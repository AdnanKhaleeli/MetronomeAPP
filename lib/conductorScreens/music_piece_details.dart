import 'dart:ffi';

import 'package:metronome/conductorScreens/selectStudentsPage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';
import 'package:flutter/material.dart';
import '../database.dart';
import 'section_details_page.dart';
import '../user.dart';
import '../customdrawer.dart';

class MusicPieceDetails extends StatefulWidget {
  final Map<String, dynamic> piece;
  final Conductor conductor;
  mongo.ObjectId musicId;

  MusicPieceDetails(
      {Key? key,
      required this.piece,
      required this.conductor,
      required this.musicId})
      : super(key: key);

  @override
  _MusicPieceDetailsState createState() => _MusicPieceDetailsState();
}

class _MusicPieceDetailsState extends State<MusicPieceDetails> {
  late Future<Map<String, double?>> _averageTempoFuture;
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _averageTempoFuture = _fetchStudentsAndCalculateAverageTempo();
    print(widget.piece);
    print("Type of sections: ${widget.piece['sections'].runtimeType}");
  }

  Future<Map<String, double?>> _fetchStudentsAndCalculateAverageTempo() async {
    var db = DatabaseHelper();
    _students = await db.getAllStudents();

    Map<String, List<int>> sectionTempoSums = {};
    Map<String, int> sectionCount = {};

    for (var student in _students) {
      var studentID = student['_id'];
      var musicID = widget.piece['_id'].oid;

      if (student['assigned_music'] == null) {
        continue;
      }

      var musicIDStr = musicID.toString();
      if (!student['assigned_music'].containsKey(musicID)) {
        continue;
      }

      var studentTempos =
          student['assigned_music'][musicIDStr] as List<dynamic>;

      for (int sectionIndex = 0;
          sectionIndex < studentTempos.length;
          sectionIndex++) {
        var tempo = studentTempos[sectionIndex];

        if (tempo == "N/A" || tempo == 0) {
          continue;
        }

        try {
          int tempoInt = tempo.toInt();

          String sectionId = 'section_${sectionIndex + 1}';

          sectionTempoSums.update(sectionId, (list) => [...list, tempoInt],
              ifAbsent: () => [tempoInt]);
          sectionCount.update(sectionId, (count) => count + 1,
              ifAbsent: () => 1);
        } catch (e) {
          print(
              "Error parsing tempo for student $studentID, section $sectionIndex: $e");
        }
      }
    }

    return sectionTempoSums.map((key, value) {
      if (value.isEmpty) {
        return MapEntry(key, null);
      } else {
        return MapEntry(
            key, value.reduce((a, b) => a + b) / sectionCount[key]!);
      }
    });
  }

  List<Map<String, dynamic>> _getStudentTemposForSection(int sectionIndex) {
    List<Map<String, dynamic>> sectionStudentTempos = [];

    for (var student in _students) {
      var musicID = widget.piece['_id'].oid.toString();

      if (student['assigned_music'] == null ||
          !student['assigned_music'].containsKey(musicID)) {
        continue;
      }

      var studentTempos = student['assigned_music'][musicID] as List<dynamic>;
      if (sectionIndex < studentTempos.length) {
        var tempo = studentTempos[sectionIndex];
        if (tempo != "N/A" && tempo != 0) {
          sectionStudentTempos.add({
            'name': student['profilename'],
            'tempo': tempo,
          });
        }
      }
    }

    return sectionStudentTempos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.piece['piece_name']),
        backgroundColor: Colors.black,
      ),
      drawer: CustomDrawer(user: widget.conductor),
      body: Container(
        color: Colors.black,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Details for ${widget.piece['piece_name']}',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(Icons.person, color: Colors.white),
                      tooltip: 'Add Student',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectStudentsPage(
                              pieceName: widget.piece['piece_name'],
                              sectionNames: widget.piece['sections']
                                  .map<String>((section) => section['name'].toString())
                                  .toList(),
                              sectionBpms: widget.piece['sections']
                                  .map<int>((section) => section['bpm'] as int)
                                  .toList(),
                              musicId: widget.musicId,
                              user: widget.conductor,
                              numSections: widget.piece['sections'].length,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              FutureBuilder<Map<String, double?>>(
                future: _averageTempoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.white));
                  }

                  var averageTempos = snapshot.data ?? {};
                  return Column(
                    children: (widget.piece['sections'] as List)
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    List<Map<String, dynamic>> studentTempos =
                                        _getStudentTemposForSection(entry.key);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SectionDetailsPage(
                                          average: averageTempos[
                                              'section_${entry.key + 1}'],
                                          goalTempo: entry.value['bpm'],
                                          songName: widget.piece['piece_name'],
                                          sectionName: entry.value['name'],
                                          studentTempos: studentTempos,
                                          conductor: widget.conductor,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 1),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        entry.value['name'],
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Goal Tempo: ${entry.value['bpm']}',
                                              style: TextStyle(
                                                  color: Colors.grey[400]),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Average Tempo: ${averageTempos['section_${entry.key + 1}']?.toStringAsFixed(2) ?? 'N/A'}',
                                              style: TextStyle(
                                                  color: Colors.grey[400]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
