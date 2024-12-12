import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter/services.dart';
import 'database.dart';
import 'user.dart';
import 'sign_in.dart';
import 'settings.dart';
import 'customdrawer.dart';
import 'conductorScreens/music.dart';
import 'conductorScreens/dashboard.dart';
import 'music.dart';
import 'studentScreens/Assignments.dart';
import 'CircularBPMIndicator.dart';
import 'PulsingCircleWithNote.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
            user: ModalRoute.of(context)?.settings.arguments as Conductor),
        '/assignments': (context) {
          final Map arguments =
          ModalRoute.of(context)?.settings.arguments as Map;
          final Student student = arguments['user'];
          final List<Piece> pieces = arguments['pieces'] as List<Piece>;
          return Assignments(student: student, pieces: pieces);
        }
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.white)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white)),
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
  static const platform = MethodChannel('samples.flutter.dev/speech');
  double _bpm = 60;
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
  var handle = null;
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  // Define available tick sounds
  final List<String> tickSounds = [
    'click3.wav',
    'click2.wav',
    'weak_tick.wav',
    'strong_tick.wav',
    'sub_tick.wav',
    'up.wav',
    'down.wav',
    'claves.wav',
    'claves2.wav',
    'hihat.wav',
    'hihat2.wav',
    'kick.wav',
    'low_block.wav',
    'mid_block.wav',
    'snare.wav'
  ];

  String? selectedStrongTick = 'strong_tick.wav';
  String? selectedWeakTick = 'weak_tick.wav';

  late SoLoud _soloud;
  var sourceBeat; // Will be changed based on strong tick selection
  var sourceTick; // Will be changed based on weak tick selection

  @override
  void initState() {
    super.initState();
    if (widget.user is Student) {
      fetchPieces();
    }

    Future.delayed(Duration.zero, () async {
      _soloud = SoLoud.instance;
      await _soloud.init();
      await updateTickSounds();
    });
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
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
    _stopListening();
    final double oneBeat = 60 / _bpm;
    final double tickDuration = (subdivisions == 1) ? oneBeat : oneBeat / subdivisions;

    _timer?.cancel();

    _timer = Timer.periodic(
        Duration(milliseconds: (tickDuration * 1000).toInt()), (timer) async {
      tickCount++;

      print('Tick duration: ' + (tickDuration * 1000).toInt().toString());

      if (subdivisions == 1 || tickCount % subdivisions == 0) {
        _soloud.setGlobalVolume(1.0);
        handle = await _soloud.play(sourceBeat);
      } else {
        _soloud.setGlobalVolume(0.5);
        handle = await _soloud.play(sourceTick);
      }
    });

    setState(() {
      playing = true;
    });
  }

  void stopMetronome() {
    if (handle != null) {
      _timer?.cancel();
      _soloud.stop(handle);
      tickCount = 0;
      setState(() {
        playing = false;
      });
    } else {
      print("Metronome handle not initialized yet.");
    }
  }

  void _startListening() async {
    stopMetronome();
    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 30),
      partialResults: false,
      localeId: 'en_US', // specify your locale
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      if (_lastWords.toLowerCase().contains('start')) {
        startMetronome(currentSubdivisions);
      } else if (_lastWords.toLowerCase().contains('stop')) {
        stopMetronome();
      }else if (_lastWords.toLowerCase().contains('set to')) {
        // Extract the BPM value from the command
        RegExp exp = RegExp(r'set to (\d+)');
        Match? match = exp.firstMatch(_lastWords.toLowerCase());
        if (match != null) {
          String bpmString = match.group(1)!;
          int? newBpm = int.tryParse(bpmString);
          if (newBpm != null && newBpm >= 40 && newBpm <= 200) {
            setState(() {
              _bpm = newBpm.toDouble();
              _controller.text = newBpm.toString();
              stopMetronome();
              startMetronome(currentSubdivisions);
            });
          }
        }
      } else if (_lastWords.toLowerCase().contains('increase')) {
        setState(() {
          _bpm = (_bpm + 2).clamp(40.0, 200.0); // Ensure BPM stays within valid range
          _controller.text = _bpm.toString();
          stopMetronome();
          startMetronome(currentSubdivisions);
        });
      } else if (_lastWords.toLowerCase().contains('decrease')) {
        setState(() {
          _bpm = (_bpm - 2).clamp(40.0, 200.0); // Ensure BPM stays within valid range
          _controller.text = _bpm.toString();
          stopMetronome();
          startMetronome(currentSubdivisions);
        });
      }
      _stopListening();
      print('Last words recognized: $_lastWords');
    }
    print('Last words recognized: $_lastWords');
  }

  void handleSwipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx > 0) {
      if (_currentSectionIndex > 0) {
        _pageController.previousPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
        );
        setState(() {
          _currentSectionIndex--;
          selectedSection = selectedPiece!.sections[_currentSectionIndex];
          fetchBpmForSection(selectedSection!);
        });
      }
    } else if (details.velocity.pixelsPerSecond.dx < 0) {
      if (_currentSectionIndex < selectedPiece!.sections.length - 1) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
        );
        setState(() {
          _currentSectionIndex++;
          selectedSection = selectedPiece!.sections[_currentSectionIndex];
          fetchBpmForSection(selectedSection!);
        });
      }
    }
  }

  Future<void> updateTickSounds() async {
    sourceBeat = await _soloud.loadAsset('assets/$selectedStrongTick');
    sourceTick = await _soloud.loadAsset('assets/$selectedWeakTick');
  }

  // New method to show the tick sound selection dialog
  void _showTickSelectionDialog(bool isStrong) async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isStrong ? 'Select Strong Tick Sound' : 'Select Weak Tick Sound'),
          children: tickSounds.map((sound) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, sound);
              },
              child: Text(sound),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        if (isStrong) {
          selectedStrongTick = selected;
        } else {
          selectedWeakTick = selected;
        }
      });
      await updateTickSounds();
      if (playing) {
        stopMetronome();
        startMetronome(currentSubdivisions);
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
      drawer: CustomDrawer(
        stopMetronome: stopMetronome,
        user: widget.user,
        list: pieces,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        onHorizontalDragEnd: handleSwipe,
        behavior: HitTestBehavior.translucent,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            if (widget.user is Student && goalBpm != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: CircularBPMIndicator(
                  currentBpm: _bpm,
                  goalBpm: goalBpm!.toDouble(),
                  savedBpm: _currentSectionBpm?.toDouble(),
                ),
              ),
            if (widget.user == null || widget.user is Conductor)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: PulsingCircleWithNote(
                  size: 150.0,
                  bpm: _bpm,
                  playing: playing,
                ),
              ),
            if (widget.user is Student)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                ),
              ),
            if (selectedPiece != null && selectedPiece!.sections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_currentSectionBpm != null &&
                _currentSectionBpm != "N/A" &&
                goalBpm != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: DataTable(
                  columnSpacing: 20.0,
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Text(
                        'Confirmed BPM',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Goal BPM',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            _currentSectionBpm!.toInt() == -1
                                ? 'N/A'
                                : _currentSectionBpm!.toInt().toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: (_currentSectionBpm!.toDouble() >=
                                  goalBpm ||
                                  _currentSectionBpm! == -1)
                                  ? Colors.green
                                  : (_currentSectionBpm!.toDouble() >=
                                  (goalBpm! - 10))
                                  ? Colors.yellow
                                  : Colors.red,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            goalBpm?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: goalBpm != null
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (widget.user is Student && selectedPiece != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          await DatabaseHelper().updateStudentBPM(
                              'N/A',
                              widget.user!.userId,
                              selectedPiece!.pieceId,
                              _currentSectionIndex);

                          setState(() {
                            _currentSectionBpm = -1;
                          });
                        },
                        child: Text('N/A'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await DatabaseHelper().updateStudentBPM(
                              _bpm,
                              widget.user!.userId,
                              selectedPiece!.pieceId,
                              _currentSectionIndex);

                          setState(() {
                            _currentSectionBpm = _bpm;
                          });
                        },
                        child: Text('Confirm BPM'),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                  SizedBox(width: 10),
                  Container(
                    width: 120,
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
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_bpm < 200) {
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Slider(
                min: 40,
                max: 200,
                value: _bpm,
                onChanged: (newBPM) {
                  setState(() {
                    stopMetronome();
                    _bpm = newBPM;
                    _controller.text = newBPM.toInt().toString();

                    startMetronome(currentSubdivisions);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: GestureDetector(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
                      child: Text('♩'),
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
                      child: Text('♪'),
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
                      child: Text('♫'),
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
                      child: Text('♬'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTickSelectionDialog(true),
                      child: Text(
                        'Strong Tick: ${selectedStrongTick ?? "N/A"}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTickSelectionDialog(false),
                      child: Text(
                        'Weak Tick: ${selectedWeakTick ?? "N/A"}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(
          onPressed: _speechEnabled ? _startListening : null,
          tooltip: 'Voice Control',
          child: Icon(_speech.isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }
}