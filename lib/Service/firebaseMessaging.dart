import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:workshop_assignment/Repository/userDevice_repo.dart';

import '../authencation/auth_service.dart';

/// Top-level background handler (must be a global function!)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Background message: ${message.notification?.title}");
  await FirebaseMessagingService().showLocalNotification(message);
}

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final AuthService authService = AuthService();

  /// Call this at app startup
  Future<void> initNotifications() async {
    // Request permissions (especially for iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await getToken();
    print("✅ FCM Token: $token");

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print("♻️ FCM Token refreshed: $newToken");
      if (authService.currentUserId != null) {
        UserDevicesRepository().upsertToken(
          userProfileId: authService.currentUserId!,
          deviceToken: newToken,
          platform: Platform.isAndroid ? 'android' : 'ios',
        );
      }
    });

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(initSettings);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message: ${message.notification?.title}");
      showLocalNotification(message);
    });

    // Background/terminated handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // When user taps notification and opens app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Notification clicked! ${message.notification?.title}");
      // TODO: Navigate to specific screen if needed
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<String> getPlatform() async {
    if (Platform.isAndroid) return "android";
    if (Platform.isIOS) return "ios";
    return "web";
  }

  /// Show a local notification
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General Notifications',
      channelDescription: 'This channel is used for general notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'No Title',
      notification.body ?? 'No body',
      platformDetails,
      payload: message.data.toString(), // Pass custom data if needed
    );
  }
}
