import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/radio_api_client.dart';
import 'push_navigation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static const _channelId = 'somos_radio_updates';
  static const _channelName = 'Avisos de Somos Radio';
  static const _channelDescription =
      'Noticias, avisos y accesos directos de Somos Radio.';
  static const _deduplicationWindow = Duration(minutes: 5);

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final Map<String, DateTime> _processedForegroundMessages = {};

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _openedAppSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();

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

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM foreground error: $error');
      },
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('ic_stat_somos_radio');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final action = response.payload?.trim();
        debugPrint('Local notification tap action: ${action ?? 'open-app'}');
        PushNavigation.request(action);
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static bool _isDuplicateForegroundMessage(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId == null || messageId.isEmpty) return false;

    final now = DateTime.now();
    _processedForegroundMessages.removeWhere(
      (_, processedAt) => now.difference(processedAt) > _deduplicationWindow,
    );

    if (_processedForegroundMessages.containsKey(messageId)) {
      return true;
    }

    _processedForegroundMessages[messageId] = now;
    return false;
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_isDuplicateForegroundMessage(message)) {
      debugPrint(
        'FCM duplicate foreground message ignored: '
        '${message.messageId ?? 'sin-id'}',
      );
      return;
    }

    debugPrint(
      'FCM foreground message: ${message.messageId ?? 'sin-id'} '
      '${message.notification?.title ?? ''}',
    );

    final notification = message.notification;
    if (notification == null) return;

    final action = message.data['action']?.toString().trim();
    final payload = action == null || action.isEmpty ? null : action;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_somos_radio',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: notification.title ?? 'Somos Radio',
      body: notification.body,
      notificationDetails: details,
      payload: payload,
    );
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
