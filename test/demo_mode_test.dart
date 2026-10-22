import 'package:chatflow/features/auth/data/demo_auth_repository.dart';
import 'package:chatflow/features/chat/data/demo_chat_repository.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/demo/data/demo_local_store.dart';
import 'package:chatflow/features/profile/data/demo_profile_repository.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:chatflow/features/settings/presentation/providers/settings_provider.dart';
import 'package:chatflow/shared/models/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DemoLocalStore Persistence Tests', () {
    test('default profile and conversations are seeded on fresh launch', () async {
      final store = DemoLocalStore();
      final profile = await store.getUserProfile();
      expect(profile.uid, DemoData.currentUserId);
      expect(profile.displayName, 'Devon Vance');

      final convs = await store.getConversations();
      expect(convs.length, 4);
      expect(convs.first.id, 'conv_sarah_chen');
    });

    test('profile updates persist across multiple store instances', () async {
      final store1 = DemoLocalStore();
      final current = await store1.getUserProfile();
      final updated = current.copyWith(
        displayName: 'Devon Vance Senior',
        bio: 'Senior Distributed Systems Architect',
      );
      await store1.saveUserProfile(updated);

      final store2 = DemoLocalStore();
      final retrieved = await store2.getUserProfile();
      expect(retrieved.displayName, 'Devon Vance Senior');
      expect(retrieved.bio, 'Senior Distributed Systems Architect');
    });

    test('resetDemoData restores original seed data', () async {
      final store = DemoLocalStore();
      final current = await store.getUserProfile();
      await store.saveUserProfile(current.copyWith(displayName: 'Temp Name'));

      var profile = await store.getUserProfile();
      expect(profile.displayName, 'Temp Name');

      await store.resetDemoData();
      profile = await store.getUserProfile();
      expect(profile.displayName, 'Devon Vance');
    });
  });

  group('DemoChatRepository Tests', () {
    test('sending a message stores it, updates conversation preview and ordering', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      await repo.sendMessage(
        conversationId: 'conv_sarah_chen',
        senderId: DemoData.currentUserId,
        receiverId: 'sarah_chen',
        text: 'Testing demo message sending',
        type: MessageType.text,
      );

      final messages = await store.getMessages('conv_sarah_chen');
      expect(messages.first.text, 'Testing demo message sending');
      expect(messages.first.senderId, DemoData.currentUserId);

      final convs = await store.getConversations();
      final targetConv = convs.firstWhere((c) => c.id == 'conv_sarah_chen');
      expect(targetConv.lastMessage, 'Testing demo message sending');
      expect(targetConv.lastSenderId, DemoData.currentUserId);
      // The updated conversation moves to index 0
      expect(convs.first.id, 'conv_sarah_chen');
    });

    test('deleteMessage soft-deletes the message and retains tombstone', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      await repo.sendMessage(
        conversationId: 'conv_sarah_chen',
        senderId: DemoData.currentUserId,
        receiverId: 'sarah_chen',
        text: 'Message to be deleted',
      );

      final messages = await store.getMessages('conv_sarah_chen');
      final messageId = messages.first.id;

      await repo.deleteMessage(
        conversationId: 'conv_sarah_chen',
        messageId: messageId,
        currentUserId: DemoData.currentUserId,
      );

      final afterDelete = await store.getMessages('conv_sarah_chen');
      final deletedMsg = afterDelete.firstWhere((m) => m.id == messageId);
      expect(deletedMsg.isDeleted, true);
      expect(deletedMsg.text, 'This message was deleted');
    });

    test('toggleReaction adds and removes reaction for user', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      await repo.sendMessage(
        conversationId: 'conv_sarah_chen',
        senderId: DemoData.currentUserId,
        receiverId: 'sarah_chen',
        text: 'React to this',
      );

      final messages = await store.getMessages('conv_sarah_chen');
      final msgId = messages.first.id;

      // Add reaction
      await repo.toggleReaction(
        conversationId: 'conv_sarah_chen',
        messageId: msgId,
        emoji: '🚀',
        userId: DemoData.currentUserId,
      );

      var updatedMessages = await store.getMessages('conv_sarah_chen');
      expect(updatedMessages.first.reactions['🚀'], contains(DemoData.currentUserId));

      // Remove reaction (toggle again)
      await repo.toggleReaction(
        conversationId: 'conv_sarah_chen',
        messageId: msgId,
        emoji: '🚀',
        userId: DemoData.currentUserId,
      );

      updatedMessages = await store.getMessages('conv_sarah_chen');
      expect(updatedMessages.first.reactions.containsKey('🚀'), false);
    });

    test('markConversationAsRead clears unread count for current user', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      // Verify initial unread count on conv_sarah_chen is 2
      final initialConvs = await store.getConversations();
      final conv = initialConvs.firstWhere((c) => c.id == 'conv_sarah_chen');
      expect(conv.getUnreadCount(DemoData.currentUserId), 2);

      // Mark as read
      await repo.markConversationAsRead(
        conversationId: 'conv_sarah_chen',
        currentUserId: DemoData.currentUserId,
      );

      final updatedConvs = await store.getConversations();
      final updatedConv = updatedConvs.firstWhere((c) => c.id == 'conv_sarah_chen');
      expect(updatedConv.getUnreadCount(DemoData.currentUserId), 0);
    });

    test('getOrCreateConversation returns existing or creates deterministic conversation', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      const me = UserProfile(uid: 'demo_user_me', displayName: 'Devon', email: 'devon@demo.io');
      const other = UserProfile(uid: 'new_contact_99', displayName: 'Zara', email: 'zara@demo.io');

      final newConv = await repo.getOrCreateConversation(
        currentUserId: 'demo_user_me',
        currentUser: me,
        otherUser: other,
      );

      expect(newConv.participantIds, containsAll(['demo_user_me', 'new_contact_99']));

      // Calling again returns the same conversation without duplicates
      final existingConv = await repo.getOrCreateConversation(
        currentUserId: 'demo_user_me',
        currentUser: me,
        otherUser: other,
      );

      expect(existingConv.id, newConv.id);
      final allConvs = await store.getConversations();
      final matches = allConvs.where((c) => c.id == newConv.id);
      expect(matches.length, 1);

      // Resolving seeded contact returns existing seeded conversation ID
      const sarah = UserProfile(uid: 'sarah_chen', displayName: 'Sarah Chen', email: 'sarah@demo.io');
      final sarahConv = await repo.getOrCreateConversation(
        currentUserId: 'demo_user_me',
        currentUser: me,
        otherUser: sarah,
      );
      expect(sarahConv.id, 'conv_sarah_chen');
    });

    test('resetDemoData broadcasts reset state to active conversation streams', () async {
      final store = DemoLocalStore();
      final repo = DemoChatRepository(store: store);

      await repo.sendMessage(
        conversationId: 'conv_sarah_chen',
        senderId: DemoData.currentUserId,
        receiverId: 'sarah_chen',
        text: 'New temporary message',
      );

      var messages = await store.getMessages('conv_sarah_chen');
      expect(messages.first.text, 'New temporary message');

      await repo.resetDemoData();
      messages = await store.getMessages('conv_sarah_chen');
      expect(messages.any((m) => m.text == 'New temporary message'), false);
    });
  });

  group('DemoProfileRepository Tests', () {
    test('searchUsers returns all contacts when query is empty', () async {
      final store = DemoLocalStore();
      final repo = DemoProfileRepository(store: store);

      final allContacts = await repo.searchUsers('', currentUserId: DemoData.currentUserId);
      expect(allContacts.length, 4);
      expect(allContacts.any((u) => u.displayName == 'Sarah Chen'), true);
      expect(allContacts.any((u) => u.displayName == 'Alex Rivera'), true);
      expect(allContacts.any((u) => u.displayName == 'Dr. Maya Patel'), true);
      expect(allContacts.any((u) => u.displayName == 'Marcus Brooks'), true);
    });

    test('searchUsers filters contacts matching query', () async {
      final store = DemoLocalStore();
      final repo = DemoProfileRepository(store: store);

      final results = await repo.searchUsers('sarah', currentUserId: DemoData.currentUserId);
      expect(results.length, 1);
      expect(results.first.displayName, 'Sarah Chen');

      final emptyResults = await repo.searchUsers('nonexistent_user_query', currentUserId: DemoData.currentUserId);
      expect(emptyResults.isEmpty, true);
    });

    test('updateProfile updates user and syncs with store', () async {
      final store = DemoLocalStore();
      final repo = DemoProfileRepository(store: store);

      await repo.updateProfile(
        uid: DemoData.currentUserId,
        currentUserId: DemoData.currentUserId,
        displayName: 'Devon Vance Updated',
        bio: 'Updated bio info',
      );

      final profile = await repo.getUserProfile(DemoData.currentUserId);
      expect(profile?.displayName, 'Devon Vance Updated');
      expect(profile?.bio, 'Updated bio info');
    });
  });

  group('DemoAuthRepository Tests', () {
    test('enterDemoMode logs in demo user and persists state', () async {
      final store = DemoLocalStore();
      final authRepo = DemoAuthRepository(store: store);

      final user = await authRepo.enterDemoMode();
      expect(user.uid, DemoData.currentUserId);
      expect(authRepo.currentUser?.uid, DemoData.currentUserId);

      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
    });

    test('demo session state persists across repository re-initialization', () async {
      final store = DemoLocalStore();
      final authRepo1 = DemoAuthRepository(store: store);
      await authRepo1.enterDemoMode();
      expect(await store.isDemoSessionActive(), true);

      // Create fresh auth repo simulating app restart
      final authRepo2 = DemoAuthRepository(store: store);
      await authRepo2.initialize();
      expect(authRepo2.currentUser?.uid, DemoData.currentUserId);
      expect(await authRepo2.isSessionActive(), true);

      await authRepo2.signOut();
      expect(authRepo2.currentUser, isNull);
      expect(await store.isDemoSessionActive(), false);
    });
  });

  group('Settings Persistence Tests', () {
    test('SettingsNotifier persists simulatedRepliesEnabled toggle', () async {
      final notifier = SettingsNotifier();
      expect(notifier.state.simulatedRepliesEnabled, true);

      await notifier.toggleSimulatedReplies(false);
      expect(notifier.state.simulatedRepliesEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chatflow_demo_simulated_replies'), false);
    });
  });
}
