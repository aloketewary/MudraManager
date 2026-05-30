import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade300, Colors.lightGreen.shade100], // Example gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Tone.current.borderRadius * 2)), // Optional rounded bottom
      ),
      padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[

              Text(
                'Payday in a week',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Total balance to spend',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$5785.55',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          // You can add the "Planning Ahead" section below using a Row or other widgets
        ],
      ),
    );
  }
}