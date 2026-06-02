import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/data/spending_drift_detector.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────
// DAILY BRIEFING — One story. One decision.
// ─────────────────────────────────────────────────────────────

/// A single coherent story about one financial signal.
/// Not three slots. One narrative.
class Briefing {
  final String greeting;
  final String narrative; // the complete story (2-3 sentences, one topic)
  final String balanceLine;
  final String? actionLabel;
  final String? actionRoute;

  const Briefing({
    required this.greeting,
    required this.narrative,
    required this.balanceLine,
    this.actionLabel,
    this.actionRoute,
  });
}

/// Each signal is a self-contained story: what changed, why it matters, what to do.
/// They compete. One wins.
class _Signal {
  final int urgency; // higher wins
  final String narrative;
  final String? actionLabel;
  final String? actionRoute;

  const _Signal({
    required this.urgency,
    required this.narrative,
    this.actionLabel,
    this.actionRoute,
  });
}

final dailyBriefingProvider = Provider<Briefing?>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) return null;

  final now = DateTime.now();
  final isGuest = ref.watch(guestModeProvider);
  final name = ref.watch(userProfileProvider).value?.name ?? '';
  final period = ref.watch(dayPeriodProvider);

  // ── Greeting ──
  final greetText = switch (period) {
    DayPeriod.morning => 'Good morning',
    DayPeriod.afternoon => 'Good afternoon',
    DayPeriod.evening || DayPeriod.night => 'Good evening',
  };
  final greeting = name.isNotEmpty ? '$greetText, $name' : greetText;

  // ── Balance ──
  final balance = GuestModeUtil.applyGuestMode(data.totalBalance, isGuest);
  final balanceLine = 'Available: ${formatCurrencyCompact(balance)}';

  // ── Collect competing signals ──
  final signals = <_Signal>[];
  final txns = data.transactions.where((t) => !t.isTransfer).toList();

  // Signal: Bills due today (urgency 100)
  final billsToday = data.recurringExpenses
      .where((r) => r.nextDueDate.difference(now).inDays == 0)
      .toList();
  if (billsToday.isNotEmpty) {
    final bill = billsToday.first;
    final billName = bill.description ?? 'A bill';
    final amount = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(bill.amount, isGuest),
    );
    signals.add(_Signal(
      urgency: 100,
      narrative: '$billName ($amount) is due today. Pay it now to avoid a missed payment.',
      actionLabel: 'Pay Now',
      actionRoute: AppRoutes.recurringTransactions,
    ));
  }

  // Signal: Budget exceeded (urgency 80)
  if (data.budgets.isNotEmpty) {
    final worst = data.budgets
        .where((b) => b.spent > b.budget.amount)
        .toList()
      ..sort((a, b) =>
          (b.spent - b.budget.amount).compareTo(a.spent - a.budget.amount));
    if (worst.isNotEmpty) {
      final b = worst.first;
      final over = formatCurrencyCompact(
        GuestModeUtil.applyGuestMode(b.spent - b.budget.amount, isGuest),
      );
      signals.add(_Signal(
        urgency: 80,
        narrative:
            '${b.budget.name} is $over over budget. Pause non-essential spending in this category.',
        actionLabel: 'Review',
        actionRoute: AppRoutes.budgetDashboard,
      ));
    }
  }

  // Signal: Spending drift (urgency 70)
  final drifts = detectSpendingDrift(txns);
  if (drifts.isNotEmpty) {
    final drift = drifts.first;
    final cat = drift.title.split(' ').first;
    final pct = drift.title.split(' ').last; // e.g. "38%"
    signals.add(_Signal(
      urgency: 70,
      narrative:
          '$cat spending is $pct above your normal pattern. '
          '${drift.message} Reduce $cat this week.',
      actionLabel: 'View Pattern',
      actionRoute: drift.actionRoute,
    ));
  }

  // Signal: Bills due soon, not today (urgency 60)
  final billsSoon = data.recurringExpenses
      .where((r) {
        final d = r.nextDueDate.difference(now).inDays;
        return d > 0 && d <= 3;
      })
      .toList();
  if (billsSoon.isNotEmpty && billsToday.isEmpty) {
    final bill = billsSoon.first;
    final billName = bill.description ?? 'A bill';
    final days = bill.nextDueDate.difference(now).inDays;
    signals.add(_Signal(
      urgency: 60,
      narrative:
          '$billName is due in $days day${days > 1 ? 's' : ''}. '
          'Make sure you have funds ready.',
      actionLabel: 'View Bills',
      actionRoute: AppRoutes.recurringTransactions,
    ));
  }

  // Signal: Overspending vs income (urgency 50)
  if (data.totalExpense > data.totalIncome && data.totalIncome > 0) {
    final over = data.totalExpense - data.totalIncome;
    final overFmt = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(over, isGuest),
    );
    signals.add(_Signal(
      urgency: 50,
      narrative:
          "You've spent $overFmt more than you earned this month. "
          'Cut discretionary spending to close the gap.',
      actionLabel: 'View Budget',
      actionRoute: AppRoutes.budgetDashboard,
    ));
  }

  // Signal: Positive — month-over-month improvement (urgency 20)
  if (now.day >= 10) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);

    final lastExp = txns
        .where((t) =>
            t.isExpense &&
            t.date.isAfter(
              lastMonthStart.subtract(const Duration(days: 1)),
            ) &&
            t.date.isBefore(
              lastMonthSameDay.add(const Duration(days: 1)),
            ))
        .fold<double>(0, (s, t) => s + t.baseAmount);

    final thisExp = txns
        .where((t) =>
            t.isExpense &&
            t.date.isAfter(
              thisMonthStart.subtract(const Duration(days: 1)),
            ))
        .fold<double>(0, (s, t) => s + t.baseAmount);

    if (lastExp > 0 && thisExp < lastExp * 0.9) {
      final pct = ((lastExp - thisExp) / lastExp * 100).round();
      signals.add(_Signal(
        urgency: 20,
        narrative:
            "You're spending $pct% less than this point last month. Keep it up.",
      ));
    }
  }

  // ── Pick the winner ──
  if (signals.isEmpty) {
    return Briefing(
      greeting: greeting,
      narrative: 'Everything looks good. No action needed today.',
      balanceLine: balanceLine,
    );
  }

  signals.sort((a, b) => b.urgency.compareTo(a.urgency));
  final winner = signals.first;

  return Briefing(
    greeting: greeting,
    narrative: winner.narrative,
    balanceLine: balanceLine,
    actionLabel: winner.actionLabel,
    actionRoute: winner.actionRoute,
  );
});

// ─────────────────────────────────────────────────────────────
// UI — The card itself
// ─────────────────────────────────────────────────────────────

class DailyBriefingCard extends ConsumerWidget {
  const DailyBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(dailyBriefingProvider);
    if (briefing == null) return const SizedBox.shrink();

    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner + 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusLarge),
          color: color.surfaceContainerLow,
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting + Balance ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    briefing.greeting,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap + 2,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    briefing.balanceLine,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.primary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing.sectionGap),

            // ── The story ──
            Text(
              briefing.narrative,
              style: textTheme.bodyLarge?.copyWith(
                color: color.onSurface,
                height: 1.5,
              ),
            ),

            // ── Action ──
            if (briefing.actionRoute != null) ...[
              SizedBox(height: spacing.sectionGap),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(briefing.actionRoute!);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        briefing.actionLabel ?? 'View',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color.primary,
                        ),
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: color.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
