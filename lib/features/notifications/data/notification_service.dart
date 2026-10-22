import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/firebase_initializer.dart';

/// Top-level background message handler for FCM.
/// Must be outside of any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handles notifications received while the app is in the background or terminated.
  debugPrint('FCM Background message received: ${message.messageId}');
}

abstract class BaseNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> syncUserFcmToken(String userId);
}

class NotificationService implements BaseNotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    if (!FirebaseInitializer.isLiveConfigured) {
      debugPrint('FCM running in simulated mode (no live Firebase configuration).');
      return;
    }

    try {
      // Request user permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification authorization status: ${settings.authorizationStatus}');

      // Configure foreground presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.notification?.title}');
      });

      // Handle message open event (when user taps on notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened from background: ${message.data}');
      });
    } catch (e) {
      debugPrint('Notice: FCM initialization skipped or unsupported: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    if (!FirebaseInitializer.isLiveConfigured) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Notice: Unable to retrieve FCM token: $e');
      return null;
    }
  }

  @override
  Future<void> syncUserFcmToken(String userId) async {
    if (!FirebaseInitializer.isLiveConfigured) return;
    try {
      final token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Notice: FCM token sync skipped: $e');
    }
  }
}
