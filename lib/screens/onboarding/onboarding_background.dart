import 'package:go_router/go_router.dart';
import 'dart:math';

import 'package:flutter/material.dart';

class OnboardingBackground extends StatefulWidget {
  const OnboardingBackground({super.key});

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground> {
  late final List<Offset> _circleCenters;
  late final List<double> _circleRadii;

  @override
  void initState() {
    super.initState();
    _generateCircles();
  }

  void _generateCircles() {
    final random = Random();
    _circleCenters = List.generate(25, (index) {
      return Offset(
        random.nextDouble() * 500, // or screen width approx
        random.nextDouble() * 1000, // or screen height approx
      );
    });

    _circleRadii = List.generate(25, (index) {
      return random.nextDouble() * 30 + 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primary, color.primaryFixed, color.tertiary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: StarPatternPainter(
          circleCenters: _circleCenters,
          circleRadii: _circleRadii,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class StarPatternPainter extends CustomPainter {
  final List<Offset> circleCenters;
  final List<double> circleRadii;

  StarPatternPainter({required this.circleCenters, required this.circleRadii});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < circleCenters.length; i++) {
      canvas.drawCircle(circleCenters[i], circleRadii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
