import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

import 'package:mudra_manager/core/widgets/skeleton_loader.dart';

/// Quick stat item: icon + value + label in a column layout.
/// Used in quick stats rows (profile, dashboard widgets).
class QuickStatItem extends ConsumerWidget {
  const QuickStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
    this.loading = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final c = accentColor ?? color.primary;

    return Column(
      children: [
        Icon(icon, color: c, size: 18),
        SizedBox(height: spacing.elementGapMin),
        if (loading)
          Container(
            width: 40,
            height: 18,
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(spacing.radiusSmall / 2),
            ),
            child: const SkeletonLoader(width: 40, height: 18),
          )
        else
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
