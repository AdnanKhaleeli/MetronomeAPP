import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../user.dart';
import '../customdrawer.dart';

class ViewStudents extends StatelessWidget {
  ObjectId songId;
  Conductor conductor;
  ViewStudents({super.key, required this.songId, required this.conductor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students for Song'),
      ),
      drawer: CustomDrawer(user: conductor),
    );
  }
}
