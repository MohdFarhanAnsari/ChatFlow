import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/firebase_initializer.dart';
import '../../profile/domain/user_profile.dart';
import 'demo_auth_repository.dart';
import 'firebase_auth_repository.dart';

abstract class BaseAuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
  bool get isDemoMode;
  Future<UserProfile> signInWithEmailAndPassword(String email, String password);
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<UserProfile> signInDemo();
}

/// Unified coordinator repository that delegates cleanly between
/// [FirebaseAuthRepository] (live production) and [DemoAuthRepository] (local demo).
class AuthRepository implements BaseAuthRepository {
  static const String _kIsDemoModeKey = 'chatflow_auth_is_demo_mode';

  final FirebaseAuthRepository _firebaseRepo;
  final DemoAuthRepository _demoRepo;
  final StreamController<UserProfile?> _streamController =
      StreamController<UserProfile?>.broadcast();

  StreamSubscription<UserProfile?>? _firebaseSub;
  StreamSubscription<UserProfile?>? _demoSub;

  bool _isDemoMode = false;

  AuthRepository({
    FirebaseAuthRepository? firebaseRepo,
    DemoAuthRepository? demoRepo,
  })  : _firebaseRepo = firebaseRepo ?? FirebaseAuthRepository(),
        _demoRepo = demoRepo ?? DemoAuthRepository() {
    _init();
  }

  void _init() {
    _demoSub = _demoRepo.authStateChanges.listen((user) {
      if (_isDemoMode) {
        _streamController.add(user);
      }
    });

    _firebaseSub = _firebaseRepo.authStateChanges.listen((user) {
      if (!_isDemoMode) {
        _streamController.add(user);
      }
    });

    // Check if demo user is stored locally and restore active mode
    _demoRepo.initialize().then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedDemoMode = prefs.getBool(_kIsDemoModeKey);
        final isDemoActive = await _demoRepo.isSessionActive();

        if (_firebaseRepo.currentUser != null) {
          _isDemoMode = false;
          await prefs.setBool(_kIsDemoModeKey, false);
          _streamController.add(_firebaseRepo.currentUser);
        } else if (savedDemoMode == true ||
            (savedDemoMode == null && isDemoActive && !FirebaseInitializer.isLiveConfigured)) {
          _isDemoMode = true;
          if (_demoRepo.currentUser != null) {
            _streamController.add(_demoRepo.currentUser);
          }
        } else {
          _isDemoMode = false;
          _streamController.add(null);
        }
      } catch (_) {}
    });
  }

  @override
  bool get isDemoMode => _isDemoMode;

  @override
  UserProfile? get currentUser {
    if (_isDemoMode) {
      return _demoRepo.currentUser;
    }
    return _firebaseRepo.currentUser;
  }

  @override
  Stream<UserProfile?> get authStateChanges => _streamController.stream;

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    _isDemoMode = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDemoModeKey, false);
      await _demoRepo.signOut();
    } catch (_) {}
    final user = await _firebaseRepo.signInWithEmailAndPassword(email, password);
    _streamController.add(user);
    return user;
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isDemoMode = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDemoModeKey, false);
      await _demoRepo.signOut();
    } catch (_) {}
    final user = await _firebaseRepo.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    _streamController.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (_isDemoMode) {
      return _demoRepo.sendPasswordResetEmail(email);
    }
    return _firebaseRepo.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool(_kIsDemoModeKey, false);
    } catch (_) {}
    try {
      await _demoRepo.signOut().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      await _firebaseRepo.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
    _isDemoMode = false;
    if (!_streamController.isClosed) {
      _streamController.add(null);
    }
  }

  @override
  Future<UserProfile> signInDemo() async {
    _isDemoMode = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDemoModeKey, true);
    } catch (_) {}
    final user = await _demoRepo.signInDemo();
    _streamController.add(user);
    return user;
  }

  DemoAuthRepository get demoRepository => _demoRepo;
  FirebaseAuthRepository get firebaseRepository => _firebaseRepo;

  void dispose() {
    _firebaseSub?.cancel();
    _demoSub?.cancel();
    _streamController.close();
  }
}
