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
import 'dart:math';

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
        '/': (context) => MetronomeApp(user: ModalRoute.of(context)?.settings.arguments as User?),
        '/sign_in': (context) => SignIn(),
        '/addMusic': (context) => AddMusic(user: ModalRoute.of(context)!.settings.arguments as Conductor),
        '/dashboard_conductor': (context) => Dashboard(user: ModalRoute.of(context)?.settings.arguments as Conductor),
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.white)),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
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

    setState(() {
      playing = true;
    });
  }

  // Stops the metronome
  void stopMetronome() {
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

  void handleSwipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx > 0) {
      // Swipe to the left, go to the previous section
      if (_currentSectionIndex > 0) {
        _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
        setState(() {
          _currentSectionIndex--;
          selectedSection = selectedPiece!.sections[_currentSectionIndex];
          fetchBpmForSection(selectedSection!);
        });
      }
    } else if (details.velocity.pixelsPerSecond.dx < 0) {
      // Swipe to the right, go to the next section
      if (_currentSectionIndex < selectedPiece!.sections.length - 1) {
        _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
        setState(() {
          _currentSectionIndex++;
          selectedSection = selectedPiece!.sections[_currentSectionIndex];
          fetchBpmForSection(selectedSection!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome App'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      drawer: CustomDrawer(stopMetronome: stopMetronome, user: widget.user),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        onHorizontalDragEnd: handleSwipe,
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (goalBpm != null)
              CircularBPMIndicator(
                currentBpm: _bpm,
                goalBpm: goalBpm!.toDouble(),
                savedBpm: _currentSectionBpm?.toDouble(),
              ),
            if (widget.user is Student)
              DropdownButton<Piece>(
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            if (goalBpm != null)
              Text(
                'Goal BPM: $goalBpm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            if (widget.user is Student && selectedPiece != null)
              Container(
                margin: EdgeInsets.all(16.0),
                child: Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    ElevatedButton(
                        onPressed: () async {
                          await DatabaseHelper().updateStudentBPM(
                              'N/A', widget.user!.userId, selectedPiece!.pieceId, _currentSectionIndex);
                        },
                        child: Text('N/A')),
                    ElevatedButton(
                        onPressed: () async {
                          await DatabaseHelper().updateStudentBPM(
                              _bpm, widget.user!.userId, selectedPiece!.pieceId, _currentSectionIndex);

                          setState(() {
                            _currentSectionBpm = _bpm;
                          });
                        },
                        child: Text('Confirm BPM')),
                  ]),
                ),
              ),
           
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
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'BPM'),
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
                GestureDetector(
                  onTap: () {
                    if (playing) {
                      stopMetronome();
                    } else {
                      startMetronome(currentSubdivisions);
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
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
                  style: ElevatedButton.styleFrom(backgroundColor: selectedSubdivisionIndex == 0 ? Colors.red : Colors.white, foregroundColor: Colors.black),
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
                  style: ElevatedButton.styleFrom(backgroundColor: selectedSubdivisionIndex == 1 ? Colors.red : Colors.white, foregroundColor: Colors.black),
                  onPressed: () {
                    setState(() {
                      selectedSubdivisionIndex = 1;
                      currentSubdivisions = 2;
                      stopMetronome();
                      startMetronome(currentSubdivisions);
                    });
                  },
                  child: Text('Eighth '),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: selectedSubdivisionIndex == 2 ? Colors.red : Colors.white, foregroundColor: Colors.black),
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
                  style: ElevatedButton.styleFrom(backgroundColor: selectedSubdivisionIndex == 3 ? Colors.red : Colors.white, foregroundColor: Colors.black),
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


class CircularBPMIndicator extends StatelessWidget {
  final double currentBpm;
  final double goalBpm;
  final double savedBpm;

  CircularBPMIndicator({
    required this.currentBpm,
    required this.goalBpm,
    required this.savedBpm,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200), // size of the circle
      painter: BPMIndicatorPainter(currentBpm: currentBpm, goalBpm: goalBpm, savedBpm: savedBpm),
    );
  }
}

class BPMIndicatorPainter extends CustomPainter {
  final double currentBpm;
  final double goalBpm;
  final double savedBpm;

  BPMIndicatorPainter({
    required this.currentBpm,
    required this.goalBpm,
    required this.savedBpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    double goalAngleStart = -pi / 2; // Start from the top (12 o'clock)
    double fullCircle = 2 * pi;

    // Define the BPM range that starts from 40 BPM
    double bpmRange = goalBpm - 40;

    // Draw the background arc for the goal BPM
    paint.color = Colors.grey.withOpacity(0.3); // Light grey for the background
    double goalSweepAngle = fullCircle; // Full circle as the max range for Goal BPM
    canvas.drawArc(Offset(0, 0) & size, goalAngleStart, goalSweepAngle, false, paint);

    // Draw the arc for the current BPM (this is the "live" value)
    double currentSweepAngle = 0.0;
    if (currentBpm > 40) {
      currentSweepAngle = fullCircle * ((currentBpm - 40) / bpmRange); // Map currentBpm from 40 to goalBpm
    }

    paint.color = Colors.red.withOpacity(0.8); // Color for current BPM (bright red)
    paint.strokeWidth = 14; // Thicker stroke for the current BPM
    canvas.drawArc(Offset(0, 0) & size, goalAngleStart, currentSweepAngle, false, paint);

    // Draw the arc for saved BPM (another track)
    double savedSweepAngle = 0.0;
    if (savedBpm > 40) {
      savedSweepAngle = fullCircle * ((savedBpm - 40) / bpmRange); // Map savedBpm from 40 to goalBpm
    }

    paint.color = Colors.green.withOpacity(0.8); // Color for saved BPM (green)
    paint.strokeWidth = 10; // Normal thickness for saved BPM
    canvas.drawArc(Offset(0, 0) & size, goalAngleStart, savedSweepAngle, false, paint);

    // Draw the center text (either a checkmark if current BPM exceeds goal BPM, or the current BPM value)
    TextSpan span;
    if (currentBpm > goalBpm) {
      // Display a check mark if Current BPM exceeds the Goal BPM
      span = TextSpan(
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        text: '✓', // Check mark
      );
    } else {
      // Otherwise, display the current BPM value
      span = TextSpan(
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        text: '${currentBpm.toInt()} BPM',
      );
    }

    // Paint the text at the center
    TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}