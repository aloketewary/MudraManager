import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class SpendingPredictionCard extends ConsumerWidget {
  final double globalPadding;
  const SpendingPredictionCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider).value;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final l10n = AppLocalizations.of(context)!;

    if (data == null) return const SizedBox.shrink();

    final now = DateTime.now();
    if (now.day < 3) return const SizedBox.shrink(); // too early

    final txns = data.transactions.where((t) => !t.isTransfer).toList();

    // This month's expense so far
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthExpense = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))),
        )
        .fold<double>(0, (s, t) => s + t.baseAmount);

    // Last month same-day expense
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);
    final lastMonthExpenseToDate = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date
                  .isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
              t.date.isBefore(lastMonthSameDay.add(const Duration(days: 1))),
        )
        .fold<double>(0, (s, t) => s + t.baseAmount);

    if (lastMonthExpenseToDate <= 0) return const SizedBox.shrink();

    final diff = thisMonthExpense - lastMonthExpenseToDate;
    final pct = (diff / lastMonthExpenseToDate * 100).abs();
    final isOver = diff > 0;

    // Project end-of-month
    final dailyRate = thisMonthExpense / now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projected = dailyRate * daysInMonth;

    final accent = isOver ? color.tertiary : color.primary;
    final icon = isOver ? LucideIcons.trendingUp : LucideIcons.trendingDown;

    return Padding(
      padding: EdgeInsets.only(top: spacing.cardVertical),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: globalPadding),
        child: Card(
          elevation: 0,
          color: color.surfaceContainerLow,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.statistics);
            },
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            child: Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(icon, color: accent, size: spacing.iconMD),
                  ),
                  SizedBox(width: spacing.cardInner),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOver
                              ? l10n.dashboard_pctAheadOfLastMonth(
                                  pct.toStringAsFixed(0),
                                )
                              : l10n.dashboard_pctUnderLastMonth(
                                  pct.toStringAsFixed(0),
                                ),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Row(
                          children: [
                            Text(
                              l10n.dashboard_onTrackForPrefix,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            CurrencyText(
                              amount: projected,
                              fixedLength: 0,
                              compact: true,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              l10n.dashboard_byMonthEnd,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: spacing.iconSM,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
