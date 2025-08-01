import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Home.dart';
import 'login.dart';
import 'main.dart'; // Make sure this contains LoginPage
// import 'home.dart'; // Uncomment and import your actual HomePage

class AuthSelectionPage extends StatefulWidget {
  const AuthSelectionPage({super.key});

  @override
  State<AuthSelectionPage> createState() => _AuthSelectionPageState();
}

class _AuthSelectionPageState extends State<AuthSelectionPage> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // ✅ Check login status when screen loads
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    if (isLoggedIn) {
      // 🔁 Go to home screen if user is already logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()), // replace with your real HomePage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'images/assets/LogoNoWord.png',
              height: 55,
              width: 55,
            ),
            const SizedBox(width: 10),
            const Text(
              'Help4U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hey, Welcome Back",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                "images/assets/login.jpg",
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 2),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black45,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  fixedSize: const Size(300, 50),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
                child: const Text("Login"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 2),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shadowColor: Colors.black45,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  fixedSize: const Size(300, 50),
                ),
                onPressed: () {
                  // TODO: Navigate to register page
                },
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



