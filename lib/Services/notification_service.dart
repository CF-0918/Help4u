import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../Home.dart';
import '../firebase_options.dart';
import '../main.dart'; // 👈 Import where navigatorKey is defined

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Keep navKey as static for app-wide access if needed
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Handles background/terminated push
  @pragma("vm:entry-point")
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _initializeLocalNotification();
    await _showFlutterNotification(message);
  }

  /// Call this during app startup with your navigatorKey
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    await _firebaseMessaging.requestPermission();
    await _getFcmToken();
    await _initializeLocalNotification();
    await getInitialNotification();

    // Listen for messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground message: ${message.data}");
      await _showFlutterNotification(message);
    });
  }

  /// Request & print FCM token
  static Future<void> _getFcmToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
  }

  /// Show notification when received
  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic>? data = message.data;

    String title = notification?.title ?? "No title";
    String body = notification?.body ?? "No body";

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      channelDescription: 'CHANNEL_DESCRIPTION',
      priority: Priority.high,
      importance: Importance.max,
    );

    DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // For demo/testing, you can include route info in payload
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: data['route'] ?? 'custom_payload', // for navigation
    );
  }

  /// Setup platform-specific initialization
  static Future<void> _initializeLocalNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@drawable/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  /// Handle navigation when tapping on notification
  static void _handleNotificationResponse(NotificationResponse response) {
    print("Tapped Notification: ${response.payload}");
    if (response.payload == 'AppointmentPage') {
      _navigatorKey?.currentState?.push(MaterialPageRoute(
        builder: (_) => const Home(),
      ));
    } else if (response.payload == 'custom_payload') {
      // Optional: show dialog, push another route
      print("Handle other payload");
    }
  }

  /// When app is terminated and opened via push
  static Future<void> getInitialNotification() async {
    RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      print("App launched from terminated via push: ${message.data}");
      if (message.data['route'] == 'goToFormPage') {
        _navigatorKey?.currentState?.pushNamed('/form');
      } else if (message.data['route'] == 'AppointmentPage') {
        _navigatorKey?.currentState?.push(MaterialPageRoute(builder: (_) => const Home()));
      }
    }
  }


  /// Manually show custom notification (for demo)
  static Future<void> showCustomNotification({
    required String title,
    required String body,
    String payload = 'AppointmentPage', // default for testing
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'custom_channel_id',
      'Custom Channel',
      channelDescription: 'Channel for custom notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      2,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
