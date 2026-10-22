import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/core/utils/date_formatter.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatflow/features/chat/presentation/screens/image_viewer_screen.dart';
import 'package:chatflow/features/chat/presentation/widgets/demo_banner.dart';
import 'package:chatflow/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chatflow/features/chat/presentation/widgets/message_input_bar.dart';
import 'package:chatflow/features/chat/presentation/widgets/reply_preview_banner.dart';
import 'package:chatflow/features/media/presentation/storage_provider.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:chatflow/shared/models/demo_data.dart';
import 'package:chatflow/shared/widgets/app_avatar.dart';
import 'package:chatflow/shared/widgets/empty_view.dart';
import 'package:chatflow/shared/widgets/error_view.dart';
import 'package:chatflow/shared/widgets/loading_indicator.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatRoomScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read upon entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider).markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleSendText(String text, String receiverId) async {
    final replyContext = ref.read(activeReplyProvider(widget.conversationId));

    setState(() => _isSending = true);
    try {
      await ref.read(chatControllerProvider).sendMessage(
            conversationId: widget.conversationId,
            receiverId: receiverId,
            text: text,
            type: MessageType.text,
            replyTo: replyContext,
          );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleSendImage(File file, String receiverId) async {
    final replyContext = ref.read(activeReplyProvider(widget.conversationId));
    final isDemo = ref.read(isDemoModeProvider);
    final storage = ref.read(storageServiceProvider);

    setState(() => _isSending = true);
    try {
      final downloadUrl = await storage.uploadChatImage(
        file: file,
        conversationId: widget.conversationId,
        isDemoMode: isDemo,
      );

      await ref.read(chatControllerProvider).sendMessage(
            conversationId: widget.conversationId,
            receiverId: receiverId,
            text: '📷 Image',
            type: MessageType.image,
            mediaUrl: downloadUrl,
            replyTo: replyContext,
          );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  UserProfile? _extractPartner(
    String currentUserId,
    List<Message> messages,
    WidgetRef ref,
  ) {
    // 1. Look up in active conversations stream
    final convs = ref.watch(conversationsStreamProvider).valueOrNull;
    if (convs != null) {
      final matchingConv = convs.where((c) => c.id == widget.conversationId);
      if (matchingConv.isNotEmpty) {
        final profile = matchingConv.first.getOtherParticipant(currentUserId);
        if (profile != null) return profile;
      }
    }

    // 2. Resolve partner ID from message history
    String? partnerId;
    for (final m in messages) {
      if (m.senderId != currentUserId && m.senderId.isNotEmpty) {
        partnerId = m.senderId;
        break;
      } else if (m.receiverId != currentUserId && m.receiverId.isNotEmpty) {
        partnerId = m.receiverId;
        break;
      }
    }

    // 3. Fallback: parse participant from conversation ID pattern
    if (partnerId == null) {
      if (widget.conversationId.startsWith('conv_')) {
        partnerId = widget.conversationId.substring(5);
      } else {
        final parts = widget.conversationId.split('_');
        partnerId = parts.where((id) => id != currentUserId).firstOrNull;
      }
    }

    if (partnerId != null) {
      // Check seeded contacts for rich profile details (photo, bio, presence)
      final contactMatch = DemoData.contacts.where((c) => c.uid == partnerId).firstOrNull;
      if (contactMatch != null) return contactMatch;

      return UserProfile(
        uid: partnerId,
        displayName: partnerId
            .replaceAll('conv_', '')
            .replaceAll('_', ' ')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
            .join(' '),
        email: '$partnerId@chatflow.io',
      );
    }

    return null;
  }

  void _showPartnerDetails(BuildContext context, UserProfile? partner) {
    if (partner == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              AppAvatar(
                name: partner.displayName,
                imageUrl: partner.photoUrl,
                size: AvatarSize.large,
                isOnline: partner.isOnline,
              ),
              const SizedBox(height: 12),
              Text(
                partner.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                partner.email,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              if (partner.bio != null && partner.bio!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceInput : AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    partner.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isDemo = ref.watch(isDemoModeProvider);
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));
    final activeReply = ref.watch(activeReplyProvider(widget.conversationId));

    // Listen to messages stream: scroll smoothly if user is near the bottom and auto-mark as read
    ref.listen(messagesStreamProvider(widget.conversationId), (prev, next) {
      if (next.hasValue) {
        if (_scrollController.hasClients && _scrollController.offset < 120) {
          _scrollToBottom();
        }
        ref.read(chatControllerProvider).markAsRead(widget.conversationId);
      }
    });

    final partner = _extractPartner(
      currentUser?.uid ?? '',
      messagesAsync.valueOrNull ?? [],
      ref,
    );

    final partnerName = partner?.displayName ?? 'Chat';
    final partnerOnline = partner?.isOnline ?? false;
    final presenceSubtitle = DateFormatter.formatLastSeen(partner?.lastSeen, partnerOnline);
    final receiverId = partner?.uid ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () => _showPartnerDetails(context, partner),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                AppAvatar(
                  name: partnerName,
                  imageUrl: partner?.photoUrl,
                  size: AvatarSize.small,
                  isOnline: partnerOnline,
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        partnerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        presenceSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: partnerOnline ? FontWeight.w600 : FontWeight.w400,
                          color: partnerOnline
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Contact Details',
            onPressed: () => _showPartnerDetails(context, partner),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isDemo) const DemoBanner(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.chatBackgroundDark : AppColors.chatBackgroundLight,
                ),
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const EmptyView(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No Messages Here Yet',
                        message: 'Send a message or photo below to start the conversation.',
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == (currentUser?.uid ?? '');

                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        currentUserId: currentUser?.uid ?? '',
                        onReply: (replyContext) {
                          ref
                              .read(activeReplyProvider(widget.conversationId).notifier)
                              .state = replyContext;
                        },
                        onReaction: (emoji) {
                          ref.read(chatControllerProvider).toggleReaction(
                                conversationId: widget.conversationId,
                                messageId: message.id,
                                emoji: emoji,
                              );
                        },
                        onDelete: () {
                          ref.read(chatControllerProvider).deleteMessage(
                                conversationId: widget.conversationId,
                                messageId: message.id,
                              );
                        },
                        onImageTap: (imageUrl) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(imageUrl: imageUrl),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const AppLoadingIndicator(message: 'Loading messages...'),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(messagesStreamProvider(widget.conversationId)),
                ),
              ),
            ),
          ),

            // Active Reply Banner if replying to a message
            if (activeReply != null)
              ReplyPreviewBanner(
                replyContext: activeReply,
                onCancel: () => ref
                    .read(activeReplyProvider(widget.conversationId).notifier)
                    .state = null,
              ),

            // Input Bar
            MessageInputBar(
              onSendText: (text) => _handleSendText(text, receiverId),
              onSendImage: (file) => _handleSendImage(file, receiverId),
              isSending: _isSending,
            ),
          ],
        ),
      ),
    );
  }
}
