import 'package:chatflow/features/chat/domain/conversation.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('initials are correctly computed for single and multi-word names', () {
      const user1 = UserProfile(uid: '1', displayName: 'Sarah Chen', email: 's@c.com');
      expect(user1.initials, 'SC');

      const user2 = UserProfile(uid: '2', displayName: 'Liam', email: 'l@c.com');
      expect(user2.initials, 'L');

      const user3 = UserProfile(uid: '3', displayName: '  alex  rivera  ', email: 'a@c.com');
      expect(user3.initials, 'AR');

      const user4 = UserProfile(uid: '4', displayName: '', email: 'e@c.com');
      expect(user4.initials, '?');
    });

    test('serialization and deserialization preserves all fields', () {
      final now = DateTime(2026, 10, 15, 10, 30);
      final profile = UserProfile(
        uid: 'user_123',
        displayName: 'Maya Patel',
        email: 'maya@example.com',
        bio: 'Security researcher',
        photoUrl: 'https://example.com/avatar.jpg',
        isOnline: true,
        lastSeen: now,
      );

      final map = profile.toMap();
      expect(map['uid'], 'user_123');
      expect(map['displayName'], 'Maya Patel');
      expect(map['isOnline'], true);

      final reconstructed = UserProfile.fromMap(map, uid: 'user_123');
      expect(reconstructed.uid, profile.uid);
      expect(reconstructed.displayName, profile.displayName);
      expect(reconstructed.email, profile.email);
      expect(reconstructed.bio, profile.bio);
      expect(reconstructed.isOnline, true);
    });

    test('copyWith properly overrides fields while preserving others', () {
      const profile = UserProfile(
        uid: 'user_1',
        displayName: 'Devon',
        email: 'devon@test.com',
        isOnline: false,
      );

      final updated = profile.copyWith(isOnline: true, displayName: 'Devon Vance');
      expect(updated.isOnline, true);
      expect(updated.displayName, 'Devon Vance');
      expect(updated.email, 'devon@test.com');
    });
  });

  group('Message Model Tests', () {
    test('message parses status, reactions, and replyContext properly', () {
      final message = Message(
        id: 'msg_99',
        conversationId: 'conv_1',
        senderId: 'user_a',
        receiverId: 'user_b',
        text: 'Review the architecture diagram',
        type: MessageType.text,
        status: MessageStatus.read,
        replyTo: const ReplyContext(
          messageId: 'msg_98',
          text: 'Where is the diagram?',
          senderName: 'Sarah',
        ),
        reactions: {
          '🔥': ['user_b'],
        },
      );

      final map = message.toMap();
      expect(map['id'], 'msg_99');
      expect(map['status'], 'read');
      expect(map['replyTo']['senderName'], 'Sarah');

      final reconstructed = Message.fromMap(map, id: 'msg_99');
      expect(reconstructed.id, 'msg_99');
      expect(reconstructed.status, MessageStatus.read);
      expect(reconstructed.replyTo?.messageId, 'msg_98');
      expect(reconstructed.reactions['🔥'], contains('user_b'));
    });

    test('soft delete replaces display semantics', () {
      const message = Message(
        id: 'msg_1',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Initial message',
      );

      final deleted = message.copyWith(
        isDeleted: true,
        text: 'This message was deleted',
      );

      expect(deleted.isDeleted, true);
      expect(deleted.text, 'This message was deleted');
    });
  });

  group('Conversation Model Tests', () {
    test('getOtherParticipant returns the correct counterpart profile', () {
      const me = UserProfile(uid: 'user_me', displayName: 'Me', email: 'me@test.com');
      const other = UserProfile(uid: 'user_partner', displayName: 'Partner', email: 'partner@test.com');

      final conversation = Conversation(
        id: 'conv_1',
        participantIds: ['user_me', 'user_partner'],
        participantProfiles: {
          'user_me': me,
          'user_partner': other,
        },
        unreadCounts: {'user_me': 3, 'user_partner': 0},
      );

      final resolvedOther = conversation.getOtherParticipant('user_me');
      expect(resolvedOther?.uid, 'user_partner');
      expect(resolvedOther?.displayName, 'Partner');

      final unreadForMe = conversation.getUnreadCount('user_me');
      expect(unreadForMe, 3);
    });
  });
}
