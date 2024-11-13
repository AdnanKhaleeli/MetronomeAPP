import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

class CircularBPMIndicator extends StatelessWidget {
  final double currentBpm;
  final double goalBpm;
  final double savedBpm;

  CircularBPMIndicator({
    required this.currentBpm,
    required this.goalBpm,
    required this.savedBpm,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200), // size of the circle
      painter: BPMIndicatorPainter(
          currentBpm: currentBpm, goalBpm: goalBpm, savedBpm: savedBpm),
    );
  }
}

class BPMIndicatorPainter extends CustomPainter {
  final double currentBpm;
  final double goalBpm;
  final double savedBpm;

  BPMIndicatorPainter({
    required this.currentBpm,
    required this.goalBpm,
    required this.savedBpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    double goalAngleStart = -pi / 2; 
    double fullCircle = 2 * pi;


    double bpmRange = goalBpm - 40;

  
    paint.color = const Color.fromARGB(255, 255, 79, 66)
        .withOpacity(0.8); 
    double goalSweepAngle =
        fullCircle; 
    canvas.drawArc(
        Offset(0, 0) & size, goalAngleStart, goalSweepAngle, false, paint);

   
    double currentSweepAngle = 0.0;
    if (currentBpm > 40) {
      currentSweepAngle = fullCircle *
          ((currentBpm - 40) / bpmRange); 
    }

    paint.color =  Colors.yellow.withOpacity(0.8);
    paint.strokeWidth = 14; 
    canvas.drawArc(  Offset(0, 0) & size, goalAngleStart, currentSweepAngle, false, paint);

    
    double savedSweepAngle = 0.0;
    if (savedBpm > 40) {
      savedSweepAngle = fullCircle *
          ((savedBpm - 40) / bpmRange); 
    }

    paint.color = const Color.fromARGB(255, 0, 194, 6)
        .withOpacity(1); // Color for saved BPM (green)
    paint.strokeWidth = 10; // Normal thickness for saved BPM
    canvas.drawArc(
        Offset(0, 0) & size, goalAngleStart, savedSweepAngle, false, paint);

    
    if (savedBpm == -1 || currentBpm >= goalBpm) {
      // -1 means 'N/A' BPM
      TextSpan span = TextSpan(
        style: TextStyle(
            fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        text: '✓', // Check mark
      );
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(
          canvas,
          Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
    } else {
  
      TextSpan span = TextSpan(
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        text: '${currentBpm.toInt()} BPM',
      );
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(
          canvas,
          Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
