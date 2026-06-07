import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';

class SpendingTagsSection extends ConsumerWidget {
  final String periodKey;

  const SpendingTagsSection({
    super.key,
    required this.periodKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    // Translate UI period to internal period string
    final period = periodKey.contains('_') ? 'Month' : periodKey;
    final tagSpendingAsync = ref.watch(tagSpendingProvider(period));

    return tagSpendingAsync.when(
      data: (tagSpendings) {
        if (tagSpendings.isEmpty) return const SizedBox.shrink();
        final maxAmount = tagSpendings.first.amount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.stats_spendingByTag,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(),
              color: color.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                side: BorderSide(
                  color: color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Column(
                  children: tagSpendings.take(8).map((ts) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.tag,
                                    size: 16,
                                    color: color.tertiary,
                                  ),
                                  SizedBox(width: spacing.elementGap),
                                  Text(
                                    ts.tag.name,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CurrencyText(
                                    amount: ts.amount,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: spacing.elementGap),
                                  Text(
                                    '${ts.count} txn',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.elementGap),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              semanticsLabel: 'Progress',
                              value: (ts.amount / maxAmount).clamp(0.0, 1.0),
                              backgroundColor: color.surfaceContainerHighest,
                              color: color.tertiary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const InlineError(),
    );
  }
}
