import 'package:flutter/material.dart';
import '../customdrawer.dart';
import '../user.dart';
import '../database.dart';

class Dashboard extends StatefulWidget {
  final Conductor user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> musicPieces = []; // To hold music pieces

  @override
  void initState() {
    super.initState();
    fetchMusicPieces();
  }

  Future<void> fetchMusicPieces() async {
    var db = DatabaseHelper();
    musicPieces = await db.getAllMusicPieces();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: CustomDrawer(user: widget.user),
      body: musicPieces.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: musicPieces.length,
              itemBuilder: (context, index) {
                final music = musicPieces[index];
                final sections = music['sections'] as List;

                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(music['piece_name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections.map((section) {
                        return Text(
                          '${section['name']} - Goal Tempo: ${section['bpm']} BPM',
                          style: TextStyle(fontSize: 14),
                        );
                      }).toList(),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        // Call delete function
                        bool success = await DatabaseHelper().deleteMusicPiece(music['_id']);
                        if (success) {
                          // Refresh the list after deletion
                          fetchMusicPieces();
                        } else {
                          // Optionally show an error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete music piece')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
