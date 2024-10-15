import 'package:flutter/material.dart';
import 'main.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
              appBar: AppBar(
                  title: Text('Please Sign In '),
                  centerTitle: true,
                  backgroundColor: Colors.red[300],
      ),
    )
       
    );
  }
}
