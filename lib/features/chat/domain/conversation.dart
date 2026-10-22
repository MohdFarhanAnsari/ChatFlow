import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/domain/user_profile.dart';

/// Represents a one-to-one conversation between two users.
class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, UserProfile> participantProfiles;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastTimestamp;
  final Map<String, int> unreadCounts;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.participantProfiles = const {},
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastTimestamp,
    this.unreadCounts = const {},
  });

  /// Returns the other user's profile in this 1:1 conversation.
  UserProfile? getOtherParticipant(String currentUserId) {
    for (final entry in participantProfiles.entries) {
      if (entry.key != currentUserId) {
        return entry.value;
      }
    }
    // Fallback if profiles map is keyed differently or empty
    for (final id in participantIds) {
      if (id != currentUserId) {
        return participantProfiles[id];
      }
    }
    return null;
  }

  /// Returns unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, UserProfile>? participantProfiles,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastTimestamp,
    Map<String, int>? unreadCounts,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantProfiles: participantProfiles ?? this.participantProfiles,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    final profilesMap = <String, dynamic>{};
    participantProfiles.forEach((key, profile) {
      profilesMap[key] = profile.toMap();
    });

    return {
      'id': id,
      'participantIds': participantIds,
      'participantProfiles': profilesMap,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastTimestamp': lastTimestamp != null ? Timestamp.fromDate(lastTimestamp!) : FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }

  Map<String, dynamic> toJsonMap() {
    final profilesMap = <String, dynamic>{};
    participantProfiles.forEach((key, profile) {
      profilesMap[key] = profile.toJsonMap();
    });

    return {
      'id': id,
      'participantIds': participantIds,
      'participantProfiles': profilesMap,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastTimestamp': lastTimestamp?.toIso8601String(),
      'unreadCounts': unreadCounts,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawIds = map['participantIds'];
    final List<String> pIds = (rawIds is List)
        ? rawIds.map((e) => e.toString()).toList()
        : [];

    final rawProfiles = map['participantProfiles'];
    final Map<String, UserProfile> profiles = {};
    if (rawProfiles is Map) {
      rawProfiles.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          profiles[key.toString()] = UserProfile.fromMap(value, uid: key.toString());
        }
      });
    }

    final rawUnread = map['unreadCounts'];
    final Map<String, int> unread = {};
    if (rawUnread is Map) {
      rawUnread.forEach((key, value) {
        unread[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }

    return Conversation(
      id: id ?? map['id'] as String? ?? '',
      participantIds: pIds,
      participantProfiles: profiles,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderId: map['lastSenderId'] as String? ?? '',
      lastTimestamp: parseTimestamp(map['lastTimestamp']),
      unreadCounts: unread,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lastMessage == other.lastMessage &&
          lastSenderId == other.lastSenderId;

  @override
  int get hashCode => id.hashCode ^ lastMessage.hashCode ^ lastSenderId.hashCode;
}
