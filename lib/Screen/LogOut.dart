import 'package:flutter/material.dart';
import 'package:workshop_assignment/Screen/Login.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class LogOut extends StatefulWidget {
  const LogOut({super.key});

  @override
  State<LogOut> createState() => _LogOutState();
}

class _LogOutState extends State<LogOut> {
  @override
  void initState() {
    super.initState();
    // Show the dialog right after this page appears
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLogoutDialog());
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    ) ?? false;

    if (!mounted) return;

    if (confirm) {

      AuthService authService = AuthService();
      await authService.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
      );
    } else {
      Navigator.of(context).pop(); // just go back
    }
  }

  @override
  Widget build(BuildContext context) {
    // Must return something; a blank scaffold is fine
    return const Scaffold(body: SizedBox.shrink());
  }
}
