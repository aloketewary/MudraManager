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
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────
// TODAY CARD — System's daily financial assessment
// Always renders. Never disappears.
// ─────────────────────────────────────────────────────────────

/// The card's three possible maturity states.
enum TodayCardMaturity {
  /// No recurring bills set up — show balance only
  stage0,

  /// Has bills — can compute "remaining after upcoming bills"
  stage1,
}

/// Signal types for the warning state.
enum BriefingSignalType {
  billDueToday,
  budgetExceeded,
  spendingDrift,
  billDueSoon,
  overspending,
  improvement,
}

/// The complete state for rendering the Today Card.
class TodayCardState {
  final TodayCardMaturity maturity;
  final double balance;
  final double upcomingBillsTotal;
  final double remainingAfterBills;

  /// Next upcoming bill info (name + days until due)
  final String? nextBillName;
  final int? nextBillDays;

  /// Warning signal (null = healthy state)
  final BriefingSignalType? signalType;
  final Map<String, dynamic> signalParams;
  final String? actionRoute;

  const TodayCardState({
    required this.maturity,
    required this.balance,
    required this.upcomingBillsTotal,
    required this.remainingAfterBills,
    this.nextBillName,
    this.nextBillDays,
    this.signalType,
    this.signalParams = const {},
    this.actionRoute,
  });

  bool get isHealthy => signalType == null;
  bool get hasUpcomingBills => maturity == TodayCardMaturity.stage1;
}

// ─────────────────────────────────────────────────────────────
// PROVIDER — Computes TodayCardState from dashboard data
// ─────────────────────────────────────────────────────────────

final todayCardProvider = Provider<TodayCardState?>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) return null;

  final now = DateTime.now();
  final isGuest = ref.watch(guestModeProvider);
  final regime = ref.watch(financialRegimeProvider);

  // ── Balance ──
  final balance = GuestModeUtil.applyGuestMode(data.totalBalance, isGuest);

  // ── Upcoming bills (next 30 days, active expenses only) ──
  final upcomingBills = data.recurringExpenses.where((r) {
    final daysUntil = r.nextDueDate.difference(now).inDays;
    return daysUntil >= 0 && daysUntil <= 30;
  }).toList();

  final upcomingBillsTotal = GuestModeUtil.applyGuestMode(
    upcomingBills.fold<double>(0, (sum, r) => sum + r.amount),
    isGuest,
  );

  // ── Maturity gate ──
  final hasAnyActiveBills = data.recurringExpenses.isNotEmpty;
  final maturity =
      hasAnyActiveBills ? TodayCardMaturity.stage1 : TodayCardMaturity.stage0;

  final remainingAfterBills = balance - upcomingBillsTotal;

  // ── Next bill context ──
  String? nextBillName;
  int? nextBillDays;

  if (upcomingBills.isNotEmpty) {
    final sorted = List.of(upcomingBills)
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final next = sorted.first;
    final rawName = next.description ?? '';
    nextBillName = rawName.isEmpty
        ? (next.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawName,
            next.category.value?.name ?? 'Bill',
          );
    nextBillDays = next.nextDueDate.difference(now).inDays;
  }

  // ── Signal competition (reuses existing logic) ──
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
            rawName,
            bill.category.value?.name ?? 'Bill',
          );
    final amount = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(bill.amount, isGuest),
    );
    signals.add(
      _Signal(
        urgency: 100,
        type: BriefingSignalType.billDueToday,
        params: {'name': billName, 'amount': amount},
        actionRoute: AppRoutes.recurringTransactions,
      ),
    );
  }

  // Signal: Budget exceeded (urgency 80)
  if (data.budgets.isNotEmpty) {
    final worst = data.budgets.where((b) => b.spent > b.budget.amount).toList()
      ..sort(
        (a, b) =>
            (b.spent - b.budget.amount).compareTo(a.spent - a.budget.amount),
      );
    if (worst.isNotEmpty) {
      final b = worst.first;
      final over = formatCurrencyCompact(
        GuestModeUtil.applyGuestMode(b.spent - b.budget.amount, isGuest),
      );
      signals.add(
        _Signal(
          urgency: 80,
          type: BriefingSignalType.budgetExceeded,
          params: {'name': b.budget.name, 'amount': over},
          actionRoute: AppRoutes.budgetDashboard,
        ),
      );
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
    signals.add(
      _Signal(
        urgency: 70,
        type: BriefingSignalType.spendingDrift,
        params: {'category': cat, 'percent': pct},
        actionRoute: drift.actionRoute,
      ),
    );
  }

  // Signal: Bills due soon, not today (urgency 60)
  final billsSoon = data.recurringExpenses.where((r) {
    final d = r.nextDueDate.difference(now).inDays;
    return d > 0 && d <= 3;
  }).toList();
  if (billsSoon.isNotEmpty && billsToday.isEmpty) {
    final bill = billsSoon.first;
    final rawSoonName = bill.description ?? '';
    final billName = rawSoonName.isEmpty
        ? (bill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawSoonName,
            bill.category.value?.name ?? 'Bill',
          );
    final days = bill.nextDueDate.difference(now).inDays;
    signals.add(
      _Signal(
        urgency: 60,
        type: BriefingSignalType.billDueSoon,
        params: {'name': billName, 'days': days},
        actionRoute: AppRoutes.recurringTransactions,
      ),
    );
  }

  // Signal: Overspending vs income (urgency 50) — requires regular income
  if (regime.hasRegularIncome &&
      data.totalExpense > data.totalIncome &&
      data.totalIncome > 0) {
    final over = data.totalExpense - data.totalIncome;
    final overFmt = formatCurrencyCompact(
      GuestModeUtil.applyGuestMode(over, isGuest),
    );
    signals.add(
      _Signal(
        urgency: 50,
        type: BriefingSignalType.overspending,
        params: {'amount': overFmt},
        actionRoute: AppRoutes.budgetDashboard,
      ),
    );
  }

  // Signal: Positive — month-over-month improvement (urgency 20)
  if (regime.spendingDepthMonths >= 2 && now.day >= 10) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);

    final lastExp = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date.isAfter(
                lastMonthStart.subtract(const Duration(days: 1)),
              ) &&
              t.date.isBefore(
                lastMonthSameDay.add(const Duration(days: 1)),
              ),
        )
        .fold<double>(0, (s, t) => s + t.baseAmount);

    final thisExp = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date.isAfter(
                thisMonthStart.subtract(const Duration(days: 1)),
              ),
        )
        .fold<double>(0, (s, t) => s + t.baseAmount);

    if (lastExp > 0 && thisExp < lastExp * 0.9) {
      final pct = ((lastExp - thisExp) / lastExp * 100).round();
      signals.add(
        _Signal(
          urgency: 20,
          type: BriefingSignalType.improvement,
          params: {'percent': pct},
        ),
      );
    }
  }

  // ── Pick the winner ──
  signals.sort((a, b) => b.urgency.compareTo(a.urgency));
  final winner = signals.isNotEmpty ? signals.first : null;

  return TodayCardState(
    maturity: maturity,
    balance: balance,
    upcomingBillsTotal: upcomingBillsTotal,
    remainingAfterBills: remainingAfterBills,
    nextBillName: nextBillName,
    nextBillDays: nextBillDays,
    signalType: winner?.type,
    signalParams: winner?.params ?? const {},
    actionRoute: winner?.actionRoute,
  );
});

