import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsApi {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'otp_channel',                   // MUST be stable
    'OTP & Alerts',
    description: 'Immediate OTP notifications',
    importance: Importance.high,     // show heads-up
  );

  /// Call once in main() BEFORE runApp()
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); // <-- this one

    // Create channel (Android 8+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }


  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'otp',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(1001, title, body, details, payload: payload);
  }
}
