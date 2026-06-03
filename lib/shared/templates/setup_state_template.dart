import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Template C — Setup State
///
/// Used for: onboarding, empty budgets, no SMS data, insufficient gate.
/// Structure:
///   - Icon or illustration
///   - Title + description
///   - Optional checklist with progress
///   - Single CTA
///
/// No decoration. No motivation. Just structure.
class SetupStateTemplate extends ConsumerWidget {
  /// Icon shown at top.
  final IconData icon;

  /// Primary title.
  final String title;

  /// Description text.
  final String description;

  /// Optional checklist items.
  final List<SetupCheckItem> checklist;

  /// Primary call-to-action.
  final String ctaLabel;

  /// CTA callback.
  final VoidCallback onCta;

  /// Optional secondary action.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const SetupStateTemplate({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.checklist = const [],
    required this.ctaLabel,
    required this.onCta,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final completedCount = checklist.where((c) => c.done).length;
    final progress = checklist.isNotEmpty
        ? completedCount / checklist.length
        : 0.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(icon, size: 56, color: color.primary),
            SizedBox(height: spacing.sectionGap),

            // Title
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.elementGap),

            // Description
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Checklist
            if (checklist.isNotEmpty) ...[
              SizedBox(height: spacing.sectionGap),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: color.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(color.primary),
                ),
              ),
              SizedBox(height: spacing.elementGap),

              // Items
              ...checklist.map((item) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                    child: Row(
                      children: [
                        Icon(
                          item.done
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 18,
                          color: item.done
                              ? color.primary
                              : color.onSurfaceVariant,
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Text(
                            item.label,
                            style: textTheme.bodyMedium?.copyWith(
                              color: item.done
                                  ? color.onSurface
                                  : color.onSurfaceVariant,
                              decoration:
                                  item.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),),
            ],

            SizedBox(height: spacing.sectionGap),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCta,
                child: Text(ctaLabel),
              ),
            ),

            // Secondary action
            if (secondaryLabel != null && onSecondary != null) ...[
              SizedBox(height: spacing.elementGap),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single checklist item for setup progress.
class SetupCheckItem {
  final String label;
  final bool done;

  const SetupCheckItem({required this.label, required this.done});
}
