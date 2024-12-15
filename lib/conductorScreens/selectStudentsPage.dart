import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../user.dart';
import '../database.dart';

class SelectStudentsPage extends StatefulWidget {
  final String pieceName;
  final List<String> sectionNames;
  final List<int> sectionBpms;
  final mongo.ObjectId musicId;
  final Conductor user;
  final int numSections;

  SelectStudentsPage({
    Key? key,
    required this.pieceName,
    required this.sectionNames,
    required this.sectionBpms,
    required this.musicId,
    required this.user,
    required this.numSections,
  }) : super(key: key);

  @override
  _SelectStudentsPageState createState() => _SelectStudentsPageState();
}

class _SelectStudentsPageState extends State<SelectStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  List<mongo.ObjectId> _selectedStudents = [];
  bool _allSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    var students = await DatabaseHelper().getStudents();
    setState(() {
      _students = students;
    });

    // After fetching the students, check which ones are already assigned to this music
    await _checkAssignedStudents();
  }

  Future<void> _checkAssignedStudents() async {
    // Check each student if they have this music assigned
    for (var student in _students) {
      var studentId = student['_id'] as mongo.ObjectId;
      var musicIds = student['assigned_music']?.keys.map((key) => mongo.ObjectId.fromHexString(key)).toList() ?? [];

      if (musicIds.contains(widget.musicId)) {
        setState(() {
          _selectedStudents.add(studentId);
        });
      }
    }
  }

  void _toggleStudentSelection(mongo.ObjectId studentId) {
    setState(() {
      if (_selectedStudents.contains(studentId)) {
        _selectedStudents.remove(studentId);
        _removeMusicFromStudent(studentId);  // Remove the music assignment
      } else {
        _selectedStudents.add(studentId);
        _assignMusicToStudent(studentId);  // Assign the music
      }

      // Update the "Select All" checkbox based on the current selection
      _allSelected = _selectedStudents.length == _students.length;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedStudents.clear();
        _removeMusicFromAllStudents();  // Remove music from all students
      } else {
        _selectedStudents = _students
            .map((student) => student['_id'] as mongo.ObjectId)
            .toList();
        _assignMusicToAllStudents();  // Assign music to all students
      }
      _allSelected = !_allSelected;
    });
  }

  Future<void> _assignMusicToStudent(mongo.ObjectId studentId) async {
    await DatabaseHelper()
        .addMusicToStudent(studentId, widget.musicId, widget.numSections);
  }

  Future<void> _removeMusicFromStudent(mongo.ObjectId studentId) async {
    await DatabaseHelper().removeMusicFromStudent(studentId, widget.musicId);
  }

  Future<void> _assignMusicToAllStudents() async {
    for (var student in _students) {
      var studentId = student['_id'] as mongo.ObjectId;
      await _assignMusicToStudent(studentId);
    }
  }

  Future<void> _removeMusicFromAllStudents() async {
    for (var student in _students) {
      var studentId = student['_id'] as mongo.ObjectId;
      await _removeMusicFromStudent(studentId);
    }
  }

  Future<void> _assignMusicToStudents() async {
    for (var studentId in _selectedStudents) {
      await DatabaseHelper()
          .addMusicToStudent(studentId, widget.musicId, widget.numSections);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Music assigned to selected students!')),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Students for ${widget.pieceName}'),
        actions: [
          Row(
            children: [
              Checkbox(
                value: _allSelected,
                onChanged: (bool? value) {
                  _toggleSelectAll();
                },
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: _assignMusicToStudents,
              ),
            ],
          ),
        ],
      ),
      body: _students.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                var student = _students[index];
                var studentId = student['_id'] as mongo.ObjectId;

                return ListTile(
                  title: Text(student['profilename']),
                  trailing: Checkbox(
                    value: _selectedStudents.contains(studentId),
                    onChanged: (bool? value) {
                      _toggleStudentSelection(studentId);
                    },
                  ),
                );
              },
            ),
    );
  }
}
