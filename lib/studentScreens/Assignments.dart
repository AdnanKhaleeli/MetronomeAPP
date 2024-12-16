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

    setState(() {
      currentBpmMap[piece.pieceId] = currentBpmList;
    });
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
                  ? Center(
                      child: Text(
                        'No assignments in pieces', // Show message when no pieces
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
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
                                  piece.pieceName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                                            final currentBpm =
                                                pieceCurrentBpm != null
                                                    ? pieceCurrentBpm[sections
                                                        .indexOf(section)]
                                                    : -1;
                                            final currentBpmText =
                                                currentBpm == -1
                                                    ? "N/A"
                                                    : currentBpm.toString();

                                            Color? backgroundColorForCurrentBpm;
                                            if (currentBpm == -1 ||
                                                currentBpm! >=
                                                    section.goalBpm) {
                                              backgroundColorForCurrentBpm =
                                                  Colors.green.shade700;
                                            } else if (currentBpm! <
                                                section.goalBpm) {
                                              if (section.goalBpm -
                                                      currentBpm <=
                                                  10) {
                                                backgroundColorForCurrentBpm =
                                                    Colors.yellow.shade800;
                                              } else {
                                                backgroundColorForCurrentBpm =
                                                    Colors.red.shade700;
                                              }
                                            }

                                            return DataRow(cells: [
                                              DataCell(
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    section.sectionName,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  color:
                                                      backgroundColorForCurrentBpm,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 6.0,
                                                          horizontal: 8.0),
                                                      child: Text(
                                                        currentBpmText,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
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
