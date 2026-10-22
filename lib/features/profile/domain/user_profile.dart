import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile entity representing a registered ChatFlow user.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.createdAt,
  });

  /// Derives initials from displayName (e.g., "Sarah Chen" -> "SC")
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? uid}) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserProfile(
      uid: uid ?? map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String? ?? 'Hey there! I am using ChatFlow.',
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: parseTimestamp(map['lastSeen']),
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          displayName == other.displayName &&
          email == other.email &&
          photoUrl == other.photoUrl &&
          bio == other.bio &&
          isOnline == other.isOnline;

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      photoUrl.hashCode ^
      bio.hashCode ^
      isOnline.hashCode;
}
