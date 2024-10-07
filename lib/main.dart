import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;



void main() async {
   var db = await mongo.Db.create("mongodb+srv://USER:USER1@metronome-cluster.3otig.mongodb.net/metronome_db?retryWrites=true&w=majority");
   await db.open();

  print('Connected to database: ${db.databaseName}');
  runApp(const Metronome());

 
}

class Metronome extends StatefulWidget {
  const Metronome({super.key});

  @override
  State<Metronome> createState() => _Metronome();
}

class _Metronome extends State<Metronome> {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Metronome'),
          centerTitle: true,
          backgroundColor: Colors.red[400],
        ),
        drawer:  Drawer(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: <Widget>[
              ListTile(
                title: const Text('Hello there'),
                onTap: () {},
              )
            ],
          )
        ),
        body: const Text("This is the body")
      )
    );
  }
}
