import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// Top banner displayed when the application is running in Demo Mode.
/// Clearly communicates that simulated data is in use and provides a direct path to live settings.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryContainer.withAlpha(80)
            : AppColors.primary.withAlpha(25),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.primary.withAlpha(50) : AppColors.primary.withAlpha(40),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: AppColors.emeraldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'DEMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: Text(
              'Local Demo Mode • Messages & profiles persist offline',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => context.push('/settings'),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
