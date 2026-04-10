import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class TransactionTagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onDeleted;

  const TransactionTagChip({
    super.key,
    required this.label,
    this.color,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      deleteIcon: onDeleted != null ? Icon(LucideIcons.x, size: 16, color: chipColor) : null,
      onDeleted: onDeleted,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
    );
  }
}
