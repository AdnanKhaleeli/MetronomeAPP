import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database.dart';
import 'user.dart';

import 'sign_in.dart';
import 'settings.dart';
import 'customdrawer.dart';

// App
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = DatabaseHelper();
  await db.init();

  bool result = await db.insertStudent(
      username: 'Adnan', pwd: '2782738', profilename: 'profile_Name');
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // Text color for TextButton
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Background color for ElevatedButton
            foregroundColor: Colors.white, // Text color for ElevatedButton
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MetronomeApp extends StatefulWidget {
  @override

   User? user;

   MetronomeApp({Key? key, this.user}) : super(key: key);

  _MetronomeAppState createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  
  double _bpm = 60;
  final player = AudioPlayer();
  Timer? _timer;
  bool playing = false;
  int currentSubdivisions = 1;
  int tickCount = 0;

  // Track the currently selected button index
  int selectedSubdivisionIndex = 0;


  // Unified method to start the metronome
  void startMetronome(int subdivisions) {
    playing = true;
    final double oneBeat = 60 / _bpm;
    final double tickDuration =
        (subdivisions == 1) ? oneBeat : oneBeat / subdivisions;

    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(
        Duration(milliseconds: (tickDuration * 1000).toInt()), (timer) async {
      tickCount++;
      await player.setSource(AssetSource('tick_sound_156.wav'));

      if (subdivisions == 1 || tickCount % subdivisions == 0) {
        await player.setVolume(1.0);
      } else {
        await player.setVolume(0.2);
      }

      await player.resume();
    });
  }

  void stopMetronome() {
    playing = false;
    _timer?.cancel();
    player.stop();
    tickCount = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    player.dispose();
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
      drawer: CustomDrawer(
        stopMetronome: stopMetronome,
        user: widget.user,
      ),
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
                      stopMetronome();
                      startMetronome(
                          currentSubdivisions); // Restart with new BPM
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
                    stopMetronome();
                    startMetronome(currentSubdivisions); // Restart with new BPM
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bpm < 199) {
                      _bpm += 1;
                      stopMetronome();
                      startMetronome(
                          currentSubdivisions); // Restart with new BPM
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
                  stopMetronome();
                  startMetronome(
                      currentSubdivisions); // Start with current subdivisions
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
                style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSubdivisionIndex == 0
                        ? Colors.red
                        : Colors.white,
                    foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    selectedSubdivisionIndex = 0; // Whole note
                    currentSubdivisions = 1;
                    stopMetronome();
                    startMetronome(
                        currentSubdivisions); // Restart with whole notes
                  });
                },
                child: Text('Whole'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSubdivisionIndex == 1
                        ? Colors.red
                        : Colors.white,
                    foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    selectedSubdivisionIndex = 1; // Eighth notes
                    currentSubdivisions = 2;
                    stopMetronome();
                    startMetronome(
                        currentSubdivisions); // Restart with eighth notes
                  });
                },
                child: Text('Eighth'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSubdivisionIndex == 2
                        ? Colors.red
                        : Colors.white,
                    foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    selectedSubdivisionIndex = 2; // Triplets
                    currentSubdivisions = 3;
                    stopMetronome();
                    startMetronome(
                        currentSubdivisions); // Restart with triplets
                  });
                },
                child: Text('Triplet'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSubdivisionIndex == 3
                        ? Colors.red
                        : Colors.white,
                    foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    selectedSubdivisionIndex = 3; // Sixteenth notes
                    currentSubdivisions = 4;
                    stopMetronome();
                    startMetronome(
                        currentSubdivisions); // Restart with sixteenth notes
                  });
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
