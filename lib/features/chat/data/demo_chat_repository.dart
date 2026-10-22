import 'dart:async';
import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../profile/domain/user_profile.dart';
import '../../demo/data/demo_local_store.dart';
import 'chat_repository.dart';

/// Pure local Demo Mode implementation of [BaseChatRepository].
/// Operates completely offline without requiring Firebase credentials.
/// Automatically persists all conversations, messages, reactions, replies,
/// unread counts, and soft-deletes via [DemoLocalStore] across app restarts.
class DemoChatRepository implements BaseChatRepository {
  final DemoLocalStore _store;

  final StreamController<List<Conversation>> _conversationsController =
      StreamController<List<Conversation>>.broadcast();

  final Map<String, StreamController<List<Message>>> _messagesControllers = {};

  DemoChatRepository({DemoLocalStore? store})
      : _store = store ?? DemoLocalStore();

  Future<void> initialize() async {
    await _store.ensureInitialized();
    final convs = await _store.getConversations();
    _conversationsController.add(convs);
  }

  @override
  Stream<List<Conversation>> streamConversations(String userId, {bool isDemoMode = true}) {
    // Deliver latest conversations immediately on listen
    _store.getConversations().then((convs) {
      if (!_conversationsController.isClosed) {
        _conversationsController.add(convs);
      }
    });
    return _conversationsController.stream;
  }

  @override
  Stream<List<Message>> streamMessages(String conversationId, {bool isDemoMode = true}) {
    final controller = _messagesControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<Message>>.broadcast(),
    );

    _store.getMessages(conversationId).then((messages) {
      if (!controller.isClosed) {
        controller.add(messages);
      }
    });

    return controller.stream;
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
    bool isDemoMode = true,
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

    // 1. Insert message and persist
    final messages = await _store.getMessages(conversationId);
    messages.insert(0, newMessage);
    await _store.saveMessages(conversationId, messages);
    _messagesControllers[conversationId]?.add(List.from(messages));

    // 2. Update conversation preview, ordering, and persist
    final convs = await _store.getConversations();
    final index = convs.indexWhere((c) => c.id == conversationId);
    final lastMsgPreview = type == MessageType.image ? '📷 Image' : text;

    if (index != -1) {
      convs[index] = convs[index].copyWith(
        lastMessage: lastMsgPreview,
        lastSenderId: senderId,
        lastTimestamp: now,
      );
    }

    // Re-sort conversations by lastTimestamp descending
    convs.sort((a, b) {
      final tA = a.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = b.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });

    await _store.saveConversations(convs);
    _conversationsController.add(List.from(convs));

