import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MetronomeApp());
}

class MetronomeApp extends StatefulWidget {
  @override
  _MetronomeAppState createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  double _bpm = 60;
  final player = AudioPlayer();



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Metronome App'),
        ),
        body: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: ${_bpm.toInt()}'),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              //adding a slider for the BPM
            //min: 40, max: 200
            children: [

              ElevatedButton(
                onPressed: () {
                  setState(()
                  {
                    _bpm = _bpm - 1;
                  });
                },
                child: Text("-"),
              ),
             Slider(
                              min: 40,
                              max: 200,
                              value: _bpm,
                              //If changed, new value is newBPM
                              onChanged: (newBPM) {
                                setState(()
                                {
                                //setting the BPM to new BPM
                                  _bpm = newBPM;
                                });},

                ),

              ElevatedButton(
                onPressed: ()
                {
                  setState(()
                  {
                    _bpm = _bpm + 1;
                  });
                },
                child: Text("+"),
              ),


            ],
            )



            ,Row(
              //centering an axis along the center of the screen
              mainAxisAlignment: MainAxisAlignment.center,
              //underneath the axis, add buttons(children)
              children: [
                ElevatedButton(
                  //when pressed, start the metronome
                  onPressed: ()
                  async {
                    await player.play(AssetSource('assets/tick_sound.mp3'));
                  },
                  child: Text('Start'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  //when pressed, stop the metronome
                  onPressed: () {  },
                  child: Text('Stop'),
                ),
              ],
            ),
        ],
        ),
      ),
    );
  }
}
