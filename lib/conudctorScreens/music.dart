import 'package:flutter/material.dart';
import '../user.dart';
import '../customdrawer.dart';

class AddMusic extends StatefulWidget {
  Conductor user;
  AddMusic({super.key, required this.user});

  @override
  State<AddMusic> createState() => AddMusicState();
}

class AddMusicState extends State<AddMusic> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Add Music Here'),
        centerTitle: true,

        ),

        drawer: CustomDrawer(
          isOnSignInPage: false,
          user: widget.user,
        ),
        body: Center(
          child: Column(),
        ));
  }
}
