import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Template D — Detail Inspection
///
/// Used for: transaction detail, budget detail, account detail.
/// Structure:
///   - Single entity header (name, primary value)
///   - Breakdown sections (key-value pairs)
///   - No competing signals
///   - Optional action bar in AppBar
///
/// This template ONLY renders. No logic.
class DetailInspectionTemplate extends ConsumerWidget {
  /// Header widget (entity name, icon, primary value).
  final Widget header;

  /// Breakdown sections. Each is a titled group of key-value rows.
  final List<DetailSection> sections;

  /// Whether data is loading.
  final bool isLoading;

  /// Optional loading placeholder.
  final Widget? loadingWidget;

  const DetailInspectionTemplate({
    super.key,
    required this.header,
    required this.sections,
    this.isLoading = false,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return loadingWidget ?? const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          header,
          SizedBox(height: spacing.sectionGap),

          // Sections
          ...sections.map((section) => Padding(
                padding: EdgeInsets.only(bottom: spacing.sectionGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (section.title != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing.elementGap),
                        child: Text(
                          section.title!,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: color.surfaceContainerLow,
                        border: Border.all(color: color.outlineVariant),
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                      child: Column(
                        children: section.rows.asMap().entries.map((entry) {
                          final row = entry.value;
                          final isLast = entry.key == section.rows.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.cardInner,
                                  vertical: spacing.elementGap,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      row.label,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    Flexible(child: row.value),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: spacing.cardInner,
                                  endIndent: spacing.cardInner,
                                  color: color.outlineVariant.withValues(alpha: 0.5),
                                ),
                            ],
                          );
                        },).toList(),
                      ),
                    ),
                  ],
                ),
              ),),
        ],
      ),
    );
  }
}

/// A titled group of key-value rows.
class DetailSection {
  final String? title;
  final List<DetailRow> rows;

  const DetailSection({this.title, required this.rows});
}

/// A single key-value row in a detail section.
class DetailRow {
  final String label;
  final Widget value;

  const DetailRow({required this.label, required this.value});
}
