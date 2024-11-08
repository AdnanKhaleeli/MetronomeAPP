import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'database.dart';
import 'user.dart';
import 'sign_in.dart';
import 'settings.dart';
import 'customdrawer.dart';
import 'conductorScreens/music.dart';
import 'conductorScreens/dashboard.dart';
import 'music.dart';

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
        '/': (context) => MetronomeApp(
            user: ModalRoute.of(context)?.settings.arguments as User?),
        '/sign_in': (context) => SignIn(),
        '/addMusic': (context) => AddMusic(
            user: ModalRoute.of(context)!.settings.arguments as Conductor),
        '/dashboard_conductor': (context) => Dashboard(
            user: ModalRoute.of(context)?.settings.arguments as Conductor)
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
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        scaffoldBackgroundColor: Color(0xFF121212), // Dark background
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MetronomeApp extends StatefulWidget {
  final User? user;

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
  List<Piece> pieces = [];
  Piece? selectedPiece;
  Section? selectedSection;
  int? goalBpm;
  PageController _pageController = PageController();
  int _currentSectionIndex = 0;
  dynamic? _currentSectionBpm = 0;

  @override
  void initState() {
    super.initState();
    if (widget.user is Student) {
      fetchPieces();
    }
  }

  void fetchPieces() async {
    if (widget.user != null) {
      pieces = await DatabaseHelper().getPiecesForUser(widget.user!);
    } else {
      pieces = [];
    }
    setState(() {});
  }

  void fetchSections(Piece piece) async {
    setState(() {
      selectedPiece = piece;
      selectedSection = null;
      _currentSectionIndex = 0;
    });
    if (selectedPiece != null && selectedPiece!.sections.isNotEmpty) {
      selectedSection = selectedPiece!.sections[0];
      fetchBpmForSection(selectedSection!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(0);
      });
    }
  }

  void fetchBpmForSection(Section section) async {
    final bpm = await DatabaseHelper().getCurrentUserBPMForSection(
      _currentSectionIndex,
      widget.user!.userId,
      selectedPiece!.pieceId,
    );
    setState(() {
      goalBpm = section.goalBpm;
      _currentSectionBpm = bpm;
    });
  }

  void startMetronome(int subdivisions) {
    if (playing) return; // Avoid starting if already playing

    final double oneBeat = 60 / _bpm;
    final double tickDuration =
        (subdivisions == 1) ? oneBeat : oneBeat / subdivisions;

    _timer?.cancel();
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

    setState(() {
      playing = true;
    });
  }

  void stopMetronome() {
    if (!playing) return; // Avoid stopping if not playing

    _timer?.cancel();
    player.stop();
    tickCount = 0;

    setState(() {
      playing = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    player.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome App'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
      ),
      drawer: CustomDrawer(
        stopMetronome: stopMetronome,
        user: widget.user,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top centered section with Music Piece and Section
            if (widget.user is Student)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: DropdownButton<Piece>(
                  value: selectedPiece,
                  hint: Text('Select a Piece'),
                  items: pieces.map((Piece piece) {
                    return DropdownMenuItem<Piece>(
                      value: piece,
                      child: Text(piece.pieceName),
                    );
                  }).toList(),
                  onChanged: (Piece? newValue) {
                    setState(() {
                      selectedPiece = newValue;
                      fetchSections(newValue!);
                    });
                  },
                  style: TextStyle(color: Colors.white),
                  dropdownColor: Colors.teal[800],
                ),
              ),
            if (selectedPiece != null && selectedPiece!.sections.isNotEmpty)
              Container(
                height: 50,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: selectedPiece!.sections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSectionIndex = index;
                      selectedSection = selectedPiece!.sections[index];
                      fetchBpmForSection(selectedSection!);
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        selectedPiece!.sections[index].sectionName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (goalBpm != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Goal BPM: $goalBpm',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            // BPM Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'BPM',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        int? bpmInput = int.tryParse(value);
                        if (bpmInput != null &&
                            bpmInput >= 40 &&
                            bpmInput <= 200) {
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
            ),
            Slider(
              min: 40,
              max: 200,
              value: _bpm,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white.withOpacity(0.5),
              onChanged: (newBPM) {
                setState(() {
                  _bpm = newBPM;
                  _controller.text = newBPM.toInt().toString();
                  stopMetronome();
                  startMetronome(currentSubdivisions);
                });
              },
            ),
            // Metronome Controls (Play/Pause, Subdivisions)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (playing) {
                      stopMetronome();
                    } else {
                      startMetronome(currentSubdivisions);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: selectedSubdivisionIndex == 0
                          ? Colors.teal[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white),
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
                          ? Colors.teal[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white),
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
                          ? Colors.teal[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white),
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
                          ? Colors.teal[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white),
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
