import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/data/financial_regime_provider.dart';
import 'package:mudra_manager/features/dashboard/data/spending_drift_detector.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/ai_insight_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/hero_moment_card.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────
// DAILY BRIEFING — One story. One decision.
// ─────────────────────────────────────────────────────────────

/// Signal types for structured l10n formatting in the widget.
enum BriefingSignalType {
  billDueToday,
  budgetExceeded,
  spendingDrift,
  billDueSoon,
  overspending,
  improvement,
}

/// A single coherent story about one financial signal.
class Briefing {
  final String nameForGreeting;
  final DayPeriod period;
  final double balance;
  final BriefingSignalType signalType;
  final Map<String, dynamic> params; // signal-specific params for l10n
  final String? actionRoute;

  const Briefing({
    required this.nameForGreeting,
    required this.period,
    required this.balance,
    required this.signalType,
    required this.params,
    this.actionRoute,
  });
}

/// Each signal is a self-contained story: what changed, why it matters, what to do.
/// They compete. One wins.
class _Signal {
  final int urgency;
  final BriefingSignalType type;
  final Map<String, dynamic> params;
  final String? actionRoute;

  const _Signal({
    required this.urgency,
    required this.type,
    required this.params,
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

  // ── Balance ──
  final balance = GuestModeUtil.applyGuestMode(data.totalBalance, isGuest);

  // ── Regime: determines which signals are admissible ──
  final regime = ref.watch(financialRegimeProvider);

  // ── Collect competing signals (regime-gated) ──
  final signals = <_Signal>[];
  final txns = data.transactions.where((t) => !t.isTransfer).toList();

  // Signal: Bills due today (urgency 100)
  final billsToday = data.recurringExpenses
      .where((r) => r.nextDueDate.difference(now).inDays == 0)
      .toList();
  if (billsToday.isNotEmpty) {
    final bill = billsToday.first;
    final rawName = bill.description ?? '';
    final billName = rawName.isEmpty
        ? (bill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawName, bill.category.value?.name ?? 'Bill',);
    final amount = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(bill.amount, isGuest),
    );
    signals.add(_Signal(
      urgency: 100,
      type: BriefingSignalType.billDueToday,
      params: {'name': billName, 'amount': amount},
      actionRoute: AppRoutes.recurringTransactions,
    ),);
  }

  // Signal: Budget exceeded (urgency 80)
  if (data.budgets.isNotEmpty) {
    final worst = data.budgets
        .where((b) => b.spent > b.budget.amount)
        .toList()
      ..sort((a, b) =>
          (b.spent - b.budget.amount).compareTo(a.spent - a.budget.amount),);
    if (worst.isNotEmpty) {
      final b = worst.first;
      final over = formatCurrencyCompact(
        GuestModeUtil.applyGuestMode(b.spent - b.budget.amount, isGuest),
      );
      signals.add(_Signal(
        urgency: 80,
        type: BriefingSignalType.budgetExceeded,
        params: {'name': b.budget.name, 'amount': over},
        actionRoute: AppRoutes.budgetDashboard,
      ),);
    }
  }

  // Signal: Spending drift (urgency 70) — requires spending depth ≥ 3
  final drifts = regime.spendingDepthMonths >= 3
      ? detectSpendingDrift(txns)
      : <AiInsight>[];
  if (drifts.isNotEmpty) {
    final drift = drifts.first;
    final cat = drift.title.split(' ').first;
    final pct = drift.title.split(' ').last;
    signals.add(_Signal(
      urgency: 70,
      type: BriefingSignalType.spendingDrift,
      params: {'category': cat, 'percent': pct},
      actionRoute: drift.actionRoute,
    ),);
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
    final rawSoonName = bill.description ?? '';
    final billName = rawSoonName.isEmpty
        ? (bill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawSoonName, bill.category.value?.name ?? 'Bill',);
    final days = bill.nextDueDate.difference(now).inDays;
    signals.add(_Signal(
      urgency: 60,
      type: BriefingSignalType.billDueSoon,
      params: {'name': billName, 'days': days},
      actionRoute: AppRoutes.recurringTransactions,
    ),);
  }

  // Signal: Overspending vs income (urgency 50) — requires regular income
  if (regime.hasRegularIncome &&
      data.totalExpense > data.totalIncome &&
      data.totalIncome > 0) {
    final over = data.totalExpense - data.totalIncome;
    final overFmt = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(over, isGuest),
    );
    signals.add(_Signal(
      urgency: 50,
      type: BriefingSignalType.overspending,
      params: {'amount': overFmt},
      actionRoute: AppRoutes.budgetDashboard,
    ),);
  }

