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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "Default Values",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              _buildRow(
                label: "Increase",
                controller: increaseController,
              ),
              SizedBox(height: 20.0),
              _buildRow(
                label: "Decrease",
                controller: decreaseController,
              ),
              SizedBox(height: 30.0),
              Center(
                child: ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller,
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
    );
  }
}
