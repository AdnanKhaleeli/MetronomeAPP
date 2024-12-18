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
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'about.dart';

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
        '/settings': (context) =>
            Settings(user: ModalRoute.of(context)?.settings.arguments as User),
        '/addMusic': (context) => AddMusic(
            user: ModalRoute.of(context)!.settings.arguments as Conductor),
        '/dashboard_conductor': (context) => Dashboard(
            user: ModalRoute.of(context)?.settings.arguments as Conductor),
        '/about': (context) => About(),
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
        cardTheme: CardTheme(
          color: Colors.blueGrey[900],
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
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

class _MetronomeAppState extends State<MetronomeApp>
    with WidgetsBindingObserver {
  double _bpm = 60;
  late SoLoud _soloud;
  late var sourceBeat;
  late var sourceTick;
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
  bool isListening = false;

  int increaseVal = 2;
  int decreaseVal = 2;

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
  bool _speechEnabled = false;
  String _lastWords = '';
  final SpeechToText _speech = SpeechToText();

  final MethodChannel _channelMethod = new MethodChannel("Method");

  @override
  void initState() {
    super.initState();

    _controller.text = _bpm.toInt().toString();
    WidgetsBinding.instance?.addObserver(this);
    Future.delayed(Duration.zero, () async {
      if (widget.user is Student) {
        await fetchPieces();
      }

      _soloud = SoLoud.instance;
      await _soloud.init();

      sourceBeat = await _soloud.loadAsset('assets/audio/strong_tick.wav');
      sourceTick = await _soloud.loadAsset('assets/audio/click3.wav');

      if (Platform.isIOS) {
        final permissions = await _channelMethod.invokeMethod('permissions');
        print('Result from IOS  $permissions');

        await _channelMethod.invokeMethod('startListening');
        isListening = true;
        _channelMethod.setMethodCallHandler((MethodCall call) async {
          switch (call.method) {
            case 'onSpeechRecognized':
              String recognizedText = call.arguments;
              print("Received recognized speech: $recognizedText");
              handleSpeechTextIOS(recognizedText.toLowerCase());

              break;
            default:
              throw MissingPluginException('notImplemented');
          }
        });
      }

      if (Platform.isAndroid) {
        _initSpeech();
      }
    });

    if (widget.user != null) {
      _fetchUserValues();
    }
  }

  void _fetchUserValues() async {
    increaseVal = await DatabaseHelper().getIncreaseVal(widget.user!);
    decreaseVal = await DatabaseHelper().getDecreaseVal(widget.user!);
    setState(() {});
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    print(_speechEnabled);
    setState(() {});
  }

  void _startListening() async {
    stopMetronome();
    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 30),
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
      } else if (_lastWords.toLowerCase().contains('set to')) {
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
          _bpm = (_bpm + increaseVal)
              .clamp(40.0, 200.0); // Ensure BPM stays within valid range
          _controller.text = _bpm.toInt().toString();
          stopMetronome();
          startMetronome(currentSubdivisions);
        });
      } else if (_lastWords.toLowerCase().contains('decrease')) {
        setState(() {
          _bpm = (_bpm - decreaseVal)
              .clamp(40.0, 200.0); // Ensure BPM stays within valid range
          _controller.text = _bpm.toInt().toString();
          stopMetronome();
          startMetronome(currentSubdivisions);
        });
      }
      _stopListening();
      print('Last words recognized: $_lastWords');
    }
    print('Last words recognized: $_lastWords');
  }

  Future<void> updateTickSounds() async {
    sourceBeat = await _soloud.loadAsset('assets/audio/$selectedStrongTick');
    sourceTick = await _soloud.loadAsset('assets/audio/$selectedWeakTick');
  }

  // New method to show the tick sound selection dialog
  void _showTickSelectionDialog(bool isStrong) async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
              isStrong ? 'Select Strong Tick Sound' : 'Select Weak Tick Sound'),
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

  void handleSpeechTextIOS(String text) async {
    bool updated = false;
    RegExp regExp = RegExp(r'-?\d+(\.\d+)?');
    const numberWords = {
      'one': 1,
      'two': 2,
      'too': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'hundred': 100
    };

    if (text.contains('stop')) {
      if (playing) {
        stopMetronome();
        playing = false;
        updated = false;
      }

      //Division 1
    } else if (text.contains('start')) {
      playing = true;
      startMetronome(currentSubdivisions);
      updated = true;
    } else if (text.contains('increase')) {
      _bpm = (_bpm + increaseVal <= 200) ? _bpm + increaseVal : 200;
      updated = true;
    } else if (text.contains('decrease')) {
      _bpm = (_bpm - decreaseVal >= 40) ? _bpm - decreaseVal : 40;
      updated = true;
    } else if (text.contains('fast') || text.contains('slow')) {
      bool isFaster = text.contains('fast');
      double adjustment = 0;

      final match = regExp.firstMatch(text);
      if (match != null) {
        adjustment = double.parse(match.group(0)!);
      } else {
        numberWords.forEach((word, value) {
          if (text.contains(word)) {
            adjustment = value.toDouble();
          }
        });
      }

      _bpm = isFaster
          ? adjustment + _bpm <= 200
              ? adjustment + _bpm
              : 200
          : _bpm - adjustment > 40
              ? _bpm - adjustment
              : 40;
      if (adjustment == 0) {
        updated = false;
      } else {
        updated = true;
      }
    } else if (text.contains('division')) {
      numberWords.forEach((word, value) {
        if (text.contains(word)) {
          currentSubdivisions = value;
          selectedSubdivisionIndex = currentSubdivisions - 1;
          updated = true;
        }
      });
    } else if (text.contains('set')) {
      final match = regExp.firstMatch(text);
      if (match != null) {
        double val = double.parse(match.group(0)!);
        _bpm = val >= 40 && val <= 200 ? val : _bpm;
        updated = true;
      } else {
        numberWords.forEach((word, value) {
          if (text.contains(word)) {
            _bpm = value >= 40 && value <= 200 ? value.toDouble() : _bpm;
            updated = true;
          }
        });
      }
    }

    if (updated) {
      setState(() {
        _controller.text = _bpm.toInt().toString();
        stopMetronome();
        startMetronome(currentSubdivisions);
      });
    }
  }

  Future<void> fetchPieces() async {
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
    Platform.isAndroid ? _stopListening() : null;
    final double oneBeat = 60 / _bpm;
    final double tickDuration =
        (subdivisions == 1) ? oneBeat : oneBeat / subdivisions;

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

  @override
  void dispose() {
    _timer?.cancel();
    _soloud.disposeSource(sourceBeat);
    _pageController.dispose();
    handle = null;
    _soloud.deinit();
    super.dispose();

    Future.delayed(Duration.zero, () async {
      if (Platform.isIOS) {
        _channelMethod.invokeMethod('stopListening');
        isListening = false;
      }
    });
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

  void toggleVoice() {
    if (isListening) {
      _channelMethod.invokeMethod('stopListening');
      isListening = false;
    } else {
      _channelMethod.invokeMethod('startListening');
      isListening = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metronome App'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: CustomDrawer(
          stopMetronome: stopMetronome,
          user: widget.user,
          list: pieces,
          toggleVoice: toggleVoice),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        onHorizontalDragEnd: handleSwipe,
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.user is Student && goalBpm != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CircularBPMIndicator(
                        currentBpm: _bpm,
                        goalBpm: goalBpm!.toDouble(),
                        savedBpm: _currentSectionBpm?.toDouble(),
                      ),
                      SizedBox(width: 20),
                      if (_currentSectionBpm != null &&
                          _currentSectionBpm != "N/A" &&
                          goalBpm != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align text to the left
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Goal BPM:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  goalBpm?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: goalBpm != null
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10), // Add space between columns
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirmed BPM:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _currentSectionBpm!.toInt() == -1
                                      ? 'N/A'
                                      : _currentSectionBpm!.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 18,
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
                              ],
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              if (widget.user is! Student ||
                  pieces.isEmpty ||
                  selectedPiece == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                    hint: Text(pieces.isEmpty
                        ? 'No pieces assigned '
                        : 'Select a Piece'),
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
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (widget.user is Student && selectedPiece != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                              child: Text('N/A')),
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
                              child: Text('Confirm BPM')),
                        ]),
                  ),
                ),
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
                      width: 150,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: 'BPM',
                          labelStyle: TextStyle(color: Colors.white),
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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSubdivisionIndex == 0
                                ? Colors.red
                                : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5),
                        onPressed: () {
                          setState(() {
                            selectedSubdivisionIndex = 0;
                            currentSubdivisions = 1;
                            stopMetronome();
                            startMetronome(currentSubdivisions);
                          });
                        },
                        child: Text('♩',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSubdivisionIndex == 1
                                ? Colors.red
                                : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5),
                        onPressed: () {
                          setState(() {
                            selectedSubdivisionIndex = 1;
                            currentSubdivisions = 2;
                            stopMetronome();
                            startMetronome(currentSubdivisions);
                          });
                        },
                        child: Text('♪',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSubdivisionIndex == 2
                                ? Colors.red
                                : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5),
                        onPressed: () {
                          setState(() {
                            selectedSubdivisionIndex = 2;
                            currentSubdivisions = 3;
                            stopMetronome();
                            startMetronome(currentSubdivisions);
                          });
                        },
                        child: Text('♫',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSubdivisionIndex == 3
                                ? Colors.red
                                : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5),
                        onPressed: () {
                          setState(() {
                            selectedSubdivisionIndex = 3;
                            currentSubdivisions = 4;
                            stopMetronome();
                            startMetronome(currentSubdivisions);
                          });
                        },
                        child: Text('♬',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
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
                  SizedBox(height: 20), // Add some space between the rows
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Platform.isAndroid
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Tooltip(
                message: 'Voice Control',
                child: FloatingActionButton(
                  onPressed: _speechEnabled ? _startListening : null,
                  child: Icon(_speech.isListening ? Icons.mic : Icons.mic_none),
                ),
              ),
            )
          : null,
    );
  }
}
