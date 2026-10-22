import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../chat/domain/conversation.dart';
import '../../chat/domain/message.dart';
import '../../profile/domain/user_profile.dart';
import '../../../shared/models/demo_data.dart';

/// Local persistence store for Demo Mode.
/// Uses SharedPreferences to persist all demo state (user profile,
/// conversations, message histories, reactions, replies, unread counts, and contacts)
/// so that changes persist reliably across app restarts without requiring Firebase credentials.
class DemoLocalStore {
  static const String _kInitializedKey = 'chatflow_demo_initialized_v1';
  static const String _kUserProfileKey = 'chatflow_demo_user_profile';
  static const String _kConversationsKey = 'chatflow_demo_conversations';
  static const String _kMessagesPrefix = 'chatflow_demo_messages_';
  static const String _kContactsKey = 'chatflow_demo_contacts';
  static const String _kSimulatedRepliesKey = 'chatflow_demo_simulated_replies';
  static const String _kDemoSessionActiveKey = 'chatflow_demo_session_active';

  SharedPreferences? _prefs;

  DemoLocalStore({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Ensures initial demo data is seeded if running for the first time.
  Future<void> ensureInitialized() async {
    final prefs = await _getPrefs();
    final isInitialized = prefs.getBool(_kInitializedKey) ?? false;

    if (!isInitialized) {
      await _seedDefaults(prefs);
    }
  }

  Future<void> _seedDefaults(SharedPreferences prefs) async {
    // 1. Seed current user
    await prefs.setString(
      _kUserProfileKey,
      jsonEncode(DemoData.currentUser.toJsonMap()),
    );

    // 2. Seed contacts
    final contactsMaps = DemoData.contacts.map((c) => c.toJsonMap()).toList();
    await prefs.setString(_kContactsKey, jsonEncode(contactsMaps));

    // 3. Seed initial conversations
    final initialConversations = DemoData.getInitialConversations();
    final convsMaps = initialConversations.map((c) => c.toJsonMap()).toList();
    await prefs.setString(_kConversationsKey, jsonEncode(convsMaps));

    // 4. Seed initial message threads for each conversation
    for (final conv in initialConversations) {
      final messages = DemoData.getInitialMessages(conv.id);
      final messagesMaps = messages.map((m) => m.toJsonMap()).toList();
      await prefs.setString('$_kMessagesPrefix${conv.id}', jsonEncode(messagesMaps));
    }

    // Default: simulated replies enabled
    await prefs.setBool(_kSimulatedRepliesKey, true);

    // Default: demo session active
    await prefs.setBool(_kDemoSessionActiveKey, true);

    // Mark initialized
    await prefs.setBool(_kInitializedKey, true);
  }

  /// Resets all demo data back to default initial state.
  Future<void> resetDemoData() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((k) => k.startsWith('chatflow_demo_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    await _seedDefaults(prefs);
  }

  // User Profile
  Future<UserProfile> getUserProfile() async {
    await ensureInitialized();
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kUserProfileKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserProfile.fromMap(map);
      } catch (_) {}
    }
    return DemoData.currentUser;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_kUserProfileKey, jsonEncode(profile.toJsonMap()));
  }

  // Conversations
  Future<List<Conversation>> getConversations() async {
    await ensureInitialized();
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kConversationsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        final convs = list
            .map((item) => Conversation.fromMap(item as Map<String, dynamic>))
            .toList();
        // Sort by lastTimestamp descending
        convs.sort((a, b) {
          final tA = a.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });
        return convs;
      } catch (_) {}
    }
    return DemoData.getInitialConversations();
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await _getPrefs();
    final list = conversations.map((c) => c.toJsonMap()).toList();
    await prefs.setString(_kConversationsKey, jsonEncode(list));
  }

  // Messages per conversation
  Future<List<Message>> getMessages(String conversationId) async {
    await ensureInitialized();
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString('$_kMessagesPrefix$conversationId');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        final messages = list
            .map((item) => Message.fromMap(item as Map<String, dynamic>))
            .toList();
        // Messages ordered descending by timestamp (newest first for reverse ListView)
        messages.sort((a, b) {
          final tA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });
        return messages;
      } catch (_) {}
    }
    return DemoData.getInitialMessages(conversationId);
  }

  Future<void> saveMessages(String conversationId, List<Message> messages) async {
    final prefs = await _getPrefs();
    final list = messages.map((m) => m.toJsonMap()).toList();
    await prefs.setString('$_kMessagesPrefix$conversationId', jsonEncode(list));
  }

  // Contacts
  Future<List<UserProfile>> getContacts() async {
    await ensureInitialized();
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kContactsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((item) => UserProfile.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return DemoData.contacts;
  }

  Future<void> saveContacts(List<UserProfile> contacts) async {
    final prefs = await _getPrefs();
    final list = contacts.map((c) => c.toJsonMap()).toList();
    await prefs.setString(_kContactsKey, jsonEncode(list));
  }

  // Simulated replies setting
  Future<bool> isSimulatedRepliesEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_kSimulatedRepliesKey) ?? true;
  }

  Future<void> setSimulatedRepliesEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_kSimulatedRepliesKey, enabled);
  }

  // Demo session persistence
  Future<bool> isDemoSessionActive() async {
    await ensureInitialized();
    final prefs = await _getPrefs();
    return prefs.getBool(_kDemoSessionActiveKey) ?? true;
  }

  Future<void> setDemoSessionActive(bool active) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_kDemoSessionActiveKey, active);
  }
}
