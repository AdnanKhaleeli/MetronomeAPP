import 'package:flutter/material.dart';
import 'main.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      drawer: CustomDrawer(), // Use the same CustomDrawer
      body: Center(
        child: Text('Sign In Screen'),
      ),
    );
  }
}
