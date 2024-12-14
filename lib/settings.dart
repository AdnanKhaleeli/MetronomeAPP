import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database.dart';
import 'user.dart';

class Settings extends StatefulWidget {
  final User user;

  Settings({super.key, required this.user});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late int increaseValue;
  late int decreaseValue;

  final TextEditingController increaseController = TextEditingController();
  final TextEditingController decreaseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  Future<void> _initializeValues() async {
    int fetchedIncreaseValue =
        await DatabaseHelper().getIncreaseVal(widget.user);
    int fetchedDecreaseValue =
        await DatabaseHelper().getDecreaseVal(widget.user);
    setState(() {
      increaseValue = fetchedIncreaseValue;
      decreaseValue = fetchedDecreaseValue;
      increaseController.text = increaseValue.toString();
      decreaseController.text = decreaseValue.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Voice Recognition Default Values",
              style: TextStyle(fontSize: 24),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Increase",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: 8.0),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: increaseController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Decrease",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: 8.0),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: decreaseController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () async {
              if (increaseController.text.isNotEmpty &&
                  decreaseController.text.isNotEmpty) {
                int increaseInput = int.parse(increaseController.text);
                int decreaseInput = int.parse(decreaseController.text);

                if (increaseInput > 0 && decreaseInput > 0) {
                  setState(() {
                    DatabaseHelper().setIncreaseVal(widget.user, increaseInput);
                    DatabaseHelper().setDecreaseVal(widget.user, decreaseInput);
                    increaseValue = increaseInput;
                    decreaseValue = decreaseInput;
                  });
                  Navigator.pushNamed(context, '/', arguments: widget.user);
                }
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
}
