import 'package:flutter/material.dart';
import '../user.dart';
import '../database.dart'; // Ensure you have a way to access your database
import 'music.dart'; // Import the music.dart for the piece data

class SelectStudentsPage extends StatefulWidget {
  final String pieceName;
  final List<String> sectionNames;
  final List<int> sectionBpms;
  final Conductor user;

  SelectStudentsPage({
    Key? key,
    required this.pieceName,
    required this.sectionNames,
    required this.sectionBpms,
    required this.user,
  }) : super(key: key);

  @override
  State<SelectStudentsPage> createState() => _SelectStudentsPageState();
}

class _SelectStudentsPageState extends State<SelectStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  List<String> _selectedStudents = []; // To keep track of selected students

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.init(); // Initialize the database if not done already
    List<Map<String, dynamic>> students = await dbHelper.getStudents();
    setState(() {
      _students = students;
    });
  }

  void _onStudentSelected(String username, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedStudents.add(username);
      } else {
        _selectedStudents.remove(username);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Students'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _students.isEmpty
            ? Center(child: CircularProgressIndicator()) // Loading indicator
            : ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            return CheckboxListTile(
              title: Text(student['profilename']),
              value: _selectedStudents.contains(student['profilename']),
              onChanged: (bool? value) {
                _onStudentSelected(student['profilename'], value ?? false);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // You can handle the next step here, such as saving the selection or navigating to another page
          // You may want to use the selected students' data along with piece information
          Navigator.pop(context, _selectedStudents); // Pass selected students back to previous screen
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
