import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool notificationsEnabled;
  final bool messagePreviewEnabled;
  final bool soundEnabled;
  final bool readReceiptsEnabled;
  final bool lastSeenVisible;
  final bool simulatedRepliesEnabled;

  const SettingsState({
    this.notificationsEnabled = true,
    this.messagePreviewEnabled = true,
    this.soundEnabled = true,
    this.readReceiptsEnabled = true,
    this.lastSeenVisible = true,
    this.simulatedRepliesEnabled = true,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? messagePreviewEnabled,
    bool? soundEnabled,
    bool? readReceiptsEnabled,
    bool? lastSeenVisible,
    bool? simulatedRepliesEnabled,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      messagePreviewEnabled: messagePreviewEnabled ?? this.messagePreviewEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      lastSeenVisible: lastSeenVisible ?? this.lastSeenVisible,
      simulatedRepliesEnabled: simulatedRepliesEnabled ?? this.simulatedRepliesEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _kNotifsKey = 'chatflow_setting_notifs';
  static const _kPreviewKey = 'chatflow_setting_preview';
  static const _kSoundKey = 'chatflow_setting_sound';
  static const _kReadReceiptsKey = 'chatflow_setting_read_receipts';
  static const _kLastSeenKey = 'chatflow_setting_last_seen';
  static const _kSimulatedRepliesKey = 'chatflow_demo_simulated_replies';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        notificationsEnabled: prefs.getBool(_kNotifsKey) ?? true,
        messagePreviewEnabled: prefs.getBool(_kPreviewKey) ?? true,
        soundEnabled: prefs.getBool(_kSoundKey) ?? true,
        readReceiptsEnabled: prefs.getBool(_kReadReceiptsKey) ?? true,
        lastSeenVisible: prefs.getBool(_kLastSeenKey) ?? true,
        simulatedRepliesEnabled: prefs.getBool(_kSimulatedRepliesKey) ?? true,
      );
    } catch (_) {}
  }

  Future<void> toggleNotifications(bool val) async {
    state = state.copyWith(notificationsEnabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifsKey, val);
  }

  Future<void> toggleMessagePreview(bool val) async {
    state = state.copyWith(messagePreviewEnabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPreviewKey, val);
  }

  Future<void> toggleSound(bool val) async {
    state = state.copyWith(soundEnabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, val);
  }

  Future<void> toggleReadReceipts(bool val) async {
    state = state.copyWith(readReceiptsEnabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReadReceiptsKey, val);
  }

  Future<void> toggleLastSeen(bool val) async {
    state = state.copyWith(lastSeenVisible: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLastSeenKey, val);
  }

  Future<void> toggleSimulatedReplies(bool val) async {
    state = state.copyWith(simulatedRepliesEnabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSimulatedRepliesKey, val);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
