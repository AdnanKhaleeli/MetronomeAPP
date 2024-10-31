import 'package:flutter/material.dart';
import 'package:metronome/main.dart';
import 'user.dart';

class CustomDrawer extends StatelessWidget {

  final Function? stopMetronome;
  final User? user;

  CustomDrawer({
  
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
            accountEmail:
                Text(user != null ? "user@example.com" : "guest@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user != null ? user!.profileName[0] : "G",
                style: TextStyle(fontSize: 40.0, color: Colors.red),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.red[400],
            ),
          ),
          if(ModalRoute.of(context)?.settings.name != '/')
          ListTile(
            title: Text('Home'),
            onTap: () {
              Navigator.pushNamed(context, '/', arguments: user);
            },
            
          ),
          if (ModalRoute.of(context)?.settings.name != '/sign_in')
            ListTile(
              title: Text(user == null ? 'Sign Up / Log In' : 'Profile'),
              onTap: () {
                if (user == null) {
                  Scaffold.of(context).closeDrawer();
                  stopMetronome?.call();
                  Navigator.pushNamed(context, '/sign_in');
                }
              },
            ),
          if (user is Conductor)
            ListTile(
                title: Text("Add Music"),
                onTap: () {
                  Navigator.pushNamed(context, '/addMusic', arguments: user);
                }),
          ListTile(
            title: Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            title: Text('About'),
            onTap: () {},
          ),
          if (user != null)
            ListTile(
              title: Text('Logout'),
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
    );
  }
}
