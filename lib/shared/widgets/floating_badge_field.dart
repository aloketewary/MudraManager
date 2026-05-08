import 'dart:math';
import 'package:flutter/material.dart';

class FloatingBadgeField extends StatefulWidget {
  final List<String> badgeIcons; // asset names
  final double width;
  final double height;

  const FloatingBadgeField({
    super.key,
    required this.badgeIcons,
    required this.width,
    required this.height,
  });

  @override
  State<FloatingBadgeField> createState() => _FloatingBadgeFieldState();
}

class _FloatingBadgeFieldState extends State<FloatingBadgeField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BadgePlacement> _placements;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _placements = _generatePlacements();
  }

  List<_BadgePlacement> _generatePlacements() {
    final rng = Random(42); // deterministic so it doesn't jump on rebuild
    final count = widget.badgeIcons.length.clamp(0, 8);
    final placements = <_BadgePlacement>[];

    // Place badges in a loose ring, avoiding center (where rank icon sits)
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i / count) + (rng.nextDouble() * 0.4 - 0.2);
      // Radius between 35-45% of half-width to stay away from center and edges
      final radiusFraction = 0.30 + rng.nextDouble() * 0.18;
      final cx = widget.width / 2;
      final cy = widget.height / 2;
      final rx = cx * radiusFraction;
      final ry = cy * radiusFraction * 0.85; // slightly elliptical

      placements.add(
        _BadgePlacement(
          x: cx + rx * cos(angle),
          y: cy + ry * sin(angle),
          phaseOffset: rng.nextDouble() * 2 * pi,
          floatAmplitude: 3.0 + rng.nextDouble() * 4.0,
          size: 32.0 + rng.nextDouble() * 8.0,
          icon: widget.badgeIcons[i],
        ),
      );
    }
    return placements;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_placements.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: _placements.map((p) {
              final t = _controller.value * 2 * pi;
              final dy = sin(t + p.phaseOffset) * p.floatAmplitude;
              final dx =
                  cos(t * 0.7 + p.phaseOffset) * (p.floatAmplitude * 0.3);

              return Positioned(
                left: p.x - p.size / 2 + dx,
                top: p.y - p.size / 2 + dy,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    semanticLabel: 'Decorative image',
                    'assets/icons/100/${p.icon}.png',
                    width: p.size,
                    height: p.size,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BadgePlacement {
  final double x, y, phaseOffset, floatAmplitude, size;
  final String icon;

  const _BadgePlacement({
    required this.x,
    required this.y,
    required this.phaseOffset,
    required this.floatAmplitude,
    required this.size,
    required this.icon,
  });
}
