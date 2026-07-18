import 'package:flutter/material.dart';

/// Signature accent for hero currency amounts.
///
/// A soft radial glow sits behind the primary number on a card's focal
/// amount (net worth, today's balance, income/expense totals). It's the
/// one decorative flourish a "money-first" screen can afford — subtle
/// enough not to compete with the number, present enough to feel crafted.
///
/// Usage: wrap the amount widget (usually [AnimatedBalance]) directly.
/// Do not use on secondary/metric numbers — one glow per card, on the
/// number the user actually came to check.
class AmountGlow extends StatelessWidget {
  final Widget child;
  final Color color;

  /// Relative glow size vs. child bounds. 1.6-2.2 reads as a soft halo
  /// without bleeding into neighboring content.
  final double spread;

  const AmountGlow({
    super.key,
    required this.child,
    required this.color,
    this.spread = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: spread,
            heightFactor: spread,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
