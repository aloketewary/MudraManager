import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';

/// Grouped settings card with optional dividers between items.
/// Used for settings groups (Core Settings, App Data, Appearance, Advanced).
class SettingsGroupCard extends ConsumerWidget {
  const SettingsGroupCard({
    super.key,
    required this.items,
    this.dividerColor,
  });

  final List<SettingItem> items;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMin, vertical: spacing.elementGap),
      decoration: BoxDecoration(
        // Glassy translucent surface
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: items.asMap().entries.expand((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return [
                item,
                if (!isLast) SizedBox(height: spacing.elementGapMin),
              ];
            }).toList(),
          ),
        ),
      ),
    );
  }
}
