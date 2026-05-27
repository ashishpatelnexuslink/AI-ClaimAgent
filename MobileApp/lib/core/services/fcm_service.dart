import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:claim_ai/features/notifications/domain/repositories/notifications_repository.dart';

/// Background handler MUST be a top-level (non-anonymous) function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate — keep work minimal. The data payload still reaches the
  // foreground handlers via onMessageOpenedApp / getInitialMessage on tap.
  if (kDebugMode) {
    debugPrint('[FCM bg] ${message.messageId} data=${message.data}');
  }
}

class FcmService {
  FcmService({required NotificationsRepository repository})
    : _repository = repository;

  final NotificationsRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _tapStream =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _messageStream =
      StreamController<RemoteMessage>.broadcast();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'claim_ai_default',
    'Claim updates',
    description: 'Notifications about your claim status and required actions.',
    importance: Importance.high,
  );

  String? _currentToken;
  bool _initialized = false;

  /// Stream of messages emitted when the user taps a notification.
  Stream<RemoteMessage> get onMessageTap => _tapStream.stream;

  /// Stream of every incoming foreground message — listeners use this to
  /// refresh in-app state (e.g. the home page notification card).
  Stream<RemoteMessage> get onMessageReceived => _messageStream.stream;

  /// Most recent FCM token (cached after registration).
  String? get currentToken => _currentToken;

  /// Call after the user has authenticated. Requests permission, fetches the
  /// token, registers it with the backend, and wires foreground/tap handlers.
  Future<void> initializeAndRegister() async {
    if (!_initialized) {
      await _initLocalNotifications();
      _initialized = true;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Still wire token refresh; user can grant later in OS settings.
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    _currentToken = token;
    await _sendTokenToBackend(token);

    // Avoid stacking listeners across multiple logins.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await _sendTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_tapStream.add);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _tapStream.add(initial);
  }

  /// Call on logout. Tells the backend to forget this device and clears the
  /// local token so a fresh one is issued on the next login.
  Future<void> unregister() async {
    final token = _currentToken;
    if (token != null && token.isNotEmpty) {
      await _repository.unregisterDevice(token);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort — ignore if FCM isn't reachable.
    }
    _currentToken = null;
  }

  Future<void> _sendTokenToBackend(String token) async {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    await _repository.registerDevice(fcmToken: token, platform: platform);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _messageStream.add(message);

    final notif = message.notification;
    if (notif == null) return;

    _localNotifications.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> dispose() async {
    await _tapStream.close();
    await _messageStream.close();
  }
}
