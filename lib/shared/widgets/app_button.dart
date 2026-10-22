import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum ButtonVariant { primary, secondary, outline, text }

/// A modern button supporting Emerald gradients, loading spinners, icons, and variants.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimens.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.outline
                    ? (isDark ? AppColors.primary : AppColors.primaryDark)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppDimens.space8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: _getTextColor(isDark),
          ),
        ),
      ],
    );

    if (variant == ButtonVariant.primary) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          gradient: (onPressed != null && !isLoading)
              ? AppColors.emeraldGradient
              : null,
          color: (onPressed == null || isLoading)
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
              : null,
          boxShadow: (onPressed != null && !isLoading)
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            child: Center(child: content),
          ),
        ),
      );
    }

    if (variant == ButtonVariant.outline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
          ),
          child: content,
        ),
      );
    }

    if (variant == ButtonVariant.secondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
          ),
          child: content,
        ),
      );
    }

    // Text button
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: content,
    );
  }

  Color _getTextColor(bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
        return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
      case ButtonVariant.text:
        return isDark ? AppColors.primaryLight : AppColors.primaryDark;
    }
  }
}
