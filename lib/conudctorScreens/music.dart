import 'package:flutter/material.dart';
import '../user.dart';
import '../customdrawer.dart';
import 'selectStudentsPage.dart'; // Import the new student selection page

class AddMusic extends StatefulWidget {
  final Conductor user;
  AddMusic({super.key, required this.user});

  @override
  State<AddMusic> createState() => AddMusicState();
}

class AddMusicState extends State<AddMusic> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pieceNameController = TextEditingController();
  final TextEditingController _numSectionsController = TextEditingController();

  List<TextEditingController> _sectionNameControllers = [];
  List<TextEditingController> _sectionBpmControllers = [];
  int _numSections = 0;

  @override
  void dispose() {
    _pieceNameController.dispose();
    _numSectionsController.dispose();
    for (var controller in _sectionNameControllers) {
      controller.dispose();
    }
    for (var controller in _sectionBpmControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateSections(int numSections) {
    setState(() {
      _sectionNameControllers = List.generate(numSections, (index) => TextEditingController());
      _sectionBpmControllers = List.generate(numSections, (index) => TextEditingController());
      _numSections = numSections;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Music Here'),
        centerTitle: true,
      ),
      drawer: CustomDrawer(
        isOnSignInPage: false,
        user: widget.user,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _pieceNameController,
                decoration: InputDecoration(labelText: 'Piece Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the piece name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _numSectionsController,
                decoration: InputDecoration(labelText: 'Number of Sections'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of sections';
                  }
                  return null;
                },
                onChanged: (value) {
                  int? sections = int.tryParse(value);
                  if (sections != null) {
                    _updateSections(sections);
                  }
                },
              ),
              SizedBox(height: 20),
              for (int i = 0; i < _numSections; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sectionNameControllers[i],
                        decoration: InputDecoration(labelText: 'Section ${i + 1} Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the name for section ${i + 1}';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 80,  // Set a fixed width for the BPM field
                      child: TextFormField(
                        controller: _sectionBpmControllers[i],
                        decoration: InputDecoration(labelText: 'BPM'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the BPM for section ${i + 1}';
                          }
                          final bpm = int.tryParse(value);
                          if (bpm == null || bpm <= 0) {
                            return 'BPM must be a positive integer';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String pieceName = _pieceNameController.text;
                    List<String> sectionNames = _sectionNameControllers.map((c) => c.text).toList();
                    List<int> sectionBpms = _sectionBpmControllers.map((c) => int.parse(c.text)).toList();

                    // Navigate to the SelectStudentsPage with piece data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectStudentsPage(
                          pieceName: pieceName,
                          sectionNames: sectionNames,
                          sectionBpms: sectionBpms,
                          user: widget.user,
                        ),
                      ),
                    );
                  }
                },
                child: Text("Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
