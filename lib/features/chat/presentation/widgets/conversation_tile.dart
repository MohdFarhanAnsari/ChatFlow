import 'package:flutter/material.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/core/utils/date_formatter.dart';
import 'package:chatflow/features/chat/domain/conversation.dart';
import 'package:chatflow/shared/widgets/app_avatar.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final otherUser = conversation.getOtherParticipant(currentUserId);
    final displayName = otherUser?.displayName ?? 'Conversation';
    final photoUrl = otherUser?.photoUrl;
    final isOnline = otherUser?.isOnline;
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final formattedTime = DateFormatter.formatConversationTimestamp(conversation.lastTimestamp);

    final isMyMessage = conversation.lastSenderId == currentUserId;
    final isImage = conversation.lastMessage == '📷 Image';
    final hasUnreadForPartner = conversation.unreadCounts.entries
        .where((e) => e.key != currentUserId)
        .any((e) => e.value > 0);

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary.withAlpha(20),
      highlightColor: isDark ? AppColors.darkSurfaceCard.withAlpha(50) : AppColors.lightSurfaceCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            AppAvatar(
              name: displayName,
              imageUrl: photoUrl,
              size: AvatarSize.medium,
              isOnline: isOnline,
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                          color: unreadCount > 0
                              ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Double checkmark if last sender was me
                      if (isMyMessage) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: hasUnreadForPartner
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : AppColors.readCheck,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (isImage) ...[
                        Icon(
                          Icons.photo_camera_rounded,
                          size: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessage.isEmpty
                              ? 'Say hello!'
                              : (isImage ? 'Photo' : conversation.lastMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                            color: unreadCount > 0
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.emeraldGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(90),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
