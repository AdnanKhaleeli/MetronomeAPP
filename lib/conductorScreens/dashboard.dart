import 'package:flutter/material.dart';
import '../customdrawer.dart';
import '../user.dart';

class Dashboard extends StatefulWidget {
  final Conductor user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(
        title : Text('Dashboard'),
      ),
       drawer: CustomDrawer(user: widget.user)
    );
  }
}