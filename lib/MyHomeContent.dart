import 'package:flutter/material.dart';

import 'login.dart';

class MyHomeContent extends StatelessWidget {

  const MyHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            }, 
            child: Text("Login here")
        ),
      )
    );
  }
}
