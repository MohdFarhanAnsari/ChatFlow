import '../../features/profile/domain/user_profile.dart';
import '../../features/chat/domain/message.dart';
import '../../features/chat/domain/conversation.dart';

/// Pre-populated realistic demonstration dataset for portfolio evaluation.
/// Clearly separated from live Firebase operations.
class DemoData {
  DemoData._();

  static const String currentUserId = 'demo_user_me';

  static final UserProfile currentUser = UserProfile(
    uid: currentUserId,
    displayName: 'Devon Vance',
    email: 'devon.vance@chatflow.io',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    bio: 'Senior Flutter Engineer & Systems Architect',
    isOnline: true,
    lastSeen: DateTime.now(),
  );

  static final List<UserProfile> contacts = [
    UserProfile(
      uid: 'sarah_chen',
      displayName: 'Sarah Chen',
      email: 'sarah.chen@deepmind.com',
      photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
      bio: 'Staff AI Researcher @ DeepMind',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    UserProfile(
      uid: 'alex_rivera',
      displayName: 'Alex Rivera',
      email: 'alex.rivera@designstudio.co',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      bio: 'Head of Product Design • Dark Mode enthusiast',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    UserProfile(
      uid: 'dr_maya_patel',
      displayName: 'Dr. Maya Patel',
      email: 'maya.patel@cyberdefense.org',
      photoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&auto=format&fit=crop&q=80',
      bio: 'Zero-Trust Security & Cryptography Lead',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    UserProfile(
      uid: 'marcus_brooks',
      displayName: 'Marcus Brooks',
      email: 'marcus.brooks@fintechcloud.io',
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
      bio: 'Cloud Infrastructure & High-Frequency Streaming',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static List<Conversation> getInitialConversations() {
    final now = DateTime.now();

    return [
      Conversation(
        id: 'conv_sarah_chen',
        participantIds: [currentUserId, 'sarah_chen'],
        participantProfiles: {
          currentUserId: currentUser,
          'sarah_chen': contacts[0],
        },
        lastMessage: 'The new Firestore caching strategy reduced read latency by 64%! Check the graph.',
        lastSenderId: 'sarah_chen',
        lastTimestamp: now.subtract(const Duration(minutes: 4)),
        unreadCounts: {currentUserId: 2},
      ),
      Conversation(
        id: 'conv_alex_rivera',
        participantIds: [currentUserId, 'alex_rivera'],
        participantProfiles: {
          currentUserId: currentUser,
          'alex_rivera': contacts[1],
        },
        lastMessage: 'The emerald micro-animations feel remarkably fluid. Approved for release!',
        lastSenderId: 'alex_rivera',
        lastTimestamp: now.subtract(const Duration(minutes: 42)),
        unreadCounts: {currentUserId: 0},
      ),
      Conversation(
        id: 'conv_maya_patel',
        participantIds: [currentUserId, 'dr_maya_patel'],
        participantProfiles: {
          currentUserId: currentUser,
          'dr_maya_patel': contacts[2],
        },
        lastMessage: 'Security audit report passed with zero high-severity findings.',
        lastSenderId: 'dr_maya_patel',
        lastTimestamp: now.subtract(const Duration(hours: 2)),
        unreadCounts: {currentUserId: 0},
      ),
      Conversation(
        id: 'conv_marcus_brooks',
        participantIds: [currentUserId, 'marcus_brooks'],
        participantProfiles: {
          currentUserId: currentUser,
          'marcus_brooks': contacts[3],
        },
        lastMessage: 'Let’s sync tomorrow regarding WebSocket fallback mechanisms.',
        lastSenderId: currentUserId,
        lastTimestamp: now.subtract(const Duration(days: 1)),
        unreadCounts: {currentUserId: 0},
      ),
    ];
  }

  static List<Message> getInitialMessages(String conversationId) {
    final now = DateTime.now();

    if (conversationId == 'conv_sarah_chen') {
      return [
        Message(
          id: 'msg_sc_1',
          conversationId: conversationId,
          senderId: 'sarah_chen',
          receiverId: currentUserId,
          text: 'Hey Devon! Did you benchmark the end-to-end message sync latency on the staging cluster?',
          timestamp: now.subtract(const Duration(minutes: 25)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'sarah_chen'],
        ),
        Message(
          id: 'msg_sc_2',
          conversationId: conversationId,
          senderId: currentUserId,
          receiverId: 'sarah_chen',
          text: 'Yes! We enabled index optimizations and localized Firestore cache persistence.',
          timestamp: now.subtract(const Duration(minutes: 20)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'sarah_chen'],
          reactions: {'🚀': ['sarah_chen']},
        ),
        Message(
          id: 'msg_sc_3',
          conversationId: conversationId,
          senderId: 'sarah_chen',
          receiverId: currentUserId,
          text: 'That is incredible! What were the final p99 metrics?',
          timestamp: now.subtract(const Duration(minutes: 15)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'sarah_chen'],
        ),
        Message(
          id: 'msg_sc_4',
          conversationId: conversationId,
          senderId: currentUserId,
          receiverId: 'sarah_chen',
          text: 'Around 42ms on 5G and under 80ms on 4G networks.',
          timestamp: now.subtract(const Duration(minutes: 10)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'sarah_chen'],
          reactions: {'🔥': ['sarah_chen']},
        ),
        Message(
          id: 'msg_sc_5',
          conversationId: conversationId,
          senderId: 'sarah_chen',
          receiverId: currentUserId,
          text: 'The new Firestore caching strategy reduced read latency by 64%! Check the graph.',
          type: MessageType.image,
          mediaUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&auto=format&fit=crop&q=80',
          timestamp: now.subtract(const Duration(minutes: 4)),
          status: MessageStatus.sent,
          readBy: ['sarah_chen'],
          reactions: {'❤️': [currentUserId]},
        ),
      ];
    } else if (conversationId == 'conv_alex_rivera') {
      return [
        Message(
          id: 'msg_ar_1',
          conversationId: conversationId,
          senderId: currentUserId,
          receiverId: 'alex_rivera',
          text: 'Hey Alex, review the dark navy and emerald contrast ratios in the new build.',
          timestamp: now.subtract(const Duration(hours: 1)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'alex_rivera'],
        ),
        Message(
          id: 'msg_ar_2',
          conversationId: conversationId,
          senderId: 'alex_rivera',
          receiverId: currentUserId,
          text: 'The emerald micro-animations feel remarkably fluid. Approved for release!',
          timestamp: now.subtract(const Duration(minutes: 42)),
          status: MessageStatus.read,
          readBy: [currentUserId, 'alex_rivera'],
          reactions: {'👍': [currentUserId]},
        ),
      ];
    }

    return [
      Message(
        id: 'msg_generic_1',
        conversationId: conversationId,
        senderId: conversationId.replaceAll('conv_', ''),
        receiverId: currentUserId,
        text: 'Hello! Excited to collaborate with you on ChatFlow.',
        timestamp: now.subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
        readBy: [currentUserId],
      ),
    ];
  }
}
