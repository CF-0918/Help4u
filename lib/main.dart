
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Provider/LocationProvider.dart';
import 'package:workshop_assignment/Screen/AppointmentDetails.dart';
import 'package:workshop_assignment/Screen/Home.dart';
import 'package:workshop_assignment/Screen/RouteWrapper.dart';
import 'package:workshop_assignment/Screen/SignUp.dart';
import 'package:workshop_assignment/Screen/wrapperr.dart';
import 'Screen/Login.dart';
import 'Screen/ResetPasswod.dart';
import 'Screen/payment.dart';
import 'Service/firebaseMessaging.dart';
import 'Service/localNotificationApi.dart';
import 'firebase_options.dart';
import 'Screen/Billing.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String normalizeRoute(String? raw) {
  var r = (raw ?? '').trim();
  if (r.isEmpty) return r;
  if (!r.startsWith('/')) r = '/$r';
  // Case-insensitive aliases → canonical keys in routes:
  switch (r.toLowerCase()) {
    case '/appointments':
      return '/Appointments';
    case '/servicereminder':
      return '/ServiceReminder';
    case '/home':
      return '/home';
    case '/payment':
      return '/payment';
    default:
      return r;
  }
}

Future<void> initializeFireabseDefault() async {
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Initialized default app $app');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFireabseDefault();

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

  final fcmService = FirebaseMessagingService();//helper that i crearte to use firebase
  await fcmService.initNotifications();//this will initliaze or get peromission and token
  await NotificationsApi.init();

  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession; // or (await auth.getSession()).data.session;
  if(auth.currentSession != null&& auth.currentUser != null) {
    print('access: ${session?.accessToken}');
    print('refresh: ${session?.refreshToken}');
  }

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
        navigatorKey: navigatorKey,
        // DO NOT set `home:` if you also define '/' in routes (avoid conflicts).
        initialRoute: '/',
        routes: {
          '/login': (_) => const Login(),
          '/home': (_) => const Home(),
          '/billing': (_) => const Billing(),
          // Wrappers read ModalRoute.settings.arguments and pass to real pages
          '/AppointmentDetails': (_) => const AppointmentsRouteWrapper(),
          '/ServiceReminder': (_) => const ServiceReminderRouteWrapper(),
        },
        onGenerateRoute: (settings) {
          final normalized = normalizeRoute(settings.name);
          // If it's already one of our canonical keys, return null here
          // so Flutter will look it up in `routes:` above.
          if (normalized == '/payment') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                settings: RouteSettings(name: normalized, arguments: args),
                builder: (_) => PaymentPage(
                  caseId: args['caseId'] as String,
                  bookingId: args['bookingId'] as String,
                  amount: args['amount'] as String,
                  currency: args['currency'] as String? ?? 'MYR',
                  description: args['description'] as String?,
                ),
              );
            } else {
              // Handle case where no arguments are provided
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Payment Error')),
                  body: const Center(
                    child: Text('Payment arguments missing'),
                  ),
                ),
              );
            }
          }


          if (normalized == settings.name) return null;

          // Otherwise, build a route to the canonical destination.
          switch (normalized) {
            case '/AppointmentDetails':
              return MaterialPageRoute(
                settings: RouteSettings(name: normalized, arguments: settings.arguments),
                builder: (_) => const AppointmentsRouteWrapper(),
              );
            case '/ServiceReminder':
              return MaterialPageRoute(
                settings: RouteSettings(name: normalized, arguments: settings.arguments),
                builder: (_) => const ServiceReminderRouteWrapper(),
              );
          }
          return null; // allow unknownRoute to catch
        },
        onUnknownRoute: (settings) {
          debugPrint('❓ onUnknownRoute: "${settings.name}"  args=${settings.arguments}');
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Unknown Route')),
              body: Center(child: Text('No route named "${settings.name}"')),
            ),
          );
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
