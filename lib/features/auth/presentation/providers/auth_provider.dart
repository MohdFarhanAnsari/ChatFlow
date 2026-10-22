import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_state.dart';
import '../../data/auth_repository.dart';
import '../../../profile/domain/user_profile.dart';

final authRepositoryProvider = Provider<BaseAuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final BaseAuthRepository _authRepository;
  StreamSubscription<UserProfile?>? _authSubscription;

  AuthNotifier(this._authRepository) : super(const AuthState(status: AuthStatus.initial)) {
    _init();
  }

  void _init() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user, isDemoMode: _authRepository.isDemoMode);
      } else {
        if (!_authRepository.isDemoMode) {
          state = AuthState.unauthenticated();
        }
      }
    });

    // Check if there is an existing currentUser
    final current = _authRepository.currentUser;
    if (current != null) {
      state = AuthState.authenticated(current, isDemoMode: _authRepository.isDemoMode);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> signIn(String email, String password) async {
    if (state.isLoading) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authRepository
          .signInWithEmailAndPassword(email, password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Sign in timed out. Please check your network connection and try again.',
            ),
          );
      state = AuthState.authenticated(user, isDemoMode: false);
    } on TimeoutException catch (e) {
      state = AuthState.error(e.message ?? 'Sign in timed out. Please try again.');
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authRepository
          .signUpWithEmailAndPassword(
            email: email,
            password: password,
            displayName: displayName,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Registration timed out. Please check your network connection and try again.',
            ),
          );
      state = AuthState.authenticated(user, isDemoMode: false);
    } on TimeoutException catch (e) {
      state = AuthState.error(e.message ?? 'Registration timed out. Please try again.');
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authRepository
          .sendPasswordResetEmail(email)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Password reset timed out. Please check your network connection and try again.',
            ),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> enterDemoMode() async {
    if (state.isLoading) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final demoUser = await _authRepository
          .signInDemo()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Demo mode setup timed out.'),
          );
      state = AuthState.authenticated(demoUser, isDemoMode: true);
    } catch (e) {
      state = AuthState.error('Failed to enter demo mode: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Ensure local state cleans up even if remote call delays
        },
      );
    } catch (_) {
      // Ignore network errors on signout so user is always returned to unauthenticated state
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  void resetState() {
    state = AuthState.unauthenticated();
  }

  void updateUserProfile(UserProfile updatedUser) {
    if (state.user != null) {
      state = state.copyWith(user: updatedUser);
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isDemoMode;
});
