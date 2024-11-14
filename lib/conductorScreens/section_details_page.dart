import 'package:flutter/material.dart';

class SectionDetailsPage extends StatelessWidget {
  final String? sectionName;
  final String songName;
  final int goalTempo;
  final double? average;
  final List<Map<String, dynamic>> studentTempos;

  const SectionDetailsPage({
    Key? key,
    required this.sectionName,
    required this.songName,
    required this.goalTempo,
    required this.studentTempos,
    required this.average,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(studentTempos);

    // Set the color based on the average tempo compared to the goal tempo
    Color averageTempoColor;
    if (average != null) {
      if (average! >= goalTempo) {
        averageTempoColor = Colors.green; // Average tempo greater than or equal to goal
      } else if (average! >= goalTempo - 10) {
        averageTempoColor = Colors.yellow; // Average tempo within 10 of the goal
      } else {
        averageTempoColor = Colors.red; // Average tempo below goal by more than 10
      }
    } else {
      averageTempoColor = Colors.white; // Default color if average is null
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sectionName ?? 'No Section Name'),
        backgroundColor: Colors.black,
        elevation: 4.0,
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: studentTempos.length + 1, // Add 1 for the header
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header section with song name, section name, goal tempo, and average tempo
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      sectionName ?? 'No Section Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    _buildGoalAndAverageTempo(averageTempoColor),
                  ],
                ),
              );
            } else {
              // Regular ListTile for student tempos
              final student = studentTempos[index - 1];
              int studentTempo = student['tempo'] != null ? student['tempo'].toInt() : 0;

              // Set the color based on the student's tempo compared to the goal tempo
              Color tempoColor;
              if (studentTempo >= goalTempo) {
                tempoColor = Colors.green;
              } else if (studentTempo >= goalTempo - 10) {
                tempoColor = Colors.yellow;
              } else {
                tempoColor = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Card(
                  color: Colors.black54,
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          student['name'] ?? 'Unknown',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tempo: ${studentTempo.toString()}',
                          style: TextStyle(color: tempoColor),
                        ),
                      ],
                    ),
                    leading: Icon(Icons.person, color: Colors.white),
                    trailing: Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Builds the Goal and Average Tempo UI
  Widget _buildGoalAndAverageTempo(Color averageTempoColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goal Tempo:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Text(
              '$goalTempo BPM',
              style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Average Tempo:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Text(
              average != null ? '${average!.toStringAsFixed(2)} BPM' : 'N/A',
              style: TextStyle(
                color: averageTempoColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.0),
      ],
    );
  }
}
