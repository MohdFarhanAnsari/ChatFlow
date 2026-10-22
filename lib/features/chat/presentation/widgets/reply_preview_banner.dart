import 'package:flutter/material.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/features/chat/domain/message.dart';

/// Small banner displayed above the text input when replying to a message.
class ReplyPreviewBanner extends StatelessWidget {
  final ReplyContext replyContext;
  final VoidCallback onCancel;

  const ReplyPreviewBanner({
    super.key,
    required this.replyContext,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          left: const BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${replyContext.senderName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyContext.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onCancel,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ],
      ),
    );
  }
}

/// Floating horizontal emoji reaction bar (❤️, 👍, 😂, 😮, 😢, 🔥).
class ReactionBar extends StatelessWidget {
  final void Function(String emoji) onSelectEmoji;

  const ReactionBar({super.key, required this.onSelectEmoji});

  static const List<String> availableEmojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: availableEmojis.map((emoji) {
            return InkWell(
              onTap: () => onSelectEmoji(emoji),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
