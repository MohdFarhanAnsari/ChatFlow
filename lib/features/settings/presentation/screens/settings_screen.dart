import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chatflow/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatflow/features/demo/data/demo_local_store.dart';
import '../../../../core/config/firebase_initializer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text(AppStrings.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              AppStrings.signOut,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetDemoData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will restore the original demo conversations, contacts, and reset all mock messages to their default state. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final chatRepo = ref.read(chatRepositoryProvider);
              await chatRepo.resetDemoData();

              // Restore default demo user profile in auth state
              final defaultUser = await DemoLocalStore().getUserProfile();
              ref.read(authNotifierProvider.notifier).updateUserProfile(defaultUser);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo conversations, messages, and profile have been reset to default.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Reset Demo Data',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isDemo = ref.watch(isDemoModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 20 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AppAvatar(
                    name: user?.displayName ?? 'User',
                    imageUrl: user?.photoUrl,
                    size: AvatarSize.large,
                    isOnline: user?.isOnline,
                  ),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.displayName ?? 'User',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          text: AppStrings.editProfile,
                          onPressed: () => context.push('/edit-profile'),
                          variant: ButtonVariant.outline,
                          height: 34,
                          width: 120,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Mode & Backend Status Section
            _buildSectionHeader(context, 'ENVIRONMENT & BACKEND'),
            _buildGroupCard(
              context,
              children: [
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.layers_rounded,
                    AppColors.primary,
                    isDark: isDark,
                  ),
                  title: const Text('Interactive Demo Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    isDemo
                        ? 'Using local responsive simulated conversations'
                        : (FirebaseInitializer.isLiveConfigured
                            ? 'Connected to live Firebase Cloud Project'
                            : 'Pending Firebase project credentials setup'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDemo ? AppColors.primaryLight : AppColors.darkTextMuted,
                    ),
                  ),
                  value: isDemo,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) async {
                    if (val) {
                      await ref.read(authNotifierProvider.notifier).enterDemoMode();
                    } else {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
                if (isDemo) ...[
                  _buildDivider(isDark),
                  SwitchListTile(
                    secondary: _buildLeadingIcon(
                      Icons.smart_toy_rounded,
                      const Color(0xFF06B6D4), // Cyan
                      isDark: isDark,
                    ),
                    title: const Text('Simulated Demo Replies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Automatically simulate responses after sending messages in demo chats',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settingsState.simulatedRepliesEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => settingsNotifier.toggleSimulatedReplies(val),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: _buildLeadingIcon(
                      Icons.restart_alt_rounded,
                      const Color(0xFFF59E0B), // Amber
                      isDark: isDark,
                    ),
                    title: const Text('Reset Demo Data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Restore default demo conversations, contacts, and clear test messages',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => _confirmResetDemoData(context, ref),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Appearance & Theme Section
            _buildSectionHeader(context, 'APPEARANCE'),
            _buildGroupCard(
              context,
              children: [
                ListTile(
                  leading: _buildLeadingIcon(
                    Icons.palette_rounded,
                    const Color(0xFF8B5CF6), // Purple
                    isDark: isDark,
                  ),
                  title: const Text('Theme Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    switch (themeMode) {
                      ThemeMode.dark => 'Deep Navy (Dark)',
                      ThemeMode.light => 'Clean (Light)',
                      ThemeMode.system => 'Follow System',
                    },
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: themeMode,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      onChanged: (newMode) {
                        if (newMode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Notifications Section
            _buildSectionHeader(context, 'NOTIFICATIONS'),
            _buildGroupCard(
              context,
              children: [
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.notifications_active_rounded,
                    const Color(0xFF3B82F6), // Blue
                    isDark: isDark,
                  ),
                  title: const Text('Push Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive alerts for incoming messages', style: TextStyle(fontSize: 12)),
                  value: settingsState.notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleNotifications(val),
                ),
                _buildDivider(isDark),
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.remove_red_eye_rounded,
                    const Color(0xFF10B981), // Emerald
                    isDark: isDark,
                  ),
                  title: const Text('Message Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Display sender and message text in notifications', style: TextStyle(fontSize: 12)),
                  value: settingsState.messagePreviewEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleMessagePreview(val),
                ),
                _buildDivider(isDark),
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.volume_up_rounded,
                    const Color(0xFFEC4899), // Pink
                    isDark: isDark,
                  ),
                  title: const Text('Notification Sounds', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play sound on new incoming chat events', style: TextStyle(fontSize: 12)),
                  value: settingsState.soundEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleSound(val),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Privacy Section
            _buildSectionHeader(context, 'PRIVACY & SECURITY'),
            _buildGroupCard(
              context,
              children: [
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.done_all_rounded,
                    AppColors.primary,
                    isDark: isDark,
                  ),
                  title: const Text(AppStrings.readReceipts, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text(AppStrings.readReceiptsDesc, style: TextStyle(fontSize: 12)),
                  value: settingsState.readReceiptsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleReadReceipts(val),
                ),
                _buildDivider(isDark),
                SwitchListTile(
                  secondary: _buildLeadingIcon(
                    Icons.access_time_rounded,
                    const Color(0xFF6366F1), // Indigo
                    isDark: isDark,
                  ),
                  title: const Text('Last Seen Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Share your online activity and last active timestamp', style: TextStyle(fontSize: 12)),
                  value: settingsState.lastSeenVisible,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleLastSeen(val),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // About & Info Section
            _buildSectionHeader(context, 'SYSTEM & ABOUT'),
            _buildGroupCard(
              context,
              children: [
                ListTile(
                  leading: _buildLeadingIcon(
                    Icons.info_outline_rounded,
                    AppColors.primary,
                    isDark: isDark,
                  ),
                  title: const Text('About ChatFlow', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Architecture, Security & Credits', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => context.push('/about'),
                ),
                _buildDivider(isDark),
                ListTile(
                  leading: _buildLeadingIcon(
                    Icons.logout_rounded,
                    AppColors.error,
                    isDark: isDark,
                  ),
                  title: const Text(
                    AppStrings.signOut,
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text('Leave current demo or authenticated session', style: TextStyle(fontSize: 12)),
                  onTap: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color color, {required bool isDark}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      indent: 56,
      endIndent: 16,
      height: 1,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withAlpha(120),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}
