import 'package:flutter/material.dart';
import '../customdrawer.dart';
import '../user.dart';
import '../music.dart';
import '../database.dart';

class Assignments extends StatefulWidget {
  final Student? student;
  final List<Piece> pieces;

  Assignments({super.key, this.student, required this.pieces});

  @override
  State<Assignments> createState() => _AssignmentsState();
}

class _AssignmentsState extends State<Assignments> {
  // Map to hold current BPM for each piece and section
  Map<String, List<int?>> currentBpmMap = {};

  // Fetch the current BPM for each section of a piece
  Future<void> fetchCurrentBPM(Piece piece) async {
    List<int?> currentBpmList = [];

    for (int sectionIndex = 0; sectionIndex < piece.sections.length; sectionIndex++) {
      final section = piece.sections[sectionIndex];

      // Fetch current BPM for this section using the student's ID and the piece's ID
      int currentBpm = await DatabaseHelper().getCurrentUserBPMForSection(
        sectionIndex,
        widget.student!.userId, // Assuming studentId is available in the Student object
        piece.pieceId, // Assuming pieceId is available in the Piece object
      );

      currentBpmList.add(currentBpm);
    }

    // Update state once all BPMs are fetched for the current piece
    setState(() {
      currentBpmMap[piece.pieceId] = currentBpmList;
    });
  }

  @override
  void initState() {
    super.initState();
    // Fetch the current BPM for each piece asynchronously
    Future.wait(widget.pieces.map((piece) => fetchCurrentBPM(piece))).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments'),
        backgroundColor: Colors.black, // Dark app bar to match the theme
      ),
      drawer: CustomDrawer(user: widget.student),
      body: Container(
        color: Colors.black, // Keep the body black
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your Assignments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                ),
              ),
            ),
            Expanded(
              child: widget.pieces.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: widget.pieces.length,
                      itemBuilder: (context, index) {
                        final piece = widget.pieces[index];
                        final sections = piece.sections;
                        final pieceCurrentBpm = currentBpmMap[piece.pieceId];

                        return Card(
                          margin: EdgeInsets.all(8.0),
                          elevation: 6,
                          color: Color(0xFF1C1C1C),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  piece.pieceName, // Name of the piece
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Use a LayoutBuilder to allow responsive sizing
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Ensure the DataTable is centered and responsive
                                    return Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: constraints.maxWidth * 0.9, // Limit width to 90% of screen width
                                        ),
                                        child: DataTable(
                                          columnSpacing: 10, // Adjust spacing between columns
                                          columns: [
                                            DataColumn(
                                              label: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Section',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Goal BPM',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Current BPM',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: sections.map<DataRow>((section) {
                                            final currentBpm = pieceCurrentBpm != null
                                                ? pieceCurrentBpm[sections.indexOf(section)]
                                                : -1;
                                            final currentBpmText = currentBpm == -1 ? "N/A" : currentBpm.toString();

                                            // Set background color for cells based on comparison
                                            Color? backgroundColorForCurrentBpm;
                                            if (currentBpm == -1 || currentBpm! >= section.goalBpm) {
                                              backgroundColorForCurrentBpm = Colors.green.shade700;
                                            } else if (currentBpm! < section.goalBpm) {
                                              backgroundColorForCurrentBpm = Colors.red.shade700;
                                            }

                                            return DataRow(cells: [
                                              DataCell(
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    section.sectionName,
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${section.goalBpm}',
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  color: backgroundColorForCurrentBpm,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      currentBpmText,
                                                      style: TextStyle(
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
