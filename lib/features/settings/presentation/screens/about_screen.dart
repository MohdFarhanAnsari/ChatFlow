import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About ChatFlow'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.chat_bubble_rounded, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.appName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0 (Build 1)',
                style: TextStyle(fontSize: 13, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Text(
                'ChatFlow is a real-time messaging application engineered with Flutter, Riverpod, GoRouter, and the Google Firebase Cloud suite.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Architectural highlights
              _buildFeatureItem(
                context,
                icon: Icons.speed_rounded,
                title: 'High-Performance Real-Time Engine',
                desc: 'Reactive Cloud Firestore subscriptions with local optimistic updates and automatic read receipt synchronization.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.security_rounded,
                title: 'Sandboxed Cloud Security Rules',
                desc: 'Strict participant authorization policies for Firestore documents and Cloud Storage media buckets.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.layers_rounded,
                title: 'Clean Feature-First Architecture',
                desc: 'Clear separation of Presentation, Application (Riverpod), Domain entities, and Data Repositories.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.palette_rounded,
                title: 'Fintech-Grade Dark & Light Design',
                desc: 'Curated deep navy surfaces, emerald primary accents, and smooth micro-animations.',
              ),
              const SizedBox(height: 32),
              Text(
                'Crafted for high-performance mobile portfolios.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withAlpha(150),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
