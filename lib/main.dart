import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database.dart';

import 'sign_in.dart';
import 'settings.dart';

// App
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = DatabaseHelper();
  await db.init();

  bool result = await db.insertStudent(name: 'Adnan', pwd: '2782738');
  print(result);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metronome App',
      initialRoute: '/',
      routes: {
        '/': (context) => MetronomeApp(),
        '/sign_in': (context) => SignIn(),
      },
    );
  }
}

class MetronomeApp extends StatefulWidget {
  @override
  _MetronomeAppState createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  double _bpm = 60;
  final player = AudioPlayer();
  Timer? _timer; // Declare a Timer variable
  bool playing = false; // Change default to false
  int currentSubdivisions = 1; // Track current subdivisions
  int tickCount = 0; // Track the count of ticks

  // Method to start the metronome
  void startMetronome() {
    playing = true;
    final double oneBeat = 60 / _bpm; // Duration of one beat in seconds

    _timer = Timer.periodic(Duration(milliseconds: (oneBeat * 1000).toInt()), (timer) async {
      tickCount++;
      await player.setSource(AssetSource('tick_sound_156.wav'));
      await player.setVolume(1.0); // Full volume for main beat
      await player.resume();
    });
  }

  void startMetronomeWithSubdivisions(int subdivisions) {
    playing = true;
    final double oneBeat = 60 / _bpm; // Duration of one beat in seconds
    final double tickDuration = oneBeat / subdivisions; // Duration of each tick

    _timer = Timer.periodic(Duration(milliseconds: (tickDuration * 1000).toInt()), (timer) async {
      tickCount++;
      await player.setSource(AssetSource('tick_sound_156.wav'));
      
      // Set volume based on whether it's a main beat or subdivision
      if (tickCount % subdivisions == 0) {
        await player.setVolume(1.0); // Full volume for main beat
      } else {
        await player.setVolume(0.2); // Lower volume for subdivisions
      }
      
      await player.resume();
    });
  }

  // Method to stop the metronome
  void stopMetronome() {
    playing = false;
    _timer?.cancel(); // Cancel the timer
    player.stop(); // Stop the audio player
    tickCount = 0; // Reset tick count
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing
    player.dispose(); // Dispose the audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome App'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      drawer: CustomDrawer(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('BPM: ${_bpm.toInt()}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bpm > 40) {
                      _bpm -= 1;
                      stopMetronome(); // Stop the metronome
                      startMetronome(); // Restart with new BPM
                    }
                  });
                },
                child: Text("-"),
              ),
              Slider(
                min: 40,
                max: 200,
                value: _bpm,
                onChanged: (newBPM) {
                  setState(() {
                    _bpm = newBPM;
                    stopMetronome(); // Stop the metronome
                    startMetronome(); // Restart with new BPM
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bpm < 199) {
                      _bpm += 1;
                      stopMetronome(); // Stop the metronome
                      startMetronome(); // Restart with new BPM
                    }
                  });
                },
                child: Text("+"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  stopMetronome(); // Stop any ongoing metronome
                  startMetronome(); // Start the metronome with regular beats
                },
                child: Text('Start'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: stopMetronome,
                child: Text('Stop'),
              ),
            ],
          ),
          // Subdivision buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  stopMetronome(); // Stop the metronome
                  currentSubdivisions = 1; // Set to whole note
                  startMetronome(); // Start the metronome with regular beats
                },
                child: Text('Whole'),
              ),
              ElevatedButton(
                onPressed: () {
                  stopMetronome(); // Stop the metronome
                  currentSubdivisions = 2; // Set to eighth notes
                  startMetronomeWithSubdivisions(currentSubdivisions);
                },
                child: Text('Eighth'),
              ),
              ElevatedButton(
                onPressed: () {
                  stopMetronome(); // Stop the metronome
                  currentSubdivisions = 3; // Set to triplets
                  startMetronomeWithSubdivisions(currentSubdivisions);
                },
                child: Text('Triplet'),
              ),
              ElevatedButton(
                onPressed: () {
                  stopMetronome(); // Stop the metronome
                  currentSubdivisions = 4; // Set to sixteenth notes
                  startMetronomeWithSubdivisions(currentSubdivisions);
                },
                child: Text('Sixteenth'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Drawer
class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          ListTile(
            title: const Text('Sign up / Log in Here'),
            onTap: () {
              Navigator.pushNamed(context, '/sign_in');
            },
          ),
        ],
      ),
    );
  }
}
