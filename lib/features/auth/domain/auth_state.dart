import '../../profile/domain/user_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// State representation for authentication in ChatFlow.
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;
  final bool isDemoMode;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isDemoMode = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
    bool? isDemoMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }

  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
  factory AuthState.authenticated(UserProfile user, {bool isDemoMode = false}) =>
      AuthState(status: AuthStatus.authenticated, user: user, isDemoMode: isDemoMode);
}
