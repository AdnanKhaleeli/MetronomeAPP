import 'package:mongo_dart/mongo_dart.dart' as mongo;

import 'package:mongo_dart/mongo_dart.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  Db? _db;

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor to return the same instance
  factory DatabaseHelper() {
    return _instance;
  }

  // Method to initialize the database connection
  Future<void> init() async {
    if (_db == null) {
      _db = await mongo.Db.create(
          "mongodb+srv://USER:USER1@metronome-cluster.3otig.mongodb.net/metronome_db?retryWrites=true&w=majority");
      await _db!.open();
    }
    if (_db != null && _db!.isConnected) {
      print(
          'Database connected. ${_db!.databaseName}'); // Correctly accessing the property
    } else {
      print('Database connection failed.');
    }
  }

  // Method to get the database instance
  Db get db {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<bool> insertStudent(
      {required String username,
      required String pwd,
      required String profilename}) async {
    if (_db == null) {
      return false;
    }

    var studentsCollection = _db!.collection('Student');
    var student = await studentsCollection.findOne(where.eq('name', username));

    if (student != null) {
      return false;
    }

    var newStudent = {
      'username': username,
      'pwd': pwd,
      'profilename': profilename,
      'assigned_music': {},
      'subgroup_id': null
    };

    await studentsCollection.insert(newStudent);
    return true;
  }

  Future<bool> checkUserNameUnique(String username) async {
    var studentsCollection = _db!.collection('Student');
    var student = await studentsCollection.findOne(where.eq('username', username));

    if (student == null) {
      return true;
    }
    return false;
  }

  Future<ObjectId?> getUserID(String username) async {
    var studentsCollection = _db!.collection('Student');
    var student = await studentsCollection.findOne(where.eq('username', username));
  
  if (student != null) {
    return student['_id'];
  }
   return null; // Return null if no student is found
  }
}
