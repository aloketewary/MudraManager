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
    
    if (previous == 0) return SizedBox.shrink();
    
    final change = ((current - previous) / previous * 100);
    final isPositive = change > 0;
    final isGood = isIncome ? isPositive : !isPositive;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isGood ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isGood ? Colors.green : Colors.red,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: textTheme.labelSmall?.copyWith(
              color: isGood ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
