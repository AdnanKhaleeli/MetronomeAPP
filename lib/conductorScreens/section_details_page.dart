import 'package:flutter/material.dart';

class SectionDetailsPage extends StatelessWidget {
  final String? sectionName; // Make it nullable
  final String songName; // Add a song name parameter
  final int goalTempo; // Add a goal tempo parameter
  final double? average; // Add the average tempo parameter
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
        title: Text(sectionName ?? 'No Section Name'), // Provide default text
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: studentTempos.length + 1, // Add 1 for the header
          itemBuilder: (context, index) {
            if (index == 0) {
              // Display the song name, section name, goal tempo, and average tempo
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Adjust font size for the song name
                      ),
                    ),
                    Text(
                      sectionName ?? 'No Section Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20, // Adjust font size for the section name
                      ),
                    ),
                    Text(
                      'Goal Tempo: ${goalTempo.toString()}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 28, // Larger font for goal tempo
                        fontWeight: FontWeight.bold, // Bold for emphasis
                      ),
                    ),
                    // Display the average tempo with color logic
                    Text(
                      'Average Tempo: ${average?.toStringAsFixed(2) ?? 'N/A'}', // Display the average with 2 decimal places
                      style: TextStyle(
                        color: averageTempoColor, // Use the calculated color for average tempo
                        fontSize: 20, // Adjust font size for the average tempo
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Regular ListTile for student tempos
              final student = studentTempos[index - 1]; // Adjust for header
              double studentTempo = student['tempo'] != null ? student['tempo'] : 0;

              // Set the color based on the student's tempo compared to the goal tempo
              Color tempoColor;
              if (studentTempo >= goalTempo) {
                tempoColor = Colors.green; // Tempo greater than or equal to goal
              } else if (studentTempo >= goalTempo - 10) {
                tempoColor = Colors.yellow; // Tempo within 10 of the goal
              } else {
                tempoColor = Colors.red; // Tempo below goal by more than 10
              }

              return ListTile(
                title: Text(student['name'] ?? 'Unknown', style: TextStyle(color: Colors.white)), // Default name if null
                subtitle: Text(
                  'Tempo: ${studentTempo.toString()}',
                  style: TextStyle(color: tempoColor), // Change text color dynamically
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
