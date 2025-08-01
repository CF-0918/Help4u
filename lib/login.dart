import 'package:flutter/material.dart';
import 'package:help4u_assignment/Home.dart';
import 'package:help4u_assignment/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text;

      // Simulated fake data check
      if (email == "yfung2574@gmail.com" && password == "Yong.0918") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("userEmail", email);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful")),
        );

        // Navigate to home/dashboard (fake)
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Home()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Invalid email or password"),
            backgroundColor: Colors.red, // 🔴 Red background
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Title section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/assets/LogoNoWord.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 15),
                const Text(
                  "Help4U",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                    fontSize: 30,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "-- Secure and simple login experience --",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            // Expanded Form section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B1919), // Deep black/grey
                      Color(0xFF484646), // Medium dark grey
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(fontSize: 18, color: Colors.white), // White input text
                            decoration: const InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: Colors.white), // White label
                              prefixIcon: Icon(Icons.email, color: Colors.white), // White icon
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white70),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // Password field
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white, fontSize: 18), // Input text color
                            decoration: const InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.white), // Label text color
                              prefixIcon: Icon(Icons.lock, color: Colors.white), // Icon color
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white70),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 25),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 6,
                                shadowColor: Colors.black45,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.login, size: 24),
                                  SizedBox(width: 10),
                                  Text("Login Now",),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          Divider(
                            thickness: 1,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              "Another login method",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Image.asset("images/assets/google.png",width: 30,
                                  height: 30,),
                                iconSize: 10,
                                onPressed: () {
                                  // Handle Google login
                                },
                              ),
                              SizedBox(width: 20),
                              IconButton(
                                icon: Image.asset("images/assets/facebook.png",width: 30,
                                  height: 30,),
                                iconSize: 10,
                                onPressed: () {
                                  // Handle Facebook login
                                },
                              ),
                              SizedBox(width: 20),
                              IconButton(
                                icon: Image.asset("images/assets/instagram.png",width: 30,
                                  height: 30,),
                                iconSize: 10,
                                onPressed: () {
                                  // Handle Instagram login
                                },
                              ),
                            ],
                          ),


                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
