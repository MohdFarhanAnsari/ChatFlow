import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/chat/domain/conversation.dart';
import 'package:chatflow/features/chat/data/chat_repository.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<BaseChatRepository>((ref) {
  return ChatRepository();
});

/// Streams all conversations for the current user, ordered by lastTimestamp
final conversationsStreamProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(chatRepositoryProvider);
  final isDemo = ref.watch(isDemoModeProvider);
  return repo.streamConversations(user.uid, isDemoMode: isDemo);
});

/// Streams all messages for a specific conversation ID
final messagesStreamProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  final isDemo = ref.watch(isDemoModeProvider);
  return repo.streamMessages(conversationId, isDemoMode: isDemo);
});

/// Holds currently active reply context when user swipes or taps "Reply"
final activeReplyProvider =
    StateProvider.autoDispose.family<ReplyContext?, String>((ref, conversationId) => null);

/// Computes aggregate unread count across all conversations
final totalUnreadCountProvider = Provider<int>((ref) {
  final convsAsync = ref.watch(conversationsStreamProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  return convsAsync.maybeWhen(
    data: (convs) => convs.fold<int>(0, (sum, c) => sum + c.getUnreadCount(user.uid)),
    orElse: () => 0,
  );
});

class ChatController {
  final BaseChatRepository _repository;
  final Ref _ref;

  ChatController(this._repository, this._ref);

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    ReplyContext? replyTo,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final isDemo = _ref.read(isDemoModeProvider);

    await _repository.sendMessage(
      conversationId: conversationId,
      senderId: user.uid,
      receiverId: receiverId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      replyTo: replyTo,
      isDemoMode: isDemo,
    );

    // Clear reply state after sending
    _ref.read(activeReplyProvider(conversationId).notifier).state = null;
  }

  Future<void> markAsRead(String conversationId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final isDemo = _ref.read(isDemoModeProvider);

    await _repository.markConversationAsRead(
      conversationId: conversationId,
      currentUserId: user.uid,
      isDemoMode: isDemo,
    );
  }

  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final isDemo = _ref.read(isDemoModeProvider);

    await _repository.toggleReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
      userId: user.uid,
      isDemoMode: isDemo,
    );
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final isDemo = _ref.read(isDemoModeProvider);

    await _repository.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      currentUserId: user.uid,
      isDemoMode: isDemo,
    );
  }
}

final chatControllerProvider = Provider<ChatController>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatController(repo, ref);
});
