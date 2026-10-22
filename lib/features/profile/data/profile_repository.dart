import '../domain/user_profile.dart';
import 'demo_profile_repository.dart';
import 'firestore_profile_repository.dart';

abstract class BaseProfileRepository {
  Stream<UserProfile?> streamUserProfile(String uid, {bool isDemoMode = false});
  Future<UserProfile?> getUserProfile(String uid, {bool isDemoMode = false});
  Future<void> updateProfile({
    required String uid,
    required String currentUserId,
    String? displayName,
    String? bio,
    String? photoUrl,
    bool isDemoMode = false,
  });
  Future<void> setPresence({
    required String uid,
    required bool isOnline,
    bool isDemoMode = false,
  });
  Future<List<UserProfile>> searchUsers(
    String query, {
    required String currentUserId,
    bool isDemoMode = false,
  });
}

/// Unified coordinator repository that delegates cleanly between
/// [FirestoreProfileRepository] (live Firestore) and [DemoProfileRepository] (local demo).
class ProfileRepository implements BaseProfileRepository {
  final FirestoreProfileRepository _firestoreRepo;
  final DemoProfileRepository _demoRepo;

  ProfileRepository({
    FirestoreProfileRepository? firestoreRepo,
    DemoProfileRepository? demoRepo,
  })  : _firestoreRepo = firestoreRepo ?? FirestoreProfileRepository(),
        _demoRepo = demoRepo ?? DemoProfileRepository();

  @override
  Stream<UserProfile?> streamUserProfile(String uid, {bool isDemoMode = false}) {
    if (isDemoMode) {
      return _demoRepo.streamUserProfile(uid, isDemoMode: true);
    }
    return _firestoreRepo.streamUserProfile(uid, isDemoMode: false);
  }

  @override
  Future<UserProfile?> getUserProfile(String uid, {bool isDemoMode = false}) {
    if (isDemoMode) {
      return _demoRepo.getUserProfile(uid, isDemoMode: true);
    }
    return _firestoreRepo.getUserProfile(uid, isDemoMode: false);
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String currentUserId,
    String? displayName,
    String? bio,
    String? photoUrl,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.updateProfile(
        uid: uid,
        currentUserId: currentUserId,
        displayName: displayName,
        bio: bio,
        photoUrl: photoUrl,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.updateProfile(
      uid: uid,
      currentUserId: currentUserId,
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
      isDemoMode: false,
    );
  }

  @override
  Future<void> setPresence({
    required String uid,
    required bool isOnline,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.setPresence(
        uid: uid,
        isOnline: isOnline,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.setPresence(
      uid: uid,
      isOnline: isOnline,
      isDemoMode: false,
    );
  }

  @override
  Future<List<UserProfile>> searchUsers(
    String query, {
    required String currentUserId,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoRepo.searchUsers(
        query,
        currentUserId: currentUserId,
        isDemoMode: true,
      );
    }
    return _firestoreRepo.searchUsers(
      query,
      currentUserId: currentUserId,
      isDemoMode: false,
    );
  }

  DemoProfileRepository get demoRepository => _demoRepo;
  FirestoreProfileRepository get firestoreRepository => _firestoreRepo;
}
