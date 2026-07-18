import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Section header with accent bar and gradient icon container.
///
/// Usage:
/// ```dart
/// TypeSectionHeader(
///   label: 'Details',
///   icon: LucideIcons.form,
///   accentColor: _selectedColor,
/// )
/// ```
class TypeSectionHeader extends ConsumerWidget {
  final String label;
  final IconData icon;
  final Color accentColor;

  const TypeSectionHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch<AppSpacing>(spacingProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: spacing.elementGapMin,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(spacing.elementGapMin / 2),
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          // Icon container
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          SizedBox(width: spacing.elementGap),
          // Label
          Expanded(
            child: Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}