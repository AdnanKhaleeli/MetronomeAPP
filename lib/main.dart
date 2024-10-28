import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'database.dart';
import 'user.dart';
import 'sign_in.dart';
import 'settings.dart';
import 'customdrawer.dart';
import 'conudctorScreens/music.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = DatabaseHelper();
  await db.init();
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
        '/addMusic': (context) => AddMusic(user: ModalRoute.of(context)!.settings.arguments as User)
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MetronomeApp extends StatefulWidget {
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
  final TextEditingController _controller = TextEditingController();
  int selectedSubdivisionIndex = 0;

  void startMetronome(int subdivisions) {
    playing = true;
    final double oneBeat = 60 / _bpm;
    final double tickDuration = (subdivisions == 1) ? oneBeat : oneBeat / subdivisions;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (tickDuration * 1000).toInt()), (timer) async {
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_bpm > 40) {
                        _bpm -= 1;
                        _controller.text = _bpm.toInt().toString();
                        stopMetronome();
                        startMetronome(currentSubdivisions);
                      }
                    });
                  },
                  child: Text("-"),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'BPM',
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      int? bpmInput = int.tryParse(value);
                      if (bpmInput != null && bpmInput >= 40 && bpmInput <= 200) {
                        setState(() {
                          _bpm = bpmInput.toDouble();
                          stopMetronome();
                          startMetronome(currentSubdivisions);
                        });
                      }
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_bpm < 199) {
                        _bpm += 1;
                        _controller.text = _bpm.toInt().toString();
                        stopMetronome();
                        startMetronome(currentSubdivisions);
                      }
                    });
                  },
                  child: Text("+"),
                ),
              ],
            ),
            Slider(
              min: 40,
              max: 200,
              value: _bpm,
              onChanged: (newBPM) {
                setState(() {
                  _bpm = newBPM;
                  _controller.text = newBPM.toInt().toString();
                  stopMetronome();
                  startMetronome(currentSubdivisions);
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    int? bpmInput = int.tryParse(_controller.text);
                    if (bpmInput != null && bpmInput >= 40 && bpmInput <= 200) {
                      setState(() {
                        _bpm = bpmInput.toDouble();
                        _controller.clear();
                      });
                    }
                  },
                  child: Text("Enter"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    stopMetronome();
                    startMetronome(currentSubdivisions);
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
                      selectedSubdivisionIndex = 0;
                      currentSubdivisions = 1;
                      stopMetronome();
                      startMetronome(currentSubdivisions);
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
                      selectedSubdivisionIndex = 1;
                      currentSubdivisions = 2;
                      stopMetronome();
                      startMetronome(currentSubdivisions);
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
                      selectedSubdivisionIndex = 2;
                      currentSubdivisions = 3;
                      stopMetronome();
                      startMetronome(currentSubdivisions);
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
                      selectedSubdivisionIndex = 3;
                      currentSubdivisions = 4;
                      stopMetronome();
                      startMetronome(currentSubdivisions);
                    });
                  },
                  child: Text('Sixteenth'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
