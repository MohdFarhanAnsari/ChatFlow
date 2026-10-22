import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../profile/domain/user_profile.dart';
import 'demo_chat_repository.dart';
import 'firestore_chat_repository.dart';

abstract class BaseChatRepository {
  Stream<List<Conversation>> streamConversations(String userId, {bool isDemoMode = false});
  Stream<List<Message>> streamMessages(String conversationId, {bool isDemoMode = false});
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    ReplyContext? replyTo,
    bool isDemoMode = false,
  });
  Future<void> markConversationAsRead({
    required String conversationId,
    required String currentUserId,
    bool isDemoMode = false,
  });
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
    bool isDemoMode = false,
  });
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    bool isDemoMode = false,
  });
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required UserProfile currentUser,
    required UserProfile otherUser,
    bool isDemoMode = false,
  });
  Future<void> resetDemoData();
}

/// Unified coordinator repository that delegates cleanly between
/// [FirestoreChatRepository] (live Firestore) and [DemoChatRepository] (local demo).
class ChatRepository implements BaseChatRepository {
  final FirestoreChatRepository _firestoreRepo;
  final DemoChatRepository _demoRepo;

  ChatRepository({
    FirestoreChatRepository? firestoreRepo,
    DemoChatRepository? demoRepo,
  })  : _firestoreRepo = firestoreRepo ?? FirestoreChatRepository(),
        _demoRepo = demoRepo ?? DemoChatRepository() {
    _demoRepo.initialize();
  }

  /// Generates a deterministic 1:1 conversation ID from two user IDs
  static String getConversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  @override
  Stream<List<Conversation>> streamConversations(String userId, {bool isDemoMode = false}) {
    if (isDemoMode) {
      return _demoRepo.streamConversations(userId, isDemoMode: true);
    }
    return _firestoreRepo.streamConversations(userId, isDemoMode: false);
  }

  @override
  Stream<List<Message>> streamMessages(String conversationId, {bool isDemoMode = false}) {
    if (isDemoMode) {
      return _demoRepo.streamMessages(conversationId, isDemoMode: true);
    }
    return _firestoreRepo.streamMessages(conversationId, isDemoMode: false);
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
  }) {
    if (isDemoMode) {
      return _demoRepo.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        replyTo: replyTo,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      replyTo: replyTo,
      isDemoMode: false,
    );
  }

  @override
  Future<void> markConversationAsRead({
    required String conversationId,
    required String currentUserId,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.markConversationAsRead(
        conversationId: conversationId,
        currentUserId: currentUserId,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.markConversationAsRead(
      conversationId: conversationId,
      currentUserId: currentUserId,
      isDemoMode: false,
    );
  }

  @override
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.toggleReaction(
        conversationId: conversationId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.toggleReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
      userId: userId,
      isDemoMode: false,
    );
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
        currentUserId: currentUserId,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      currentUserId: currentUserId,
      isDemoMode: false,
    );
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required UserProfile currentUser,
    required UserProfile otherUser,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.getOrCreateConversation(
        currentUserId: currentUserId,
        currentUser: currentUser,
        otherUser: otherUser,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.getOrCreateConversation(
      currentUserId: currentUserId,
      currentUser: currentUser,
      otherUser: otherUser,
      isDemoMode: false,
    );
  }

  @override
  Future<void> resetDemoData() async {
    await _demoRepo.resetDemoData();
  }

  DemoChatRepository get demoRepository => _demoRepo;
  FirestoreChatRepository get firestoreRepository => _firestoreRepo;
}