/// Internal signal model for competition.
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

// ─────────────────────────────────────────────────────────────
// LEGACY COMPATIBILITY — Keep old provider alive for
// ai_insight_provider.dart which depends on it
// ─────────────────────────────────────────────────────────────

/// Legacy Briefing model (kept for backward compat with ai_insight_provider)
class Briefing {
  final String nameForGreeting;
  final DayPeriod period;
  final double balance;
  final BriefingSignalType signalType;
  final Map<String, dynamic> params;
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

/// Legacy provider — now derived from todayCardProvider for backward compat.
final dailyBriefingProvider = Provider<Briefing?>((ref) {
  final state = ref.watch(todayCardProvider);
  if (state == null || state.isHealthy) return null;

  final period = ref.watch(dayPeriodProvider);

  return Briefing(
    nameForGreeting: '',
    period: period,
    balance: state.balance,
    signalType: state.signalType!,
    params: state.signalParams,
    actionRoute: state.actionRoute,
  );
});

// ─────────────────────────────────────────────────────────────
// UI — The Today Card (always renders)
// ─────────────────────────────────────────────────────────────

/// Entry point widget registered in the plugin system.
/// Always renders — never returns SizedBox.shrink.
class UnifiedBriefingCard extends ConsumerStatefulWidget {
  const UnifiedBriefingCard({super.key});

  @override
  ConsumerState<UnifiedBriefingCard> createState() =>
      _UnifiedBriefingCardState();
}

class _UnifiedBriefingCardState extends ConsumerState<UnifiedBriefingCard> {
  bool _hasRecordedImpression = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayCardProvider);
    if (state == null) return const SizedBox.shrink(); // data still loading

