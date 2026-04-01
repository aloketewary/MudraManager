import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

// In spending_prediction_card.dart
// Replace the predictedSpendingProvider watch with dashboardDataProvider

class SpendingPredictionCard extends ConsumerWidget {
  final double globalPadding;
  const SpendingPredictionCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider).valueOrNull;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        .fold<double>(0, (s, t) => s + t.amount);

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
        .fold<double>(0, (s, t) => s + t.amount);

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
      padding: const EdgeInsets.only(top: 16),
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
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOver
                              ? '${pct.toStringAsFixed(0)}% ahead of last month'
                              : '${pct.toStringAsFixed(0)}% under last month',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'On track for ₹${projected.toStringAsFixed(0)} by month end',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: 20,
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
