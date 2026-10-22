import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/core/utils/date_formatter.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/chat/presentation/widgets/reply_preview_banner.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final void Function(ReplyContext replyContext) onReply;
  final void Function(String emoji) onReaction;
  final VoidCallback onDelete;
  final void Function(String imageUrl)? onImageTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.onReply,
    required this.onReaction,
    required this.onDelete,
    this.onImageTap,
  });

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick emoji reaction bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ReactionBar(
                    onSelectEmoji: (emoji) {
                      Navigator.pop(ctx);
                      onReaction(emoji);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReply(
                      ReplyContext(
                        messageId: message.id,
                        text: message.type == MessageType.image ? '📷 Image' : message.text,
                        senderName: isMe ? 'You' : 'Participant',
                      ),
                    );
                  },
                ),
                if (!message.isDeleted && message.text.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Copy Text'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                if (isMe && !message.isDeleted)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    title: const Text(
                      'Delete for everyone',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeletion(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message for everyone in this conversation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * AppDimens.bubbleMaxWidthFactor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(context),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                decoration: BoxDecoration(
                  gradient: isMe && !message.isDeleted
                      ? (isDark
                          ? AppColors.senderBubbleGradient
                          : const LinearGradient(
                              colors: [Color(0xFF047857), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                      : null,
                  color: isMe
                      ? (message.isDeleted
                          ? (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard)
                          : null)
                      : (isDark ? AppColors.receiverBubbleDark : AppColors.receiverBubbleLight),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: !isMe || message.isDeleted
                      ? Border.all(
                          color: isDark ? const Color(0xFF233044) : AppColors.lightBorder,
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 28 : 10),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 8.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quoted Reply Context inside bubble
                    if (message.replyTo != null && !message.isDeleted) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(isMe ? 35 : 20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white70 : AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyTo!.senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isMe ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyTo!.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Message Body (Deleted vs Image vs Text)
                    if (message.isDeleted) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 15,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'This message was deleted',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (message.type == MessageType.image && message.mediaUrl != null) ...[
                        GestureDetector(
                          onTap: () => onImageTap?.call(message.mediaUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            child: (message.mediaUrl!.startsWith('http://') || message.mediaUrl!.startsWith('https://'))
                                ? CachedNetworkImage(
                                    imageUrl: message.mediaUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 180,
                                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 140,
                                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                      child: const Center(
                                        child: Icon(Icons.broken_image_rounded, size: 36),
                                      ),
                                    ),
                                  )
                                : Image.file(
                                    File(message.mediaUrl!),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 140,
                                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                      child: const Center(
                                        child: Icon(Icons.broken_image_rounded, size: 36),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.text.isNotEmpty && (message.type != MessageType.image || message.text != '📷 Image'))
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: isMe
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                    ],

                    const SizedBox(height: 4),

                    // Timestamp & Status Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white70
                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ),
                        if (isMe && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions display underneath bubble
              if (message.reactions.isNotEmpty && !message.isDeleted) ...[
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  children: message.reactions.entries.map((entry) {
                    final emoji = entry.key;
                    final uids = entry.value;
                    final hasMyReaction = uids.contains(currentUserId);

                    return GestureDetector(
                      onTap: () => onReaction(emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasMyReaction
                              ? AppColors.primaryContainer
                              : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasMyReaction
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 12)),
                            if (uids.length > 1) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${uids.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasMyReaction
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70);
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.primaryLight);
    }
  }
}
