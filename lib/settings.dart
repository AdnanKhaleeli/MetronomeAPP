import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Settings extends StatelessWidget {
  static int increaseValue = 2;
  static int decreaseValue = 2;

  Settings({super.key});

  final TextEditingController increaseController = TextEditingController(text: increaseValue.toString());
  final TextEditingController decreaseController = TextEditingController(text: decreaseValue.toString());

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
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Increase",
                style: TextStyle(
                  fontSize: 18,
                ),
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
                style: TextStyle(
                  fontSize: 18,
                ),
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
            onPressed: () {
              if (increaseController.text != "" && decreaseController.text != "") {
                int increaseInput = int.parse(increaseController.text);
                int decreaseInput = int.parse(decreaseController.text);

                if (increaseInput > 0 && decreaseInput > 0) {
                  increaseValue = increaseInput;
                  decreaseValue = decreaseInput;
                  Navigator.pushNamed(context, '/');
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