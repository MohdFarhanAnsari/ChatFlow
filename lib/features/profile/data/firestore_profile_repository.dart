import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// Pure production Cloud Firestore implementation of [BaseProfileRepository].
class FirestoreProfileRepository implements BaseProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> streamUserProfile(String uid, {bool isDemoMode = false}) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, uid: doc.id);
    });
  }

  @override
  Future<UserProfile?> getUserProfile(String uid, {bool isDemoMode = false}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, uid: doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String currentUserId,
    String? displayName,
    String? bio,
    String? photoUrl,
    bool isDemoMode = false,
  }) async {
    if (uid != currentUserId) {
      throw Exception('Permission denied: You can only edit your own profile.');
    }

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  @override
  Future<void> setPresence({
    required String uid,
    required bool isOnline,
    bool isDemoMode = false,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<List<UserProfile>> searchUsers(
    String query, {
    required String currentUserId,
    bool isDemoMode = false,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    try {
      final snapshot = await _firestore.collection('users').limit(20).get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), uid: doc.id))
          .where((user) =>
              user.uid != currentUserId &&
              (user.displayName.toLowerCase().contains(cleanQuery) ||
                  user.email.toLowerCase().contains(cleanQuery)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
