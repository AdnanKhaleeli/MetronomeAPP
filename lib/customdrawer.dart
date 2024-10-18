import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final bool isUserSignedIn;
  final bool isOnSignInPage; // New parameter to check if on sign-in page

  CustomDrawer({
    this.isUserSignedIn = false,
    this.isOnSignInPage = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(isUserSignedIn ? "User Name" : "Guest"),
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
          if (!isOnSignInPage) // Only show this if not on sign-in page
            ListTile(
              title: Text(isUserSignedIn ? 'Profile' : 'Sign Up / Log In'),
              onTap: () {
                if (isUserSignedIn) {
                  // Navigate to profile
                } else {
                  Navigator.pushNamed(context, '/sign_in');
                }
              },
            ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              // Navigate to Settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            title: Text('About'),
            onTap: () {
              // Navigate to About
            },
          ),
        ],
      ),
    );
  }
}
