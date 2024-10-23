import 'package:flutter/material.dart';
import 'customdrawer.dart';
import "database.dart";

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login or Sign_up'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      drawer: CustomDrawer(
        isOnSignInPage: true,
      ),
      body: Center(
          child: Column(
        children: [LogIn()],
      )),
    );
  }
}

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _password;
  bool sign_up = false;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: <Widget>[
          Container(
            margin: EdgeInsets.all(40),
            child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                }),
          ),
          Container(
            margin: EdgeInsets.all(40),
            child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                }),
          ),
          if (sign_up)
            Container(
              margin: EdgeInsets.all(40),
              child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Profile name',
                      hintText: 'Enter your profile name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 15.0)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a profile name';
                    }
                    return null;
                  }),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                     sign_up = false; // Update state to show login fields
                  });
                  },
                  child: Text('Login')),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                    sign_up = true; // Update state to show login fields
                    });
                  },
                  child: Text('SignUp')),
            ],
          )
        ]));
  }
}
