import 'package:flutter/material.dart';
import 'package:metronome/main.dart';
import 'user.dart';
import 'studentScreens/Assignments.dart';
import 'music.dart';

class CustomDrawer extends StatelessWidget {
  final Function? stopMetronome;
  User? user;
  List<Piece>? list;
  final Function? toggleVoice;

  CustomDrawer({this.stopMetronome, this.user, this.list, this.toggleVoice});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user != null ? user!.getProfileName() : "Guest"),
            accountEmail: Text(user != null ? user!.role : ""),
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
          if (ModalRoute.of(context)?.settings.name != '/')
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/', arguments: user);
              },
            ),
          if (ModalRoute.of(context)?.settings.name != '/sign_in')
            ListTile(
              title: Text(user == null ? 'Sign Up / Log In' : 'Profile'),
              onTap: () {
                if (user == null) {
                  Scaffold.of(context).closeDrawer();
                  stopMetronome?.call();
                  ModalRoute.of(context)?.settings.name == '/'
                      ? toggleVoice!()
                      : null;
                  Navigator.pushNamed(context, '/sign_in');
                }
              },
            ),
          if (ModalRoute.of(context)?.settings.name != '/assignments' &&
              user != null &&
              user is Student)
            ListTile(
              title: Text("Assignments"),
              onTap: () {
                if (user is Student) {
                  Scaffold.of(context).closeDrawer();
                  stopMetronome?.call();
                  ModalRoute.of(context)?.settings.name == '/'
                      ? toggleVoice!()
                      : null;
                  Navigator.pushNamed(context, '/assignments',
                      arguments: {'user': user, 'pieces': list});
                }
              },
            ),
          if (user is Conductor)
            ListTile(
                title: Text("Dashboard"),
                onTap: () {
                  stopMetronome?.call();
                  ModalRoute.of(context)?.settings.name == '/'
                      ? toggleVoice!()
                      : null;
                  Navigator.pushNamed(context, '/dashboard_conductor',
                      arguments: user);
                }),
          if (user is Conductor)
            ListTile(
                title: Text("Add Music"),
                onTap: () {
                  ModalRoute.of(context)?.settings.name == '/'
                      ? toggleVoice!()
                      : null;
                  Navigator.pushNamed(context, '/addMusic', arguments: user);
                  Scaffold.of(context).closeDrawer();
                }),
          if (user != null)
            ListTile(
              title: Text('Settings'),
              onTap: () {
                ModalRoute.of(context)?.settings.name == '/'
                    ? toggleVoice!()
                    : null;
                stopMetronome?.call();
                Navigator.pushNamed(
                  context,
                  '/settings',
                  arguments: user,
                );
              },
            ),
          ListTile(
            title: Text('About'),
            onTap: () {
              stopMetronome?.call();
              Navigator.pushNamed(context, '/about');
            },
          ),
          if (user != null)
            ListTile(
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/');
              },
            ),
        ],
      ),
    );
  }
}
