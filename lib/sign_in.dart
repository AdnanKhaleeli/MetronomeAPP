import 'package:flutter/material.dart';
import 'customdrawer.dart';
import 'database.dart';
import 'main.dart';
import 'user.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login or Sign up'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      drawer: CustomDrawer(
        isOnSignInPage: true,
        user: null,
      ),
      body: Center(
        child: Column(
          children: [LogIn()],
        ),
      ),
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
  bool sign_up = false;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _profileController = TextEditingController();

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> _isUsernameUnique(String username) async {
    var db = DatabaseHelper();
    await db.init();
    return await db.checkUserNameUnique(username);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(children: <Widget>[
        Container(
          margin: EdgeInsets.all(40),
          child: TextFormField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null; // Assume valid for now
            },
            onChanged: (value) async {
              // Check for uniqueness on input change (only if in sign-up mode)
              if (value.isNotEmpty && sign_up) {
                bool isUnique = await _isUsernameUnique(value);
                if (!isUnique) {
                  _showSnackBar('Username is already taken');
                }
              }
            },
          ),
        ),
        Container(
          margin: EdgeInsets.all(40),
          child: TextFormField(
            controller: _pwdController,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return null; // Assume valid for now
            },
          ),
        ),
        if (sign_up)
          Container(
            margin: EdgeInsets.all(40),
            child: TextFormField(
              controller: _profileController,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                hintText: 'Enter your profile name',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a profile name';
                }
                return null;
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  sign_up = false; // Switch to login
                });
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  sign_up = true; // Switch to sign-up
                });
              },
              child: Text('SignUp'),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () async {
            if (sign_up) {
              // Sign-up logic
              if (_formKey.currentState!.validate()) {
                bool isUnique =
                    await _isUsernameUnique(_userNameController.text);
                if (!isUnique) {
                  _showSnackBar('Error: Username taken');
                  return;
                }

                // Insert student if unique
                var db = DatabaseHelper();
                await db.init();
                await db.insertStudent(
                  username: _userNameController.text,
                  pwd: _pwdController.text,
                  profilename: _profileController.text,
                );

                var userID = await db.getUserID(_userNameController.text);
                if (userID != null) {
                  User user = User(
                    userId: userID,
                    username: _userNameController.text,
                    password: _pwdController.text,
                    profileName: _profileController.text,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetronomeApp(user: user),
                    ),
                  );
                }
              }
            } else {
              // Login logic
              if (_formKey.currentState!.validate()) {
                var db = DatabaseHelper();
                await db.init();

                var userID = await db.getUserID(_userNameController.text);
                if (userID == null) {
                  _showSnackBar(
                      'Username not found'); // Show feedback only if username is not found
                  return;
                }

                var user =
                    await db.loginUser(_userNameController.text, _pwdController.text);

                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetronomeApp(user: user),
                    ),
                  );
                }
              }
            }
          },
          child: Text('Submit'),
        ),
      ]),
    );
  }
}
