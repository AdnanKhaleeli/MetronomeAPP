import 'package:flutter/material.dart'; // Import ObjectId
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../user.dart';
import '../database.dart'; // Import the DatabaseHelper

class SelectStudentsPage extends StatefulWidget {
  final String pieceName;
  final List<String> sectionNames;
  final List<int> sectionBpms;
  final mongo.ObjectId musicId; // Change to ObjectId
  final Conductor user;

  SelectStudentsPage({
    Key? key,
    required this.pieceName,
    required this.sectionNames,
    required this.sectionBpms,
    required this.musicId, // Pass musicId here
    required this.user,
  }) : super(key: key);

  @override
  _SelectStudentsPageState createState() => _SelectStudentsPageState();
}

class _SelectStudentsPageState extends State<SelectStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  List<mongo.ObjectId> _selectedStudents = []; // Change to List<ObjectId>

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    // Fetch the list of students from the database
    var students = await DatabaseHelper().getStudents();
    setState(() {
      _students = students;
    });
  }

  void _toggleStudentSelection(mongo.ObjectId studentId) {
    setState(() {
      if (_selectedStudents.contains(studentId)) {
        _selectedStudents.remove(studentId);
      } else {
        _selectedStudents.add(studentId);
      }
    });
  }

  Future<void> _assignMusicToStudents() async {
    for (var studentId in _selectedStudents) {
      await DatabaseHelper().addMusicToStudent(studentId, widget.musicId); // Pass ObjectId directly
    }

    // Notify the user about the success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Music assigned to selected students!')),
    );

    // Navigate back or to another page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Students for ${widget.pieceName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _assignMusicToStudents,
          ),
        ],
      ),
      body: _students.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                var student = _students[index];
                return ListTile(
                  title: Text(student['username']),
                  trailing: Checkbox(
                    value: _selectedStudents.contains(student['_id']), // Use ObjectId directly
                    onChanged: (bool? value) {
                      // Convert the string ID to ObjectId
                      var studentId = student['_id'] as mongo.ObjectId;
                      _toggleStudentSelection(studentId);
                    },
                  ),
                );
              },
            ),
    );
  }
}
