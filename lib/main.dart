import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

void main() async {
  var db = await mongo.Db.create("mongodb+srv://USER:USER1@metronome-cluster.3otig.mongodb.net/metronome_db?retryWrites=true&w=majority");
  await db.open();
  print('Connected to database: ${db.databaseName}');
  runApp(MetronomeApp());
}

class MetronomeApp extends StatefulWidget {
  @override
  _MetronomeAppState createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  double _bpm = 60;
  final player = AudioPlayer();
  bool playing = true;


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
                    if(_bpm > 40)
                      {
                        _bpm = _bpm - 1;
                      }
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
                    if(_bpm < 199)
                    {
                      _bpm = _bpm + 1;
                    }
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
                  playing = true;

                    //looping the sound
                    while (playing)
                      {
                        //calculation desired duration of one beat in seconds
                        double oneBeat = 60/_bpm;

                        //length of tick_sound is 0.022. length of one beat - length of tick sound is wait time
                        double waitTime = oneBeat-0.156;
                        //setting source of the audio file
                        await player.setSource(AssetSource('tick_sound_156.wav'));
                        //playing the audio file
                        await player.resume();
                        //delaying the loop (length of tick sound)
                        await Future.delayed(Duration(milliseconds: 156));
                        //delaying the loop(length of wait time
                        await Future.delayed(Duration(milliseconds: (waitTime * 1000).toInt()));
                        //Now, one full beat has been completed. The loop will loop again!

                      }


                  },
                  child: Text('Start'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  //when pressed, stop the metronome
                  onPressed: () {
                    playing = false;
                    player.stop();
                  },
                  child: Text('Stop'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (){},
                  child: Text('Beat 1'),
                ),
                ElevatedButton(
                  onPressed: (){},
                  child: Text('Beat 2'),
                ),
                ElevatedButton(
                  onPressed: (){},
                  child: Text('Beat 3'),
                ),
                ElevatedButton(
                  onPressed: (){},
                  child: Text('Beat 4'),
                )

              ]
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (){},
                    child: Text('♩', style: new TextStyle(fontSize: 50.0)),
                  ),
                  ElevatedButton(
                    onPressed: (){},
                    child: Text('♪', style: TextStyle(fontSize: 50.0)),
                  ),
                  ElevatedButton(
                    onPressed: (){},
                    child: Text('♫', style: TextStyle(fontSize: 50.0)),
                  ),
                  ElevatedButton(
                    onPressed: (){},
                    child: Text('♬', style: TextStyle(fontSize: 50.0)),
                  )

                ]
            )






        ],
        ),
      ),
    );
  }
}