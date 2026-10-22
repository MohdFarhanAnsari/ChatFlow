import 'package:chatflow/core/theme/theme_provider.dart';
import 'package:chatflow/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('State Management Tests', () {
    test('ThemeModeNotifier toggles between dark and light', () async {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.dark);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
    });

    test('SettingsNotifier updates privacy and notification toggles', () async {
      final notifier = SettingsNotifier();

      expect(notifier.state.readReceiptsEnabled, true);
      expect(notifier.state.notificationsEnabled, true);
      expect(notifier.state.lastSeenVisible, true);

      await notifier.toggleReadReceipts(false);
      expect(notifier.state.readReceiptsEnabled, false);

      await notifier.toggleNotifications(false);
      expect(notifier.state.notificationsEnabled, false);

      await notifier.toggleLastSeen(false);
      expect(notifier.state.lastSeenVisible, false);
    });
  });
}
