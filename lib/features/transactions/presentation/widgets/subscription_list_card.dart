import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/transactions/data/subscription_detector_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class SubscriptionListCard extends ConsumerWidget {
  const SubscriptionListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detectedSubscriptionsProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();

        final monthlyTotal = subs.fold<double>(
          0,
          (sum, s) => sum + s.monthlyTotal,
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardInner,
                    spacing.cardInner,
                    spacing.cardInner,
                    spacing.elementGap,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.repeat,
                        size: 18,
                        color: color.primary,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Text(
                          ctxt.subscription_title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Text(
                          ctxt.subscription_monthlyTotal(
                            formatCurrency(
                              monthlyTotal,
                              code: BaseCurrency.code,
                              decimals: 0,
                            ),
                          ),
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                ...subs.take(5).map(
                      (sub) => _SubscriptionRow(sub: sub),
                    ),
                SizedBox(height: spacing.elementGap),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubscriptionRow extends ConsumerWidget {
  final DetectedSubscription sub;
  const _SubscriptionRow({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.cardVerticalMin,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(
              LucideIcons.receipt,
              size: 16,
              color: color.primary,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub.estimatedDayOfMonth != null
                      ? ctxt.subscription_dayOfMonth(sub.estimatedDayOfMonth!)
                      : ctxt.subscription_occurrences(sub.occurrences),
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CurrencyText(
            amount: sub.avgAmount,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.error,
            ),
          ),
        ],
      ),
    );
  }
}
