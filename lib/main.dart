import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_initializer.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/data/notification_service.dart';
import 'package:chatflow/features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase Cloud services
  await FirebaseInitializer.initialize();

  // Register background FCM handler if Firebase is operational
  if (FirebaseInitializer.isLiveConfigured) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize notification channels and permissions asynchronously without blocking app launch
  NotificationService()
      .initialize()
      .timeout(
        const Duration(seconds: 4),
        onTimeout: () => debugPrint('NotificationService init timed out.'),
      )
      .catchError((e) {
        debugPrint('NotificationService init notice: $e');
      });

  runApp(
    const ProviderScope(
      child: ChatFlowApp(),
    ),
  );
}

class ChatFlowApp extends ConsumerStatefulWidget {
  const ChatFlowApp({super.key});

  @override
  ConsumerState<ChatFlowApp> createState() => _ChatFlowAppState();
}

class _ChatFlowAppState extends ConsumerState<ChatFlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(isOnline: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updatePresence(isOnline: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(isOnline: true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updatePresence(isOnline: false);
    }
  }

  void _updatePresence({required bool isOnline}) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final isDemo = ref.read(isDemoModeProvider);
      // Only set presence in Demo mode. Firestore presence is out of scope.
      if (isDemo) {
        ref.read(profileRepositoryProvider).setPresence(
              uid: user.uid,
              isOnline: isOnline,
              isDemoMode: true,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
