
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse, AuthException;
import 'package:workshop_assignment/Components/Loading.dart';
import 'package:workshop_assignment/Screen/OtpVerification.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

import 'ForgetPassword.dart';
import 'Home.dart';
import 'SignUp.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  //supabase instance
  final AuthService _authService= AuthService();

  final _formKey = GlobalKey<FormState>();

  // Field keys (to check which one has errors)
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _passFieldKey  = GlobalKey<FormFieldState<String>>();

  // Controllers & focus nodes
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _showPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }



  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final input = value.trim().replaceAll(RegExp(r'\D'), '');

    // Case 1: starts with "1" but not "11" → must be 8 digits
    if (RegExp(r'^(1[02-9])[0-9]{7}$').hasMatch(input)) {
      return null; // valid
    }

    // Case 2: starts with "11" → must be 9 digits
    if (RegExp(r'^(11)[0-9]{8}$').hasMatch(input)) {
      return null; // valid
    }

    return 'Enter a valid Malaysian phone number';
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null; // valid
  }


  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      if (_phoneFieldKey.currentState?.hasError ?? false) {
        _phoneFocus.requestFocus();
      } else if (_passFieldKey.currentState?.hasError ?? false) {
        _passwordFocus.requestFocus();
      }
      return;
    }

    // Show loading
    LoadingOverlay.show(context, message: 'Signing in...');

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final resp = await _authService.login(phone: phone, password: password);
      if (resp.user == null) throw Exception('Sign-in failed. Please try again.');

      if (!mounted) return;

      // ✅ close loading FIRST, then navigate
     LoadingOverlay.hide(context);

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      LoadingOverlay.hide(context); // ✅ close loading on error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.hide(context); // ✅ close loading on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Container(
                    width: 110,
                    height: 100,
                    color: Colors.white,
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 25, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Poppins', letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Sign in to your account to continue",
                  style: TextStyle(
                    fontSize: 15, color: Colors.white,
                    fontFamily: 'Poppins', letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 15),

                Container(
                  margin:const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.fromLTRB(15, 22, 15, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Phone", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _phoneFieldKey,
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          validator: validatePhone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            prefixIcon: const Icon(Icons.phone, color: Colors.white),
                            prefixText: "+60 ",
                            floatingLabelBehavior: FloatingLabelBehavior.always, // <----- just add this
                            prefixStyle: const TextStyle(color: Colors.white, fontSize: 16),
                            hintText: "128082165",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontFamily: 'Poppins', letterSpacing: 0.5, fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF9B5DE5), width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text("Password", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _passFieldKey,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          validator: validatePassword,
                          obscureText: _showPassword,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            prefixIcon: const Icon(Icons.password, color: Colors.white),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            hintText: "Enter your password",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontFamily: 'Poppins', letterSpacing: 0.5, fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF9B5DE5), width: 2),
                            ),
                          ),
                        ),

                        SizedBox(height:10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: (){
                                Navigator.push(context,MaterialPageRoute(builder:(context) => const Login()));
                              },
                              child: TextButton(
                                onPressed: () {
                                  // TODO: navigate to ForgetPassword page
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgetPassword()),
                                  );
                                },
                                child: const Text(
                                  "Forget Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                          ),
                        ),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            width: 250,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                          onPressed: (){
                            Navigator.push(context,MaterialPageRoute(builder:(context) => const SignUp()));
                          },
                          child: Text("Sign Up Now",style: TextStyle(
                            color: Color(0xFF9B5DE5),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),)
                      )
                    ],
                  )
                ),
                SizedBox(height: 20,),
                Center(
                  child: Text("@2025 Workshop App. All rights reserved.",style: TextStyle(fontSize: 12,color: Colors.white),),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
