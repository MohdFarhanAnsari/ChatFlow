import 'package:chatflow/core/utils/date_formatter.dart';
import 'package:chatflow/features/chat/data/chat_repository.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Business Logic Tests', () {
    test('getConversationId produces deterministic ID regardless of argument order', () {
      final id1 = ChatRepository.getConversationId('user_alpha', 'user_beta');
      final id2 = ChatRepository.getConversationId('user_beta', 'user_alpha');

      expect(id1, 'user_alpha_user_beta');
      expect(id2, 'user_alpha_user_beta');
      expect(id1, equals(id2));
    });

    test('DateFormatter handles presence formats correctly', () {
      expect(DateFormatter.formatLastSeen(null, false), 'Offline');
      expect(DateFormatter.formatLastSeen(DateTime.now(), true), 'Active now');

      final fiveMinsAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatLastSeen(fiveMinsAgo, false), 'Active 5m ago');

      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      expect(DateFormatter.formatLastSeen(twoHoursAgo, false), 'Active 2h ago');
    });

    test('DateFormatter handles conversation timestamps', () {
      final now = DateTime.now();
      expect(DateFormatter.formatConversationTimestamp(now), 'Just now');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.formatConversationTimestamp(yesterday), 'Yesterday');
    });

    test('ReplyContext formats and parses correctly', () {
      const reply = ReplyContext(
        messageId: 'm123',
        text: 'Hello world',
        senderName: 'Sarah',
      );

      final map = reply.toMap();
      final parsed = ReplyContext.fromMap(map);

      expect(parsed.messageId, 'm123');
      expect(parsed.text, 'Hello world');
      expect(parsed.senderName, 'Sarah');
      expect(parsed, equals(reply));
    });
  });
}
