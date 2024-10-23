import 'package:flutter/material.dart';
import 'package:metronome/main.dart';
import 'user.dart';

class CustomDrawer extends StatelessWidget {
  final bool isUserSignedIn;
  final bool isOnSignInPage;
  final Function? stopMetronome;
  final User? user;

  CustomDrawer({
    this.isUserSignedIn = false,
    this.isOnSignInPage = false,
    this.stopMetronome,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user != null ? user!.getProfileName() : "Guest"),
            accountEmail: Text(isUserSignedIn ? "user@example.com" : "guest@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                isUserSignedIn ? "U" : "G",
                style: TextStyle(fontSize: 40.0, color: Colors.red),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.red[400],
            ),
          ),
          if (!isOnSignInPage)
            ListTile(
              title: Text(user == null ? 'Sign Up / Log In' :  'Profile'),
              onTap: () {
                if (!isUserSignedIn) {
                  Scaffold.of(context).closeDrawer();
                  stopMetronome?.call();
                  Navigator.pushNamed(context, '/sign_in');
                }
              },
            ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            title: Text('About'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
