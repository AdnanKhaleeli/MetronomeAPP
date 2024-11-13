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
  Map<String, List<int?>> currentBpmMap = {};
  Map<String, double> averageBpmMap = {}; // Map to store average BPM for each piece

  // Fetch the current BPM and calculate the average BPM for each piece
  Future<void> fetchCurrentBPM(Piece piece) async {
    List<int?> currentBpmList = [];

    for (int sectionIndex = 0; sectionIndex < piece.sections.length; sectionIndex++) {
      final section = piece.sections[sectionIndex];
      int currentBpm = await DatabaseHelper().getCurrentUserBPMForSection(
        sectionIndex,
        widget.student!.userId,
        piece.pieceId,
      );

      currentBpmList.add(currentBpm);
    }

    // Calculate the average BPM for this piece
    double averageBpm = _calculateAverageBpm(currentBpmList);

    // Update state once all BPMs are fetched
    setState(() {
      currentBpmMap[piece.pieceId] = currentBpmList;
      averageBpmMap[piece.pieceId] = averageBpm;
    });
  }

  // Method to calculate average BPM, excluding "N/A" (null values)
  double _calculateAverageBpm(List<int?> bpms) {
    int sum = 0;
    int count = 0;

    for (var bpm in bpms) {
      if (bpm != null && bpm != -1) { // Exclude null and N/A (-1) values
        sum += bpm;
        count++;
      }
    }
    return count > 0 ? sum / count : 0; // Avoid division by zero
  }

  @override
  void initState() {
    super.initState();
    Future.wait(widget.pieces.map((piece) => fetchCurrentBPM(piece))).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments'),
        backgroundColor: Colors.black,
      ),
      drawer: CustomDrawer(user: widget.student),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your Assignments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  final averageBpm = averageBpmMap[piece.pieceId];

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
                            piece.pieceName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Average Tempo: ${averageBpm?.toStringAsFixed(2) ?? "N/A"} BPM',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.9,
                                  ),
                                  child: DataTable(
                                    columnSpacing: 10,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Section',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Goal BPM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Current BPM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: sections.map<DataRow>((section) {
                                      final currentBpm = pieceCurrentBpm != null
                                          ? pieceCurrentBpm[sections.indexOf(section)]
                                          : -1;
                                      final currentBpmText = currentBpm == -1 ? "N/A" : currentBpm.toString();

                                      Color? backgroundColorForCurrentBpm;
                                      if (currentBpm == -1 || currentBpm! >= section.goalBpm) {
                                        backgroundColorForCurrentBpm = Colors.green.shade700;
                                      } else if (currentBpm! < section.goalBpm) {
                                        backgroundColorForCurrentBpm = Colors.red.shade700;
                                      }

                                      return DataRow(cells: [
                                        DataCell(Text(
                                          section.sectionName,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        )),
                                        DataCell(Text(
                                          '${section.goalBpm}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        )),
                                        DataCell(Container(
                                          color: backgroundColorForCurrentBpm,
                                          child: Text(
                                            currentBpmText,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        )),
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
