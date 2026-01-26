import 'dart:math';
import 'package:flutter/material.dart';

class DoughnutChart extends StatelessWidget {
  final double percentage; // 0.0 to 1.0 (e.g. 0.85)
  final double score; // Raw score to display (e.g. 85 or 8.5)
  final Color primaryColor;
  final Color backgroundColor;
  final double size;
  final String label;

  const DoughnutChart({
    super.key,
    required this.percentage,
    required this.score,
    this.primaryColor = Colors.cyanAccent,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.size = 100,
    this.label = 'Total Score',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DoughnutPainter(
                  percentage: percentage,
                  primaryColor: primaryColor,
                  backgroundColor: backgroundColor,
                  strokeWidth: 2,
                ),
              ),
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.25, // Slightly larger as it's alone now
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color backgroundColor;
  final double strokeWidth;

  _DoughnutPainter({
    required this.percentage,
    required this.primaryColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground Arc
    final fgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    
    // Start from top (-90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