  // Signal: Positive — month-over-month improvement (urgency 20) — requires depth ≥ 2
  if (regime.spendingDepthMonths >= 2 && now.day >= 10) {
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
            ),)
        .fold<double>(0, (s, t) => s + t.baseAmount);

    final thisExp = txns
        .where((t) =>
            t.isExpense &&
            t.date.isAfter(
              thisMonthStart.subtract(const Duration(days: 1)),
            ),)
        .fold<double>(0, (s, t) => s + t.baseAmount);

    if (lastExp > 0 && thisExp < lastExp * 0.9) {
      final pct = ((lastExp - thisExp) / lastExp * 100).round();
      signals.add(_Signal(
        urgency: 20,
        type: BriefingSignalType.improvement,
        params: {'percent': pct},
      ),);
    }
  }

  // ── Pick the winner ──
  if (signals.isEmpty) return null;

  signals.sort((a, b) => b.urgency.compareTo(a.urgency));
  final winner = signals.first;

  return Briefing(
    nameForGreeting: name,
    period: period,
    balance: balance,
    signalType: winner.type,
    params: winner.params,
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
    final l10n = AppLocalizations.of(context)!;

    // ── Format greeting with l10n ──
    final greetText = switch (briefing.period) {
      DayPeriod.morning => l10n.greeting_good_morning_text,
      DayPeriod.afternoon => l10n.greeting_good_afternoon_text,
      DayPeriod.evening || DayPeriod.night => l10n.greeting_good_evening_text,
    };
    final greeting = briefing.nameForGreeting.isNotEmpty
        ? l10n.briefing_greetingWithName(greetText, briefing.nameForGreeting)
        : greetText;

    // ── Format balance line ──
    final balanceLine = l10n.briefing_available(
      formatCurrencyCompact(briefing.balance),
    );

    // ── Format narrative from signal type ──
    final narrative = _formatNarrative(l10n, briefing);
    final actionLabel = _formatActionLabel(l10n, briefing);

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
                    greeting,
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
                    balanceLine,
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
              narrative,
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
                        actionLabel,
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

  String _formatNarrative(AppLocalizations l10n, Briefing b) {
    return switch (b.signalType) {
      BriefingSignalType.billDueToday => l10n.briefing_billDueToday(
          b.params['name'] as String, b.params['amount'] as String,),
      BriefingSignalType.budgetExceeded => l10n.briefing_budgetExceeded(
          b.params['name'] as String, b.params['amount'] as String,),
      BriefingSignalType.spendingDrift => l10n.briefing_spendingDrift(
          b.params['category'] as String, b.params['percent'] as String,),
      BriefingSignalType.billDueSoon => l10n.briefing_billDueSoon(
          b.params['name'] as String, b.params['days'] as int,),
      BriefingSignalType.overspending => l10n.briefing_overspending(
          b.params['amount'] as String,),
      BriefingSignalType.improvement => l10n.briefing_improvement(
          b.params['percent'] as int,),
    };
  }

  String _formatActionLabel(AppLocalizations l10n, Briefing b) {
    return switch (b.signalType) {
      BriefingSignalType.billDueToday => l10n.briefing_payNow,
      BriefingSignalType.budgetExceeded => l10n.briefing_review,
      BriefingSignalType.spendingDrift => l10n.briefing_viewPattern,
      BriefingSignalType.billDueSoon => l10n.briefing_viewBills,
      BriefingSignalType.overspending => l10n.briefing_viewBudget,
      BriefingSignalType.improvement => l10n.briefing_review,
    };
  }
}

// ─────────────────────────────────────────────────────────────
// UNIFIED CARD — One slot. Briefing or Hero. Never both.
// ─────────────────────────────────────────────────────────────

/// Renders DailyBriefingCard when a signal fires,
/// HeroMomentCard when the system is silent.
/// One plugin, one slot, adapts to state.
class UnifiedBriefingCard extends ConsumerWidget {
  const UnifiedBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(dailyBriefingProvider);

    if (briefing != null) {
      return const DailyBriefingCard();
    }

    // No signal — show Hero moment (positive reinforcement on quiet days)
    return const HeroMomentCard();
  }
}
