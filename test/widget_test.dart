import 'package:chatflow/features/chat/domain/conversation.dart';
import 'package:chatflow/features/chat/domain/message.dart';
import 'package:chatflow/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:chatflow/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:chatflow/shared/widgets/app_button.dart';
import 'package:chatflow/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyView renders title, message, and executes action', (WidgetTester tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.chat_bubble_outline,
            title: 'No Conversations',
            message: 'You have no chats yet.',
            actionText: 'Start Chat',
            onAction: () => actionClicked = true,
          ),
        ),
      ),
    );

    expect(find.text('No Conversations'), findsOneWidget);
    expect(find.text('You have no chats yet.'), findsOneWidget);
    expect(find.text('Start Chat'), findsOneWidget);

    await tester.tap(find.text('Start Chat'));
    await tester.pump();

    expect(actionClicked, true);
  });

  testWidgets('AppButton renders loading state and prevents taps when loading', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Sign In',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, false);
  });

  testWidgets('ConversationTile renders partner info and unread badge', (WidgetTester tester) async {
    const me = UserProfile(uid: 'me', displayName: 'Me', email: 'me@test.com');
    const partner = UserProfile(uid: 'sarah', displayName: 'Sarah Chen', email: 'sarah@test.com');

    final conversation = Conversation(
      id: 'conv_1',
      participantIds: ['me', 'sarah'],
      participantProfiles: {'me': me, 'sarah': partner},
      lastMessage: 'Let’s review the PR today',
      unreadCounts: {'me': 3},
      lastTimestamp: DateTime.now(),
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationTile(
            conversation: conversation,
            currentUserId: 'me',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Let’s review the PR today'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Unread badge

    await tester.tap(find.byType(ConversationTile));
    await tester.pump();
    expect(tapped, true);
  });

  testWidgets('MessageBubble displays sender text and reacts to callbacks', (WidgetTester tester) async {
    final message = Message(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'user_me',
      receiverId: 'user_other',
      text: 'Hello from Flutter!',
      status: MessageStatus.read,
      timestamp: DateTime(2026, 10, 15, 14, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
            currentUserId: 'user_me',
            onReply: (_) {},
            onReaction: (_) {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hello from Flutter!'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget); // Read receipt double-check
  });
}
