
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Provider/LocationProvider.dart';
import 'package:workshop_assignment/Screen/Home.dart';
import 'package:workshop_assignment/Screen/SignUp.dart';
import 'package:workshop_assignment/Screen/wrapperr.dart';
import 'Screen/Login.dart';
import 'Screen/ResetPasswod.dart';
import 'Service/localNotificationApi.dart';



final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // <-- no await
  await Supabase.initialize(
    url: 'https://rqpedrthgpgocmiliext.supabase.co',
    anonKey: 'sb_publishable_Pt3H8RVWKV3RVggnU6m9QA_IA9iqgDD',
  );
  // Listen for deep link auth events (reset link)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      // App was opened by the reset-password link
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordPageFromLink()),
      );
    }
  });

  await NotificationsApi.init();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,   // << important
        routes: {
          '/login': (_) => const Login(),
          '/home' : (_) => const Home(),   // <-- add this
          // add more routes here...
        },
        debugShowCheckedModeBanner: false,
        title: 'Workshop App',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: const Color(0xFF000000), // black bg
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA855F7), // purple as base
            brightness: Brightness.dark,
          ),
          cardColor: const Color(0xFF1C1C1E), // card background
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)), // white text
            bodySmall: TextStyle(color: Color(0xFF9CA3AF)),  // gray text
          ),
        ),
        home: const Wrapperr(),
      ),
    );
  }
}