    // Record impression once per widget lifecycle
    if (!_hasRecordedImpression) {
      _hasRecordedImpression = true;
      if (state.isHealthy) {
        TodayCardAnalytics.recordCardShownHealthy();
        // Detect natural dismissal: previous session had alert, now healthy
        final lastSignal = TodayCardAnalytics.getLastAlertSignal();
        if (lastSignal != null &&
            !TodayCardAnalytics.hasInteractionAfterLastAlert()) {
          TodayCardAnalytics.recordAlertDismissedNaturally(
            signalType: lastSignal,
          );
        }
      } else {
        TodayCardAnalytics.recordCardShownAlert(
          signalType: state.signalType!,
          metadata: state.signalParams.map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );
      }
    }

    return TodayCard(state: state);
  }
}

/// The permanent Today Card.
class TodayCard extends ConsumerWidget {
  final TodayCardState state;

  const TodayCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner + 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          color: color.surfaceContainerLow,
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── "TODAY" label ──
            Text(
              l10n.today_label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            SizedBox(height: spacing.elementGap),

            // ── Hero number ──
            if (state.hasUpcomingBills) ...[
              CurrencyText(
                amount: state.remainingAfterBills,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color.onSurface,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                l10n.today_remainingAfterBills,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                l10n.today_breakdown(
                  formatCurrencyCompact(state.balance),
                  formatCurrencyCompact(state.upcomingBillsTotal),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ] else ...[
              CurrencyText(
                amount: state.balance,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color.onSurface,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                l10n.today_balance,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],

            // ── Signal narrative (warning only) ──
            if (!state.isHealthy) ...[
              SizedBox(height: spacing.sectionGap),
              Text(
                _formatNarrative(l10n, state),
                style: textTheme.bodySmall?.copyWith(
                  color: color.error,
                  height: 1.4,
                ),
              ),
            ],

            SizedBox(height: spacing.sectionGap),

            // ── Context line (next bill or setup prompt) ──
            if (state.hasUpcomingBills && state.nextBillName != null)
              _buildNextBillChip(
                context,
                spacing,
                color,
                textTheme,
                state.nextBillName!,
                state.nextBillDays ?? 0,
              )
            else if (!state.hasUpcomingBills)
              _buildSetupPrompt(context, spacing, color, textTheme, l10n),

            // ── CTA (warning state only) ──
            if (!state.isHealthy && state.actionRoute != null) ...[
              SizedBox(height: spacing.elementGap),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    TodayCardAnalytics.recordCtaTapped(
                      signalType: state.signalType!,
                      destination: state.actionRoute!,
                    );
                    context.push(state.actionRoute!);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatActionLabel(l10n, state),
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

  Widget _buildNextBillChip(
    BuildContext context,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    String billName,
    int days,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap + 2,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 14,
            color: color.onSurfaceVariant,
          ),
          SizedBox(width: spacing.elementGapMin),
          Flexible(
            child: Text(
              days == 0
                  ? l10n.today_billDueToday(billName)
                  : l10n.today_billContext(billName, days),
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(
    BuildContext context,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.recurringTransactions);
      },
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap + 2,
          vertical: spacing.elementGapMin + 2,
        ),
        decoration: BoxDecoration(
          color: color.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(
            color: color.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plus,
              size: 14,
              color: color.primary,
            ),
            SizedBox(width: spacing.elementGapMin),
            Text(
              l10n.today_addBillPrompt,
              style: textTheme.labelSmall?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNarrative(AppLocalizations l10n, TodayCardState state) {
    return switch (state.signalType!) {
      BriefingSignalType.billDueToday => l10n.briefing_billDueToday(
          state.signalParams['name'] as String,
          state.signalParams['amount'] as String,
        ),
      BriefingSignalType.budgetExceeded => l10n.briefing_budgetExceeded(
          state.signalParams['name'] as String,
          state.signalParams['amount'] as String,
        ),
      BriefingSignalType.spendingDrift => l10n.briefing_spendingDrift(
          state.signalParams['category'] as String,
          state.signalParams['percent'] as String,
        ),
      BriefingSignalType.billDueSoon => l10n.briefing_billDueSoon(
          state.signalParams['name'] as String,
          state.signalParams['days'] as int,
        ),
      BriefingSignalType.overspending => l10n.briefing_overspending(
          state.signalParams['amount'] as String,
        ),
      BriefingSignalType.improvement => l10n.briefing_improvement(
          state.signalParams['percent'] as int,
        ),
    };
  }

  String _formatActionLabel(AppLocalizations l10n, TodayCardState state) {
    return switch (state.signalType!) {
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
// LEGACY — Keep DailyBriefingCard alive for any external refs
// ─────────────────────────────────────────────────────────────

/// @deprecated Use UnifiedBriefingCard instead.
class DailyBriefingCard extends ConsumerWidget {
  const DailyBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UnifiedBriefingCard();
  }
}
