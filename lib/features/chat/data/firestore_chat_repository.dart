import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../profile/domain/user_profile.dart';
import 'chat_repository.dart';

/// Pure production Cloud Firestore implementation of [BaseChatRepository].
/// Interacts directly with Firestore database collections.
class FirestoreChatRepository implements BaseChatRepository {
  final FirebaseFirestore _firestore;

  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Conversation>> streamConversations(String userId, {bool isDemoMode = false}) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Conversation.fromMap(doc.data(), id: doc.id)).toList();
    });
  }

  @override
  Stream<List<Message>> streamMessages(String conversationId, {bool isDemoMode = false}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromMap(doc.data(), id: doc.id)).toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    ReplyContext? replyTo,
    bool isDemoMode = false,
  }) async {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newMessage = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: now,
      status: MessageStatus.sent,
      readBy: [senderId],
      replyTo: replyTo,
      reactions: {},
      isDeleted: false,
    );

    final batch = _firestore.batch();
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    batch.set(messageRef, newMessage.toMap());

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final lastMsgPreview = type == MessageType.image ? '📷 Image' : text;

    batch.update(convRef, {
      'lastMessage': lastMsgPreview,
      'lastSenderId': senderId,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> markConversationAsRead({
    required String conversationId,
    required String currentUserId,
    bool isDemoMode = false,
  }) async {
    try {
      final convRef = _firestore.collection('conversations').doc(conversationId);
      await convRef.update({
        'unreadCounts.$currentUserId': 0,
      });

      final unreadSnapshots = await convRef
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isNotEqualTo: 'read')
          .limit(50)
          .get();

      if (unreadSnapshots.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadSnapshots.docs) {
          batch.update(doc.reference, {
            'status': 'read',
            'readBy': FieldValue.arrayUnion([currentUserId]),
          });
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  @override
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
    bool isDemoMode = false,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final rawReactions = data['reactions'];
      final Map<String, dynamic> reactionsMap =
          (rawReactions is Map) ? Map<String, dynamic>.from(rawReactions) : {};

      final List<dynamic> userList =
          (reactionsMap[emoji] is List) ? List<dynamic>.from(reactionsMap[emoji] as List) : [];

      if (userList.contains(userId)) {
        userList.remove(userId);
        if (userList.isEmpty) {
          reactionsMap.remove(emoji);
        } else {
          reactionsMap[emoji] = userList;
        }
      } else {
        userList.add(userId);
        reactionsMap[emoji] = userList;
      }

      transaction.update(messageRef, {'reactions': reactionsMap});
    });
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    bool isDemoMode = false,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await messageRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data?['senderId'] != currentUserId) {
      throw Exception('Permission denied: You can only delete messages you sent.');
    }

    await messageRef.update({
      'isDeleted': true,
      'text': 'This message was deleted',
      'mediaUrl': FieldValue.delete(),
    });
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required UserProfile currentUser,
    required UserProfile otherUser,
    bool isDemoMode = false,
  }) async {
    final conversationId = ChatRepository.getConversationId(currentUserId, otherUser.uid);
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final doc = await convRef.get();

    if (doc.exists && doc.data() != null) {
      return Conversation.fromMap(doc.data()!, id: doc.id);
    }

    final newConversation = Conversation(
      id: conversationId,
      participantIds: [currentUserId, otherUser.uid],
      participantProfiles: {
        currentUserId: currentUser,
        otherUser.uid: otherUser,
      },
      lastMessage: 'Conversation started',
      lastSenderId: currentUserId,
      lastTimestamp: DateTime.now(),
      unreadCounts: {currentUserId: 0, otherUser.uid: 0},
    );

    await convRef.set(newConversation.toMap());
    return newConversation;
  }

  @override
  Future<void> resetDemoData() async {}
}
