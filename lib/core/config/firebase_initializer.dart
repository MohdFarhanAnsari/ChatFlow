import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

/// Manages Firebase initialization safely and reports configuration readiness.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _isInitialized = false;
  static bool _isLiveConfigured = false;
  static String? _initErrorMessage;

  static bool get isInitialized => _isInitialized;
  static bool get isLiveConfigured => _isLiveConfigured;
  static String? get initErrorMessage => _initErrorMessage;

  /// Initializes Firebase with platform options.
  /// Does not crash if placeholder credentials are used.
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _isLiveConfigured = true;
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isInitialized = true;
      // If the apiKey contains 'Placeholder', it indicates manual config is pending
      if (DefaultFirebaseOptions.android.apiKey.contains('Placeholder')) {
        _isLiveConfigured = false;
        developer.log(
          'Firebase initialized with placeholder options. Live auth and sync require real Firebase Console setup.',
          name: 'ChatFlow.Firebase',
        );
      } else {
        _isLiveConfigured = true;
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      _isLiveConfigured = false;
      _initErrorMessage = e.toString();
      debugPrint('Firebase initialization notice: $e');
      developer.log(
        'Firebase not configured with valid cloud credentials: $e',
        name: 'ChatFlow.Firebase',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
