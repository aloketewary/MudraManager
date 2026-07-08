import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

// ─────────────────────────────────────────────────────────────
// HEALTH STRIP — Domain-level attention orientation
// Only shows domains needing attention. Hidden when all clear.
// ─────────────────────────────────────────────────────────────

/// Attention counts per financial domain.
class HealthStripState {
  final int budgets;
  final int bills;
  final int goals;
  final int cards;

  const HealthStripState({
    required this.budgets,
    required this.bills,
    required this.goals,
    required this.cards,
  });

  bool get allClear => budgets == 0 && bills == 0 && goals == 0 && cards == 0;
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final healthStripProvider = Provider<HealthStripState>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) {
    return const HealthStripState(
      budgets: 0,
      bills: 0,
      goals: 0,
      cards: 0,
    );
  }

  final now = DateTime.now();

  // ── Budgets: breached (spent > amount) ──
  final budgetsAttention =
      data.budgets.where((b) => b.spent > b.budget.amount).length;

  // ── Bills: non-credit-card recurring due within 7 days ──
  // Domain ownership: Bills = utilities, rent, subscriptions, EMIs
  // Cards get their own domain.
  final billsAttention = data.recurringExpenses.where((r) {
    final daysUntil = r.nextDueDate.difference(now).inDays;
    if (daysUntil < 0 || daysUntil > 7) return false;
    // Exclude bills linked to credit card accounts
    final account = r.account.value;
    if (account?.accountType == AccountType.creditCard) return false;
    return true;
  }).length;

  // ── Cards: due within 7 days OR utilization > 80% ──
  final creditCards = data.accounts
      .where((a) => a.accountType == AccountType.creditCard && a.isActive)
      .toList();
  int cardsAttention = 0;
  for (final card in creditCards) {
    // Due date check
    if (card.dueDay != null) {
      final dueThisMonth = DateTime(now.year, now.month, card.dueDay!);
      final dueDate =
          dueThisMonth.isBefore(now) && now.day > card.dueDay!
              ? DateTime(now.year, now.month + 1, card.dueDay!)
              : dueThisMonth;
      final daysUntilDue = dueDate.difference(now).inDays;
      if (daysUntilDue >= 0 && daysUntilDue <= 7) {
        cardsAttention++;
        continue;
      }
    }
    // Utilization check
    if (card.creditLimit != null && card.creditLimit! > 0) {
      final balance = data.accountBalances[card.id] ?? 0;
      final utilization = balance / card.creditLimit!;
      if (utilization > 0.8) {
        cardsAttention++;
      }
    }
  }

  // ── Goals: active + current pace cannot reach target ──
  int goalsAttention = 0;
  for (final goal in data.goals) {
    if (!goal.isActive) continue;
    if (goal.targetDate == null) continue;
    if (goal.currentAmount >= goal.targetAmount) continue;

    final remaining = goal.targetAmount - goal.currentAmount;
    final monthsLeft = goal.targetDate!.difference(now).inDays / 30.0;
    if (monthsLeft <= 0) {
      // Past deadline with remaining amount = attention
      goalsAttention++;
      continue;
    }

    final neededPerMonth = remaining / monthsLeft;

    // Calculate recent pace (last 90 days)
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final recentContributions = goal.contributions
        .where((c) => c.date.isAfter(ninetyDaysAgo))
        .fold<double>(0, (sum, c) => sum + c.amount);
    final recentPace = recentContributions / 3; // per month

    // Only flag if pace is insufficient (can't reach target)
    if (recentPace < neededPerMonth * 0.7) {
      goalsAttention++;
    }
  }

  return HealthStripState(
    budgets: budgetsAttention,
    bills: billsAttention,
    goals: goalsAttention,
    cards: cardsAttention,
  );
});

// ─────────────────────────────────────────────────────────────
// UI — Horizontal chip row (only attention domains)
// ─────────────────────────────────────────────────────────────

class HealthStrip extends ConsumerWidget {
  const HealthStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthStripProvider);

    // All clear → don't render
    if (state.allClear) return const SizedBox.shrink();

    final spacing = ref.watch(spacingProvider);
    final l10n = AppLocalizations.of(context)!;

    final chips = <_ChipData>[];

    if (state.budgets > 0) {
      chips.add(_ChipData(
        label: l10n.health_budgets,
        count: state.budgets,
        route: AppRoutes.budgetDashboard,
        icon: LucideIcons.chartPie,
      ),);
    }
    if (state.bills > 0) {
      chips.add(_ChipData(
        label: l10n.health_bills,
        count: state.bills,
        route: AppRoutes.recurringTransactions,
        icon: LucideIcons.receipt,
      ),);
    }
    if (state.goals > 0) {
      chips.add(_ChipData(
        label: l10n.health_goals,
        count: state.goals,
        route: AppRoutes.goalScreen,
        icon: LucideIcons.target,
      ),);
    }
    if (state.cards > 0) {
      chips.add(_ChipData(
        label: l10n.health_cards,
        count: state.cards,
        route: AppRoutes.manageAccounts,
        icon: LucideIcons.creditCard,
      ),);
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Wrap(
        spacing: spacing.elementGap,
        runSpacing: spacing.elementGapMin,
        children: chips.map((chip) => _buildChip(context, ref, chip)).toList(),
      ),
    );
  }

  Widget _buildChip(BuildContext context, WidgetRef ref, _ChipData chip) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        TodayCardAnalytics.recordDestinationOpened(
          destination: 'healthStrip_${chip.label.toLowerCase()}',
        );
        context.push(chip.route);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap + 2,
          vertical: spacing.elementGapMin + 2,
        ),
        decoration: BoxDecoration(
          color: color.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(
            color: color.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chip.icon,
              size: 14,
              color: color.error,
            ),
            SizedBox(width: spacing.elementGapMin),
            Text(
              '${chip.label} ${chip.count}',
              style: textTheme.labelSmall?.copyWith(
                color: color.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final int count;
  final String route;
  final IconData icon;

  const _ChipData({
    required this.label,
    required this.count,
    required this.route,
    required this.icon,
  });
}
