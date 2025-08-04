import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:help4u_assignment/AppointmentPage.dart';
import 'Services/notification_service.dart';
import 'firebase_options.dart';
import 'AuthSelectionPage.dart';

// 👇 Move navigatorKey here (globally accessible)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service AFTER Firebase initialized
  await NotificationService.init(navigatorKey);();

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 👈 Set it here
      supportedLocales: const [
        Locale('en', 'MY'),
      ],
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthSelectionPage(),
        '/form': (context) => const AppointmentPage(),
      },
    );
  }
}