    // 3. Trigger simulated realistic demo reply
    _triggerSimulatedReply(conversationId, receiverId, senderId, text);
  }

  void _triggerSimulatedReply(
    String conversationId,
    String botId,
    String targetUserId,
    String userText,
  ) {
    _store.isSimulatedRepliesEnabled().then((enabled) {
      if (!enabled) return;

      Timer(const Duration(milliseconds: 1400), () async {
        final replies = [
          'Got it! That looks remarkably responsive and fluid.',
          'Review complete. Everything compiles with zero warnings.',
          'The emerald micro-animations feel fantastic on mobile.',
          'Confirmed! All local demo persistence tests are passing.',
          'Great point. Let us integrate that into the next build.',
        ];
        final replyText = replies[(userText.length + replies.length) % replies.length];
        final replyId = 'msg_reply_${DateTime.now().millisecondsSinceEpoch}';
        final now = DateTime.now();

        final botMessage = Message(
          id: replyId,
          conversationId: conversationId,
          senderId: botId,
          receiverId: targetUserId,
          text: replyText,
          timestamp: now,
          status: MessageStatus.sent,
          readBy: [botId],
        );

        final currentMessages = await _store.getMessages(conversationId);
        currentMessages.insert(0, botMessage);
        await _store.saveMessages(conversationId, currentMessages);
        _messagesControllers[conversationId]?.add(List.from(currentMessages));

        // Update conversation card and increment unread count for target user
        final convs = await _store.getConversations();
        final index = convs.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final currentUnread = convs[index].unreadCounts[targetUserId] ?? 0;
          final updatedUnread = Map<String, int>.from(convs[index].unreadCounts);
          updatedUnread[targetUserId] = currentUnread + 1;

          convs[index] = convs[index].copyWith(
            lastMessage: replyText,
            lastSenderId: botId,
            lastTimestamp: now,
            unreadCounts: updatedUnread,
          );

          convs.sort((a, b) {
            final tA = a.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = b.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });

          await _store.saveConversations(convs);
          _conversationsController.add(List.from(convs));
        }
      });
    });
  }

  @override
  Future<void> markConversationAsRead({
    required String conversationId,
    required String currentUserId,
    bool isDemoMode = true,
  }) async {
    // 1. Reset unread count on conversation
    final convs = await _store.getConversations();
    final index = convs.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final unread = Map<String, int>.from(convs[index].unreadCounts);
      unread[currentUserId] = 0;
      convs[index] = convs[index].copyWith(unreadCounts: unread);
      await _store.saveConversations(convs);
      _conversationsController.add(List.from(convs));
    }

    // 2. Mark messages received as read
    final messages = await _store.getMessages(conversationId);
    bool changed = false;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].senderId != currentUserId && messages[i].status != MessageStatus.read) {
        messages[i] = messages[i].copyWith(
          status: MessageStatus.read,
          readBy: [...messages[i].readBy, currentUserId],
        );
        changed = true;
      }
    }

    if (changed) {
      await _store.saveMessages(conversationId, messages);
      _messagesControllers[conversationId]?.add(List.from(messages));
    }
  }

  @override
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
    bool isDemoMode = true,
  }) async {
    final messages = await _store.getMessages(conversationId);
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final currentMap = Map<String, List<String>>.from(messages[index].reactions);
      final currentList = List<String>.from(currentMap[emoji] ?? []);

      if (currentList.contains(userId)) {
        currentList.remove(userId);
        if (currentList.isEmpty) {
          currentMap.remove(emoji);
        } else {
          currentMap[emoji] = currentList;
        }
      } else {
        currentList.add(userId);
        currentMap[emoji] = currentList;
      }

      messages[index] = messages[index].copyWith(reactions: currentMap);
      await _store.saveMessages(conversationId, messages);
      _messagesControllers[conversationId]?.add(List.from(messages));
    }
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    bool isDemoMode = true,
  }) async {
    final messages = await _store.getMessages(conversationId);
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      if (messages[index].senderId != currentUserId) {
        throw Exception('You can only delete your own messages.');
      }
      messages[index] = messages[index].copyWith(
        isDeleted: true,
        text: 'This message was deleted',
        mediaUrl: null,
      );
      await _store.saveMessages(conversationId, messages);
      _messagesControllers[conversationId]?.add(List.from(messages));

      // Update conversation preview if the deleted message was the latest message
      if (index == 0) {
        final convs = await _store.getConversations();
        final cIndex = convs.indexWhere((c) => c.id == conversationId);
        if (cIndex != -1) {
          convs[cIndex] = convs[cIndex].copyWith(
            lastMessage: 'This message was deleted',
          );
          await _store.saveConversations(convs);
          _conversationsController.add(List.from(convs));
        }
      }
    }
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required UserProfile currentUser,
    required UserProfile otherUser,
    bool isDemoMode = true,
  }) async {
    final conversationId = ChatRepository.getConversationId(currentUserId, otherUser.uid);
    final convs = await _store.getConversations();

    final existingIndex = convs.indexWhere(
      (c) =>
          c.id == conversationId ||
          (c.participantIds.contains(currentUserId) && c.participantIds.contains(otherUser.uid)),
    );
    if (existingIndex != -1) {
      return convs[existingIndex];
    }

    final newConv = Conversation(
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

    convs.insert(0, newConv);
    await _store.saveConversations(convs);
    await _store.saveMessages(conversationId, []);
    _conversationsController.add(List.from(convs));
    return newConv;
  }

  /// Resets demo data and broadcasts fresh lists to all active UI streams.
  @override
  Future<void> resetDemoData() async {
    await _store.resetDemoData();
    final freshConvs = await _store.getConversations();
    _conversationsController.add(List.from(freshConvs));

    for (final conv in freshConvs) {
      final messages = await _store.getMessages(conv.id);
      _messagesControllers[conv.id]?.add(List.from(messages));
    }
    for (final entry in _messagesControllers.entries) {
      final messages = await _store.getMessages(entry.key);
      entry.value.add(List.from(messages));
    }
  }

  void dispose() {
    _conversationsController.close();
    for (final c in _messagesControllers.values) {
      c.close();
    }
  }
}
