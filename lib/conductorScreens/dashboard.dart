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
        backgroundColor: Colors.black, // Dark AppBar
      ),
      drawer: CustomDrawer(user: widget.user),
      body: Container(
        color: Colors.black, // Keep the body black
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'All Music',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                ),
              ),
            ),
            Expanded(
              child: musicPieces.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      // Enable scrolling
                      child: ListView.builder(
                        physics:
                            NeverScrollableScrollPhysics(), // Disable inner scroll
                        shrinkWrap:
                            true, // Allow ListView to take only the space it needs
                        itemCount: musicPieces.length,
                        itemBuilder: (context, index) {
                          final music = musicPieces[index];
                          final sections = music['sections'] as List;

                          return Card(
                            margin: EdgeInsets.all(8.0),
                            elevation: 6, // Card elevation
                            color: Color(
                                0xFF1C1C1C), // Slightly lighter card color
                            child: InkWell(
                              onTap: () => {}, // Handle tap
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title of the music piece
                                    Text(
                                      music['piece_name'],
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18), // Title styling
                                    ),
                                    SizedBox(
                                        height:
                                            8), // Space between title and sections
                                    // Center the DataTable
                                    Center(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(
                                                label: Center(
                                                    child: Text('Section',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .white)))),
                                            DataColumn(
                                                label: Center(
                                                    child: Text(
                                                        'Goal Tempo (BPM)',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .white)))),
                                          ],
                                          rows:
                                              sections.map<DataRow>((section) {
                                            return DataRow(cells: [
                                              DataCell(
                                                Center(
                                                  child: Text(
                                                    section['name'],
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[400]),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Center(
                                                  child: Text(
                                                    '${section['bpm']}',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[400]),
                                                  ),
                                                ),
                                              ),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    // Positioned delete icon (aligned to the right)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors
                                                .red), // Red icon for delete
                                        onPressed: () async {
                                          // Call delete function
                                          bool success = await DatabaseHelper()
                                              .deleteMusicPiece(music['_id']);
                                          if (success) {
                                            // Refresh the list after deletion
                                            fetchMusicPieces();
                                          } else {
                                            // Optionally show an error message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Failed to delete music piece')),
                                            );
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
}
