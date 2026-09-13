import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/radio_api_client.dart';
import 'push_navigation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _openedAppSubscription;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (token) => _registerToken(token),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM token refresh error: $error');
      },
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    await _openedAppSubscription?.cancel();
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageTap,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM opened-app error: $error');
      },
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground message: ${message.messageId ?? 'sin-id'} '
        '${message.notification?.title ?? ''}',
      );
    });
  }

  static void _handleMessageTap(RemoteMessage message) {
    final action = message.data['action']?.toString();
    debugPrint('FCM tap action: ${action ?? 'open-app'}');
    PushNavigation.request(action);
  }

  static Future<void> _registerToken(String token) async {
    try {
      await RadioApiClient().registerPushDevice(token: token);
      debugPrint('FCM device registered with Radio API.');
    } catch (error) {
      debugPrint('FCM device registration failed: $error');
    }
  }
}
