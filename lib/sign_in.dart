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
      drawer: CustomDrawer(user: null),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LogIn(),
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
  String? selectedRole;
  List<String> roles = [
    'Soprano Cornet', 'Solo Cornet', 'Repiano Cornet', 'Second Cornet', 'Third Cornet',
    'Flugelhorn', 'Solo Horn', 'Horn 1', 'Horn 2', 'Baritone 1', 'Baritone 2',
    'Trombone 1', 'Trombone 2', 'Bass Trombone', 'Euphonium', 'E-flat Bass', 
    'B-Flat Bass', 'Percussion'
  ];

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: ToggleButtons(
            isSelected: [!sign_up, sign_up],
            onPressed: (int index) {
              setState(() {
                sign_up = index == 1;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Login'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
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
              return null;
            },
            onChanged: (value) async {
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
              return null;
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
        if (sign_up)
          Container(
            margin: EdgeInsets.all(40),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Band Role',
                border: OutlineInputBorder(),
              ),
              value: selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue;
                });
              },
              items: roles.map<DropdownMenuItem<String>>((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Please select a role';
                }
                return null;
              },
            ),
          ),
        ElevatedButton(
          onPressed: () async {
            if (sign_up) {
              if (_formKey.currentState!.validate()) {
                bool isUnique =
                    await _isUsernameUnique(_userNameController.text);
                if (!isUnique) {
                  _showSnackBar('Error: Username taken');
                  return;
                }

                var db = DatabaseHelper();
                await db.init();
                await db.insertStudent(
                  username: _userNameController.text,
                  pwd: _pwdController.text,
                  profilename: _profileController.text,
                  role: selectedRole ?? '',
                );

                var userID = await db.getUserID(_userNameController.text);
                if (userID != null) {
                  Student user = Student(
                    userId: userID,
                    username: _userNameController.text,
                    password: _pwdController.text,
                    profileName: _profileController.text,
                    role: selectedRole ?? '',
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
              if (_formKey.currentState!.validate()) {
                var db = DatabaseHelper();
                await db.init();

                var userID = await db.getUserID(_userNameController.text);
                if (userID == null) {
                  _showSnackBar('Username not found');
                  return;
                }

                var user = await db.loginUser(
                    _userNameController.text, _pwdController.text);

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
