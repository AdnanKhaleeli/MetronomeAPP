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
      _db = await Db.create(
          "mongodb+srv://USER:USER1@metronome-cluster.3otig.mongodb.net/metronome_db?retryWrites=true&w=majority");
      await _db!.open();
    }
    if (_db != null && _db!.isConnected) {
      print('Database connected. ${_db!.databaseName}');
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

  Future<bool> insertStudent({
    required String username,
    required String pwd,
    required String profilename,
  }) async {
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
    return null;
  }

  Future<User?> loginUser(String username, String password) async {
    var studentsCollection = _db!.collection('Student');

    var student =
        await studentsCollection.findOne(where.eq('username', username));

    if (student != null && student['pwd'] == password) {
      return Student(
        userId: student['_id'],
        username: student['username'],
        password: student['pwd'],
        profileName: student['profilename'] ?? '',
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
          profileName: conductor['profilename'],
        );
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var studentsCollection = _db!.collection('Student');
    final students = await studentsCollection.find().toList();

    return students.map((student) {
      return {
        '_id': student['_id'],
        'username': student['username'],
        'profilename': student['profilename'],
      };
    }).toList();
  }

  Future<ObjectId?> insertMusic({
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
    return insertedMusic?['_id'];
  }

  Future<bool> addMusicToStudent(
      ObjectId studentId, ObjectId musicId, int numSections) async {
    if (_db == null) {
      return false;
    }

    var studentsCollection = _db!.collection('Student');
    List<int> initialArray = List<int>.filled(numSections, 0);

    var result = await studentsCollection.updateOne(
      where.eq('_id', studentId),
      modify.set('assigned_music.${musicId.oid}', initialArray),
    );

    return result.isAcknowledged;
  }

  Future<List<String>> getPieceNamesForUser(User user) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var studentsCollection = _db!.collection('Student');
    var student =
        await studentsCollection.findOne(where.eq('_id', user.userId));

    if (student != null) {
      var assignedMusic = student['assigned_music'];

      List<ObjectId> musicIds = [];

      // Convert String instances back to ObjectId
      for (var key in assignedMusic.keys) {
        if (key is String) {
          // Convert string to ObjectId
          musicIds.add(ObjectId.fromHexString(key));
        } else {
          print('Unexpected key type: $key of type ${key.runtimeType}');
        }
      }

      var musicCollection = _db!.collection('Music');

      // Query using ObjectId instances
      var musicPieces =
          await musicCollection.find(where.oneFrom('_id', musicIds)).toList();
      return musicPieces.map((music) => music['piece_name'] as String).toList();
    }

    return [];
  }

  Future<List<String>> getSectionsForPiece(String pieceName) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var musicCollection = _db!.collection('Music');
    var musicPiece =
        await musicCollection.findOne(where.eq('piece_name', pieceName));

    if (musicPiece != null) {
      List<Map<String, dynamic>> sections =
          List<Map<String, dynamic>>.from(musicPiece['sections'] ?? []);
      return sections.map((section) => section['name'] as String).toList();
    }

    return [];
  }

  Future<int?> getBpmForSection(String sectionName) async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var musicCollection = _db!.collection('Music');
    var musicPieces = await musicCollection
        .find(where.eq('sections.name', sectionName))
        .toList();

    if (musicPieces.isNotEmpty) {
      var musicPiece = musicPieces.first;
      List<Map<String, dynamic>> sections =
          List<Map<String, dynamic>>.from(musicPiece['sections'] ?? []);
      var section = sections.firstWhere((s) => s['name'] == sectionName,
          orElse: () => {});
      return section.isNotEmpty ? section['bpm'] : null;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getAllMusicPieces() async {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    var musicCollection = _db!.collection('Music');
    final musicPieces = await musicCollection.find().toList();

    return musicPieces.map((music) {
      return {
        '_id': music['_id'],
        'piece_name': music['piece_name'],
        'sections': music['sections'], 
      };
    }).toList();

    
  }

  Future<bool> deleteMusicPiece(ObjectId musicId) async {
  if (_db == null) {
    return false;
  }

  var musicCollection = _db!.collection('Music');
  var result = await musicCollection.deleteOne(where.eq('_id', musicId));

  return result.isAcknowledged;
}

}
