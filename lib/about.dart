import 'package:flutter/material.dart';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Screen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Text
            Text(
              'MetronomeAPP!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This app is designed to help your band keep track of beats and assigned pieces with this customizable metronome. Here\'s an overview of how it works and its features.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Additional Information
            Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '- Adjustable tempo and subdivisions.\n'
                  '- Visual and auditory beat indicators.\n'
                  '- Voice control for start, stop, and settings to change beat and subdivisions.\n'
                  ' * "Start": Start the metronome.\n'
                  ' * "Stop": Stop the metronome.\n'
                  ' * "Fast x": Increase tempo by x.\n'
                  ' * "Slow x": Decrease temp by x.\n'
                  ' * "Increase": Increase tempo by set value. (Adjustable in settings)\n'
                  ' * "Decrease": Decrease tempo by set value. (Adjustable in settings)\n'
                  ' * "Division": Change the subdivision.\n',
              style: TextStyle(fontSize: 16),
            ),

            // Display an Image
            Center(
              child: Image.asset(
                'assets/images/progress_bar_screenshot.png', // Replace with your image path
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),

            // Explanation of the Image
            Text(
              'Above is an example of the Metronome\'s personal progress tracker. It features an easy to follow BPM circle, acting as a bar to show the current BPM and the BPM the student needs to reach.\n '
                  'As the student changes the current BPM, the yellow portion rises.\n'
                  'The remaining red bar represents the gap between the current BPM and the goal BPM which needs to be reached.\n'
                  'When the student confirms and submits their BPM, the yellow bar changes green.\n'
                  'Student users confirming their current BPM will let the conductor see which BPM the student is currently comfortable playing the piece at.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}