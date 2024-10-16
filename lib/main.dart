import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database.dart';

import 'sign_in.dart';
import 'settings.dart';

// App
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure initialization of Flutter bindings
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
        '/sign_in': (context) => SignIn(), // Define the sign-in route
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
  bool playing = false; // Change default to false

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
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bpm < 199) {
                      _bpm += 1;
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
                onPressed: () async {
                  playing = true;
                  while (playing) {
                    double oneBeat = 60 / _bpm;
                    double waitTime = oneBeat - 0.156;

                    await player.setSource(AssetSource('tick_sound_156.wav'));
                    await player.setVolume(1.0);
                    await player.resume();
                    await Future.delayed(Duration(milliseconds: 156));
                    await Future.delayed(Duration(milliseconds: (waitTime * 1000).toInt()));
                  }
                },
                child: Text('Start'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  playing = false;
                  player.stop();
                },
                child: Text('Stop'),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () {},
              child: Text('Beat 1'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Beat 2'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Beat 3'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Beat 4'),
            )
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () {},
              child: Text('♩', style: TextStyle(fontSize: 50.0)),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('♪', style: TextStyle(fontSize: 50.0)),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('♫', style: TextStyle(fontSize: 50.0)),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('♬', style: TextStyle(fontSize: 50.0)),
            )
          ]),
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
