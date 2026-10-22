import 'dart:async';
import '../../profile/domain/user_profile.dart';
import '../../demo/data/demo_local_store.dart';
import 'auth_repository.dart';

/// Pure local Demo Mode implementation of [BaseAuthRepository].
/// Operates completely offline without requiring Firebase credentials.
/// Reads and persists session state and profile changes through [DemoLocalStore].
class DemoAuthRepository implements BaseAuthRepository {
  final DemoLocalStore _store;
  final StreamController<UserProfile?> _authStreamController =
      StreamController<UserProfile?>.broadcast();

  UserProfile? _cachedUser;
  bool _isSignedIn = false;

  DemoAuthRepository({DemoLocalStore? store})
      : _store = store ?? DemoLocalStore();

  Future<void> initialize() async {
    await _store.ensureInitialized();
    _cachedUser = await _store.getUserProfile();
    _isSignedIn = await _store.isDemoSessionActive();
    _authStreamController.add(_isSignedIn ? _cachedUser : null);
  }

  @override
  bool get isDemoMode => true;

  @override
  UserProfile? get currentUser => _isSignedIn ? _cachedUser : null;

  @override
  Stream<UserProfile?> get authStateChanges {
    // Deliver current state immediately on listen
    Future.microtask(() {
      _authStreamController.add(_isSignedIn ? _cachedUser : null);
    });
    return _authStreamController.stream;
  }

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    // In demo mode, sign in seamlessly with any valid credentials or pre-seeded user
    await _store.ensureInitialized();
    _cachedUser = await _store.getUserProfile();
    _isSignedIn = true;
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _store.ensureInitialized();
    final newUser = UserProfile(
      uid: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName.trim(),
      email: email.trim(),
      bio: 'Hey there! I am using ChatFlow.',
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _store.saveUserProfile(newUser);
    _cachedUser = newUser;
    _isSignedIn = true;
    _authStreamController.add(_cachedUser);
    return newUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulated password reset in demo mode
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> signOut() async {
    _isSignedIn = false;
    await _store.setDemoSessionActive(false);
    _authStreamController.add(null);
  }

  @override
  Future<UserProfile> signInDemo() async {
    await _store.ensureInitialized();
    _cachedUser = await _store.getUserProfile();
    _isSignedIn = true;
    await _store.setDemoSessionActive(true);
    _authStreamController.add(_cachedUser);
    return _cachedUser!;
  }

  Future<bool> isSessionActive() => _store.isDemoSessionActive();

  Future<UserProfile> enterDemoMode() => signInDemo();

  Future<void> updateProfile(UserProfile updated) async {
    _cachedUser = updated;
    await _store.saveUserProfile(updated);
    if (_isSignedIn) {
      _authStreamController.add(_cachedUser);
    }
  }

  void dispose() {
    _authStreamController.close();
  }
}
