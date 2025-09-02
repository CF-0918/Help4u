import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Home.dart';
import 'Login.dart';

class Wrapperr extends StatelessWidget {
  const Wrapperr({super.key});

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      // emits on SIGNED_IN / SIGNED_OUT / TOKEN_REFRESHED, etc.
      stream: supa.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // while connecting we can still check the current cached session
        final session = supa.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show splash while we decide
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If no session (signed out) -> Login
        if (session == null) {
          return const Login();
        }

        // Session exists -> Home
        return const Home();
      },
    );
  }
}
