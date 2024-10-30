import 'package:mongo_dart/mongo_dart.dart' as mongo;

import 'package:mongo_dart/mongo_dart.dart';
import 'user.dart';

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
    var student =
        await studentsCollection.findOne(where.eq('username', username));

    var conductorCollection = _db!.collection('Conductor');
    var conductor =
        await conductorCollection.findOne(where.eq('username', username));

    if (student != null && conductor != null) {
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
    var student =
        await studentsCollection.findOne(where.eq('username', username));

    var conductorCollection = _db!.collection('Conductor');
    var conductor =
        await conductorCollection.findOne(where.eq('username', username));

    if (student == null && conductor == null) {
      return true;
    }
    return false;
  }

  Future<ObjectId?> getUserID(String username) async {
    var studentsCollection = _db!.collection('Student');
    var student =
        await studentsCollection.findOne(where.eq('username', username));

    var conductorCollection = _db!.collection('Conductor');
    var conductor =
        await conductorCollection.findOne(where.eq('username', username));

    if (student != null) {
      return student['_id'];
    } else if (conductor != null) {
      return conductor['_id'];
    }
    return null; // Return null if no student is found
  }

  Future<User?> loginUser(String username, String password) async {
    var studentsCollection = _db!.collection('Student');

    // Find the student by username
    var student =
        await studentsCollection.findOne(where.eq('username', username));

    // Check if the student exists and if the password matches
    if (student != null && student['pwd'] == password) {
      // Create and return a User object if credentials match
      return Student(
        userId: student['_id'], // Assuming _id is the user ID
        username: student['username'],
        password: student['pwd'], // Consider handling this securely
        profileName: student['profilename'] ??
            '', // Default to an empty string if not set
      );
    } else {
      var conductorCollection = _db!.collection('Conductor');
      var conductor =
          await conductorCollection.findOne(where.eq('username', username));

      if (conductor != null && conductor['pwd'] == password) {
        return Conductor(
            userId: conductor['_id'],
            username: conductor['username'],
            password: conductor['pwd'],
            profileName: conductor['profilename']);
      }
    }

    // Return null if no matching student is found
    return null;
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    // Check if the database is initialized
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    // Access the students collection
    var studentsCollection = _db!.collection('Student');

    // Fetch all students from the collection
    final students = await studentsCollection.find().toList();

    // Map each document to a simplified format and return as a list
    return students.map((student) {
      return {
        '_id': student['_id'],
        'username': student['username'],
        'profilename': student['profilename'],
        // Add any other fields as necessary
      };
    }).toList();
  }

  Future<mongo.ObjectId?> insertMusic({
    required String pieceName,
    required List<String> sectionNames,
    required List<int> sectionBpms,
  }) async {
    if (_db == null) {
      return null;
    }

    var musicCollection = _db!.collection('Music');

  
    var newMusic = {
      'piece_name': pieceName,
      'sections': List.generate(sectionNames.length, (index) {
        return {
          'name': sectionNames[index],
          'bpm': sectionBpms[index],
        };
      }),
    };

 
    await musicCollection.insert(newMusic);

    
    var insertedMusic =
        await musicCollection.findOne(where.eq('piece_name', pieceName));

 
    return insertedMusic?['_id']; // Return null if not found
  }

  Future<bool> addMusicToStudent(mongo.ObjectId studentId, mongo.ObjectId musicId, int numSections) async {
  if (_db == null) {
    return false;
  }

  var studentsCollection = _db!.collection('Student');

   List<int> initialArray = List<int>.filled(numSections, 0);

  var result = await studentsCollection.updateOne(
    where.eq('_id', studentId),
    modify.set('assigned_music.$musicId', initialArray),
  );

  return result.isAcknowledged; 
}

  Future<List<String>> getPieceNamesForUser(User user) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var studentsCollection = _db!.collection('Student');
    var student = await studentsCollection.findOne(
        where.eq('_id', user.userId)); // Assuming userId is of type ObjectId

    if (student != null) {
      // Extract the assigned_music which is a list of ObjectIds
      List<ObjectId> musicIds =
          List<ObjectId>.from(student['assigned_music'] ?? []);

      // Now fetch the music names from the Music collection based on these IDs
      var musicCollection = _db!.collection('Music');
      var musicPieces =
          await musicCollection.find(where.oneFrom('_id', musicIds)).toList();

      // Return the names of the pieces
      return musicPieces.map((music) => music['piece_name'] as String).toList();
    }

    return []; // Return an empty list if no student is found
  }

  Future<List<String>> getSectionsForPiece(String pieceName) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var musicCollection = _db!.collection('Music');
    // Find the music piece by name
    var musicPiece =
        await musicCollection.findOne(where.eq('piece_name', pieceName));

    if (musicPiece != null) {
      // Extract the sections from the music piece
      List<Map<String, dynamic>> sections =
          List<Map<String, dynamic>>.from(musicPiece['sections'] ?? []);
      // Return the names of the sections
      return sections.map((section) => section['name'] as String).toList();
    }

    return []; // Return an empty list if no music piece is found
  }

  Future<int?> getBpmForSection(String sectionName) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var musicCollection = _db!.collection('Music');

    // Find the music piece that contains the section with the given name
    var musicPieces = await musicCollection
        .find(where.eq('sections.name', sectionName))
        .toList();

    if (musicPieces.isNotEmpty) {
      var musicPiece = musicPieces.first; // Take the first match
      List<Map<String, dynamic>> sections =
          List<Map<String, dynamic>>.from(musicPiece['sections'] ?? []);

      // Find the section in the music piece
      var section = sections.firstWhere((s) => s['name'] == sectionName,
          orElse: () => {} // Provide an empty map as the default value
          );

      // Check if the section map is not empty and return the BPM
      return section.isNotEmpty
          ? section['bpm']
          : null; // Return the BPM or null if not found
    }

    return null; // Return null if no section is found
  }
}
