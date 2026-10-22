import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum AvatarSize {
  small(AppDimens.avatarSmall, 13.0, 10.0),
  medium(AppDimens.avatarMedium, 16.0, 12.0),
  large(AppDimens.avatarLarge, 22.0, 14.0),
  xlarge(AppDimens.avatarXLarge, 32.0, 18.0);

  final double diameter;
  final double fontSize;
  final double badgeSize;

  const AvatarSize(this.diameter, this.fontSize, this.badgeSize);
}

/// A circular avatar displaying a local or remote photo with cached fallback to initials,
/// plus an optional real-time online presence indicator dot.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final AvatarSize size;
  final bool? isOnline;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AvatarSize.medium,
    this.isOnline,
    this.onTap,
  });

  String _getInitials(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildImageWidget() {
      if (imageUrl == null || imageUrl!.isEmpty) {
        return Center(
          child: Text(
            _getInitials(name),
            style: TextStyle(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
        );
      }

      if (!imageUrl!.startsWith('http')) {
        return Image.file(
          File(imageUrl!),
          fit: BoxFit.cover,
          width: size.diameter,
          height: size.diameter,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              _getInitials(name),
              style: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
              ),
            ),
          ),
        );
      }

      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size.diameter,
        height: size.diameter,
        placeholder: (context, url) => Center(
          child: Text(
            _getInitials(name),
            style: TextStyle(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Text(
            _getInitials(name),
            style: TextStyle(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
        ),
      );
    }

    Widget avatarWidget = Container(
      width: size.diameter,
      height: size.diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurfaceCard, AppColors.primaryContainer]
              : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: ClipOval(child: buildImageWidget()),
    );

    if (onTap != null) {
      avatarWidget = GestureDetector(onTap: onTap, child: avatarWidget);
    }

    if (isOnline != null) {
      final borderColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size.badgeSize,
              height: size.badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline! ? AppColors.online : AppColors.offline,
                border: Border.all(
                  color: borderColor,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarWidget;
  }
}
