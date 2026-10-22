import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../profile/domain/user_profile.dart';
import '../../../core/config/firebase_initializer.dart';
import 'auth_repository.dart';

/// Pure production Firebase Authentication repository.
/// Communicates directly with Firebase Auth (Google Identity Toolkit)
/// without unneeded dependencies on Cloud Firestore or remote storage.
class FirebaseAuthRepository implements BaseAuthRepository {
  final fb.FirebaseAuth? _customFirebaseAuth;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
  }) : _customFirebaseAuth = firebaseAuth;

  fb.FirebaseAuth get _auth =>
      _customFirebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  bool get isDemoMode => false;

  @override
  UserProfile? get currentUser {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return null;
      return UserProfile(
        uid: fbUser.uid,
        displayName: (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : fbUser.email?.split('@').first ?? 'User',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
        createdAt: fbUser.metadata.creationTime,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    try {
      return _auth.authStateChanges().map((fbUser) {
        if (fbUser == null) return null;
        return UserProfile(
          uid: fbUser.uid,
          displayName: (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
              ? fbUser.displayName!.trim()
              : fbUser.email?.split('@').first ?? 'User',
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
          createdAt: fbUser.metadata.creationTime,
        );
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    if (!FirebaseInitializer.isLiveConfigured) {
      throw fb.FirebaseAuthException(
        code: 'configuration-required',
        message:
            'Firebase is running with placeholder settings. Connect your live Firebase project or explore Interactive Demo Mode.',
      );
    }

    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Connection timed out. Please check your internet connection and try again.',
            ),
          );

      final user = credential.user!;
      return UserProfile(
        uid: user.uid,
        displayName: (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'User',
        email: user.email ?? email.trim(),
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on TimeoutException catch (e) {
      throw e.message ?? 'Connection timed out. Please try again.';
    } catch (e) {
      throw 'Sign in failed: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  @override
  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!FirebaseInitializer.isLiveConfigured) {
      throw fb.FirebaseAuthException(
        code: 'configuration-required',
        message:
            'Firebase is running with placeholder settings. Connect your live Firebase project or explore Interactive Demo Mode.',
      );
    }

    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Connection timed out. Please check your internet connection and try again.',
            ),
          );

      final user = credential.user!;
      final trimmedName = displayName.trim();
      if (trimmedName.isNotEmpty) {
        try {
          await user.updateDisplayName(trimmedName).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      return UserProfile(
        uid: user.uid,
        displayName: trimmedName.isNotEmpty
            ? trimmedName
            : user.email?.split('@').first ?? 'User',
        email: user.email ?? email.trim(),
        bio: 'Hey there! I am using ChatFlow.',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on TimeoutException catch (e) {
      throw e.message ?? 'Connection timed out. Please try again.';
    } catch (e) {
      throw 'Registration failed: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!FirebaseInitializer.isLiveConfigured) {
      throw fb.FirebaseAuthException(
        code: 'configuration-required',
        message: 'Firebase is not yet configured for live password resets. Connect your Firebase project credentials.',
      );
    }

    try {
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Connection timed out. Please check your internet connection and try again.',
            ),
          );
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on TimeoutException catch (e) {
      throw e.message ?? 'Connection timed out. Please try again.';
    } catch (e) {
      throw 'Password reset request failed: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  @override
  Future<UserProfile> signInDemo() async {
    throw UnsupportedError('FirebaseAuthRepository does not handle demo sessions.');
  }

  String _handleFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Access is temporarily restricted. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console. Please enable it under Authentication > Sign-in method.';
      case 'configuration-required':
      case 'no-app':
        return e.message ?? 'Firebase configuration required.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }
}
