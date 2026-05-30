import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class TrendIndicator extends StatelessWidget {
  final double current;
  final double previous;
  final bool isIncome;

  const TrendIndicator({
    super.key,
    required this.current,
    required this.previous,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (previous == 0) return const SizedBox.shrink();

    final change = ((current - previous) / previous * 100);
    final isPositive = change > 0;
    final isGood = isIncome ? isPositive : !isPositive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isGood ? color.primary : color.tertiary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            color: isGood ? color.primary : color.tertiary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: textTheme.labelSmall?.copyWith(
              color: isGood ? color.primary : color.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
