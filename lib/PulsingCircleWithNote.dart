import 'package:flutter/material.dart';
import 'dart:async';

class PulsingCircleWithNote extends StatefulWidget {
  final double size;
  final double bpm;
  final bool playing; // New parameter

  PulsingCircleWithNote({
    Key? key,
    this.size = 150.0,
    required this.bpm,
    required this.playing, // Initialize the new parameter
  }) : super(key: key);

  @override
  _PulsingCircleWithNoteState createState() => _PulsingCircleWithNoteState();
}

class _PulsingCircleWithNoteState extends State<PulsingCircleWithNote>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _jumpAnimation;
  Timer? _beatTimer; // Make it nullable to manage lifecycle properly

  late int _beatIntervalMilliseconds;
  late Color _circleColor;

  @override
  void initState() {
    super.initState();

    _circleColor = Colors.blue[400]!;

    // Initialize the beat interval based on the bpm
    _beatIntervalMilliseconds = (60000 / widget.bpm).toInt();

    // Set up the animation controller
    _controller = AnimationController(
      duration: Duration(milliseconds: _beatIntervalMilliseconds),
      vsync: this,
    );

    _jumpAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.playing) {
      _startBeatTimer(); // Start the beat timer if it's playing initially
    }
  }

  void _startBeatTimer() {
    // Initialize the beat timer when playback starts
    if (_beatTimer == null || !_beatTimer!.isActive) {
      _beatTimer = Timer.periodic(
        Duration(milliseconds: _beatIntervalMilliseconds),
        (timer) {
          _controller.forward(from: 0);
          _changeColor();
        },
      );
    }
  }

  void _changeColor() {
    setState(() {
      _circleColor = Colors.red[400]!;
    });

    // Change color back after half the beat duration
    Future.delayed(Duration(milliseconds: _beatIntervalMilliseconds ~/ 2), () {
      setState(() {
        _circleColor = Colors.blue[300]!;
      });
    });
  }

  @override
  void didUpdateWidget(PulsingCircleWithNote oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if the bpm or playing state has changed
    if (oldWidget.bpm != widget.bpm || oldWidget.playing != widget.playing) {
      setState(() {
        _beatIntervalMilliseconds = (60000 / widget.bpm).toInt();
      });

      // Cancel the existing timer and reset the controller
      _beatTimer?.cancel();

      if (widget.playing) {
        _startBeatTimer(); // Restart the timer when playing
      } else {
        _controller.reset(); // Stop the animation when not playing
      }
    }
  }

  @override
  void dispose() {
    // Make sure to cancel the timer and dispose of the controller
    _beatTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.playing) {
          _controller.forward(from: 0); // Start the animation on tap
        }
      },
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.playing ? _jumpAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      size: widget.size * 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
