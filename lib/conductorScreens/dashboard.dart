import 'package:flutter/material.dart';
import '../customdrawer.dart';
import '../user.dart';
import '../database.dart';
import 'music_piece_details.dart'; // Import the new widget

class Dashboard extends StatefulWidget {
  final Conductor user;
  const Dashboard({Key? key, required this.user}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> musicPieces = [];

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
        title: const Text('Dashboard'),
        backgroundColor: Colors.black,
      ),
      drawer: CustomDrawer(user: widget.user),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'All Music',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: musicPieces.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: musicPieces.length,
                  itemBuilder: (context, index) {
                    final music = musicPieces[index];
                    final sections = music['sections'] as List;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 6,
                      color: const Color(0xFF1C1C1C),
                      child: InkWell(
                        onTap: () => {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MusicPieceDetails(piece: music, conductor: widget.user,musicId: music['_id']),
                            ),
                          ),
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                music['piece_name'],
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(
                                          label: Center(child: Text('Section', style: TextStyle(color: Colors.white)))
                                      ),
                                      DataColumn(
                                          label: Center(child: Text('Goal Tempo (BPM)', style: TextStyle(color: Colors.white)))
                                      ),
                                    ],
                                    rows: sections.map<DataRow>((section) {
                                      return DataRow(cells: [
                                        DataCell(
                                          Center(child: Text(section['name'], style: TextStyle(color: Colors.grey[400]))),
                                        ),
                                        DataCell(
                                          Center(child: Text('${section['bpm']}', style: TextStyle(color: Colors.grey[400]))),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    // Confirmation dialog
                                    bool confirm = await _showConfirmDialog(context);
                                    if (confirm) {
                                      bool success = await DatabaseHelper().deleteMusicPiece(music['_id']);
                                      if (success) {
                                        fetchMusicPieces(); // Refresh the list if deletion is successful
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to delete music piece')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this music piece?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false; // If user dismisses the dialog, assume they don't want to delete
  }
}