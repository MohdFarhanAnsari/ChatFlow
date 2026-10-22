import 'dart:async';
import 'package:chatflow/features/auth/data/auth_repository.dart';
import 'package:chatflow/features/auth/domain/auth_state.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository implements BaseAuthRepository {
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _user;
  bool _demo = false;
  bool shouldFailSignIn = false;
  bool shouldFailSignOut = false;
  String failureMessage = 'Invalid credentials';

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;

  @override
  UserProfile? get currentUser => _user;

  @override
  bool get isDemoMode => _demo;

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    if (shouldFailSignIn) {
      throw failureMessage;
    }
    _demo = false;
    _user = UserProfile(uid: 'real_user_1', email: email, displayName: 'Real User');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (shouldFailSignIn) {
      throw failureMessage;
    }
    _demo = false;
    _user = UserProfile(uid: 'real_user_new', email: email, displayName: displayName);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldFailSignIn) {
      throw failureMessage;
    }
  }

  @override
  Future<UserProfile> signInDemo() async {
    _demo = true;
    _user = const UserProfile(uid: 'demo_user', email: 'demo@chatflow.io', displayName: 'Demo Devon');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    if (shouldFailSignOut) {
      throw 'Network failure during signOut';
    }
    _demo = false;
    _user = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('AuthState Unit Tests', () {
    test('AuthState factory constructors instantiate expected status', () {
      final unauth = AuthState.unauthenticated();
      expect(unauth.status, AuthStatus.unauthenticated);
      expect(unauth.isAuthenticated, false);
      expect(unauth.isLoading, false);

      final loading = AuthState.loading();
      expect(loading.status, AuthStatus.loading);
      expect(loading.isLoading, true);

      final err = AuthState.error('Network failure');
      expect(err.status, AuthStatus.error);
      expect(err.errorMessage, 'Network failure');

      const user = UserProfile(uid: 'u1', displayName: 'Tester', email: 't@t.com');
      final auth = AuthState.authenticated(user, isDemoMode: false);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.isAuthenticated, true);
      expect(auth.isDemoMode, false);

      final authDemo = AuthState.authenticated(user, isDemoMode: true);
      expect(authDemo.isDemoMode, true);
    });
  });

  group('AuthNotifier State Management Tests', () {
    late MockAuthRepository mockRepo;
    late AuthNotifier notifier;

    setUp(() {
      mockRepo = MockAuthRepository();
      notifier = AuthNotifier(mockRepo);
    });

    tearDown(() {
      notifier.dispose();
      mockRepo.dispose();
    });

    test('initial state is unauthenticated when no cached user', () {
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.isDemoMode, false);
    });

    test('signIn success transitions to authenticated with isDemoMode false', () async {
      await notifier.signIn('user@company.com', 'validPassword123');

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.isDemoMode, false);
      expect(notifier.state.user?.email, 'user@company.com');
      expect(notifier.state.errorMessage, isNull);
    });

    test('signIn failure transitions to error state and clearError clears message', () async {
      mockRepo.shouldFailSignIn = true;
      mockRepo.failureMessage = 'Incorrect email or password. Please verify and try again.';

      await notifier.signIn('wrong@company.com', 'wrongPassword');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.errorMessage, contains('Incorrect email or password'));

      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });

    test('signUp creates user and authenticates cleanly', () async {
      await notifier.signUp(
        email: 'newuser@chatflow.io',
        password: 'securePassWord123',
        displayName: 'New Explorer',
      );

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.displayName, 'New Explorer');
      expect(notifier.state.isDemoMode, false);
    });

    test('enterDemoMode sets isDemoMode true and authenticates demo user', () async {
      await notifier.enterDemoMode();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.isDemoMode, true);
      expect(notifier.state.user?.displayName, 'Demo Devon');
    });

    test('signOut clears user profile and resets isDemoMode', () async {
      await notifier.enterDemoMode();
      expect(notifier.state.isAuthenticated, true);

      await notifier.signOut();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.user, isNull);
      expect(notifier.state.isDemoMode, false);
    });

    test('signOut guarantees transition to unauthenticated even if repository throws error', () async {
      await notifier.enterDemoMode();
      expect(notifier.state.isAuthenticated, true);

      mockRepo.shouldFailSignOut = true;
      await notifier.signOut();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, false);
    });

    test('resetState immediately resets loading state to unauthenticated', () {
      notifier.state = AuthState.loading();
      expect(notifier.state.isLoading, true);

      notifier.resetState();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isLoading, false);
    });

    test('sendPasswordReset rethrows failure when email sending fails', () async {
      mockRepo.shouldFailSignIn = true;
      mockRepo.failureMessage = 'No user found with this email address.';

      expect(
        () => notifier.sendPasswordReset('nonexistent@company.com'),
        throwsA(equals('No user found with this email address.')),
      );
    });
  });
}
