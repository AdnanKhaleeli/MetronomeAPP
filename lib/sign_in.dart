import 'package:flutter/material.dart';
import 'customdrawer.dart';


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
      drawer: CustomDrawer(isOnSignInPage: true,),
      body: Center(
        child: Text('Sign In Screen'),
      ),
    );
  }
}
