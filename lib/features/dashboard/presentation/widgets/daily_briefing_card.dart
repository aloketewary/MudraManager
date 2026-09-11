import 'package:auto_skeleton/auto_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/data/financial_regime_provider.dart';
import 'package:mudra_manager/features/dashboard/data/spending_drift_detector.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';

enum BriefingSignalType {
  billDueToday,
  budgetExceeded,
  spendingDrift,
  billDueSoon,
  overspending,
  improvement,
}

class TodayCardState {
  final double balance;
  final double upcomingBillsTotal;
  final double remainingAfterBills;
  final String? nextBillName;
  final int? nextBillDays;
  final BriefingSignalType? signalType;
  final Map<String, dynamic> signalParams;
  final String? actionRoute;

  const TodayCardState({
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
  bool get hasUpcomingBills => nextBillName != null;
}

final todayCardProvider = Provider<TodayCardState?>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) return null;

  final now = DateTime.now();
  final isGuest = ref.watch(guestModeProvider);
  final regime = ref.watch(financialRegimeProvider);
  final balance = GuestModeUtil.applyGuestMode(data.totalBalance, isGuest);

  final todayBills = <RecurringTransaction>[];
  final soonBills = <RecurringTransaction>[];
  double upcomingTotal = 0;
  RecurringTransaction? nearestBill;
  int nearestDays = 999;

  for (final r in data.recurringExpenses) {
    final daysUntil = r.nextDueDate.difference(now).inDays;
    if (daysUntil < 0 || daysUntil > 30) continue;

    final guestAmount = GuestModeUtil.applyGuestMode(r.amount, isGuest);
    upcomingTotal += guestAmount;

    if (daysUntil == 0) {
      todayBills.add(r);
    } else if (daysUntil <= 3) {
      soonBills.add(r);
    }

    if (daysUntil < nearestDays) {
      nearestDays = daysUntil;
      nearestBill = r;
    }
  }

  String? nextBillName;
  int? nextBillDays;
  if (nearestBill != null) {
    final rawName = nearestBill.description ?? '';
    nextBillName = rawName.isEmpty
        ? (nearestBill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawName,
            nearestBill.category.value?.name ?? 'Bill',
          );
    nextBillDays = nearestDays;
  }

  final remainingAfterBills = balance - upcomingTotal;

  final signals = <_Signal>[];
  final txns = data.transactions.where((t) => !t.isTransfer).toList();

  if (todayBills.isNotEmpty) {
    final bill = todayBills.first;
    final rawName = bill.description ?? '';
    final billName = rawName.isEmpty
        ? (bill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawName,
            bill.category.value?.name ?? 'Bill',
          );
    signals.add(
      _Signal(
        urgency: 100,
        type: BriefingSignalType.billDueToday,
        params: {
          'name': billName,
          'amount': formatCurrencyCompact(
            GuestModeUtil.applyGuestMode(bill.amount, isGuest),
          ),
        },
        actionRoute: AppRoutes.recurringTransactions,
      ),
    );
  }

  if (data.budgets.isNotEmpty) {
    final worst = data.budgets.where((b) => b.spent > b.budget.amount).toList()
      ..sort(
        (a, b) =>
            (b.spent - b.budget.amount).compareTo(a.spent - a.budget.amount),
      );
    if (worst.isNotEmpty) {
      final b = worst.first;
      signals.add(
        _Signal(
          urgency: 80,
          type: BriefingSignalType.budgetExceeded,
          params: {
            'name': b.budget.name,
            'amount': formatCurrencyCompact(
              GuestModeUtil.applyGuestMode(b.spent - b.budget.amount, isGuest),
            ),
          },
          actionRoute: AppRoutes.budgetDashboard,
        ),
      );
    }
  }

  if (regime.spendingDepthMonths >= 3) {
    final drifts = detectSpendingDrift(txns);
    if (drifts.isNotEmpty) {
      final drift = drifts.first;
      final parts = drift.title.split(' ');
      signals.add(
        _Signal(
          urgency: 70,
          type: BriefingSignalType.spendingDrift,
          params: {'category': parts.first, 'percent': parts.last},
          actionRoute: drift.actionRoute,
        ),
      );
    }
  }

  if (soonBills.isNotEmpty && todayBills.isEmpty) {
    final bill = soonBills.first;
    final rawName = bill.description ?? '';
    final billName = rawName.isEmpty
        ? (bill.category.value?.name ?? 'Bill')
        : FieldEncryptionService.safeDisplay(
            rawName,
            bill.category.value?.name ?? 'Bill',
          );
    signals.add(
      _Signal(
        urgency: 60,
        type: BriefingSignalType.billDueSoon,
        params: {
          'name': billName,
          'days': bill.nextDueDate.difference(now).inDays,
        },
        actionRoute: AppRoutes.recurringTransactions,
      ),
    );
  }

  if (regime.hasRegularIncome &&
      data.totalExpense > data.totalIncome &&
      data.totalIncome > 0) {
    signals.add(
      _Signal(
        urgency: 50,
        type: BriefingSignalType.overspending,
        params: {
          'amount': formatCurrencyCompact(
            GuestModeUtil.applyGuestMode(
              data.totalExpense - data.totalIncome,
              isGuest,
            ),
          ),
        },
        actionRoute: AppRoutes.budgetDashboard,
      ),
    );
  }

  if (regime.spendingDepthMonths >= 2 && now.day >= 10) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);
    final lastMonthStart = lastMonthSameDay.subtract(const Duration(days: 1));

    double lastExp = 0, thisExp = 0;
    for (final t in txns) {
      if (!t.isExpense) continue;
      if (t.date.isAfter(lastMonthStart) &&
          t.date.isBefore(lastMonthSameDay.add(const Duration(days: 1)))) {
        lastExp += t.baseAmount;
      }
      if (t.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        thisExp += t.baseAmount;
      }
    }

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

  signals.sort((a, b) => b.urgency.compareTo(a.urgency));
  final winner = signals.isNotEmpty ? signals.first : null;

  return TodayCardState(
    balance: balance,
    upcomingBillsTotal: upcomingTotal,
    remainingAfterBills: remainingAfterBills,
    nextBillName: nextBillName,
    nextBillDays: nextBillDays,
    signalType: winner?.type,
    signalParams: winner?.params ?? const {},
    actionRoute: winner?.actionRoute,
  );
});

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

/// Compact Insight card for the daily financial briefing.
///
/// Design contract (dashboard-visual-polish steering):
/// - No balance / currency amount shown here - that's Accounts' job.
/// - One glance, one line of status text, optional single action chip.
/// - Healthy state: quiet positive affirmation, no numbers.
/// - Alert state: plain-language signal + one CTA chip, tap anywhere to act.
/// - Dark surface separates this insight from the money summary above.
class TodayBriefingSkeleton extends ConsumerWidget {
  const TodayBriefingSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final insightBackground = color.brightness == Brightness.light
        ? const Color(0xFF151215)
        : color.surfaceContainerHighest;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: AutoSkeleton(
        enabled: true,
        child: Container(
          decoration: BoxDecoration(
            color: insightBackground,
            borderRadius: BorderRadius.circular(spacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: color.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner * 0.7,
              vertical: spacing.elementGap,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 20, color: color.primary),
                SizedBox(width: spacing.elementGap),
                const Expanded(
                  child: Text(
                    'Your financial insight is loading',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                const Text('Review'),
                SizedBox(width: spacing.elementGapMin),
                const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodayBriefingCard extends ConsumerStatefulWidget {
  const TodayBriefingCard({super.key});

  @override
  ConsumerState<TodayBriefingCard> createState() => _TodayBriefingCardState();
}

class _TodayBriefingCardState extends ConsumerState<TodayBriefingCard> {
  bool _hasRecordedImpression = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayCardProvider);
    if (state == null) return const SizedBox.shrink();

    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    if (!_hasRecordedImpression) {
      _hasRecordedImpression = true;
      if (state.isHealthy) {
        TodayCardAnalytics.recordCardShownHealthy();
      } else {
        TodayCardAnalytics.recordCardShownAlert(
          signalType: state.signalType!,
          metadata: state.signalParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }
    }

    final isHealthy = state.isHealthy;
    final isPro = ref.watch(isProProvider).value ?? false;
    final showUpgrade = isHealthy && !isPro;
    final statusColor = isHealthy ? color.primary : color.error;
    final statusIcon =
        isHealthy ? LucideIcons.sparkles : LucideIcons.circleAlert;
    final statusText =
        isHealthy ? 'Your insight is ready' : _formatBriefMessage(state);
    final hasAction = showUpgrade || (!isHealthy && state.actionRoute != null);
    final insightBackground = color.brightness == Brightness.light
        ? const Color(0xFF151215)
        : color.surfaceContainerHighest;
    final insightText = color.brightness == Brightness.light
        ? const Color(0xFFF7F3F8)
        : color.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: insightBackground,
          borderRadius: BorderRadius.circular(spacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: color.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: hasAction
              ? () {
                  if (showUpgrade) {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.upgrade);
                    return;
                  }
                  HapticFeedback.lightImpact();
                  TodayCardAnalytics.recordCtaTapped(
                    signalType: state.signalType!,
                    destination: state.actionRoute!,
                  );
                  context.push(state.actionRoute!);
                }
              : null,
          borderRadius: BorderRadius.circular(spacing.radiusLarge),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner * 0.7,
              vertical: spacing.elementGap,
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: 20,
                  color: isHealthy ? color.primary : statusColor,
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isHealthy ? insightText : statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasAction) ...[
                  SizedBox(width: spacing.elementGap),
                  Text(
                    showUpgrade ? 'Get Pro' : _formatActionLabel(l10n, state),
                    style: textTheme.labelMedium?.copyWith(
                      color: showUpgrade ? insightText : statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: spacing.elementGapMin),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: showUpgrade ? insightText : statusColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBriefMessage(TodayCardState state) {
    return switch (state.signalType!) {
      BriefingSignalType.billDueToday =>
        '${state.signalParams['name']} due today',
      BriefingSignalType.budgetExceeded =>
        '${state.signalParams['name']} over budget',
      BriefingSignalType.spendingDrift =>
        '${state.signalParams['category']} spending high',
      BriefingSignalType.billDueSoon =>
        '${state.signalParams['name']} due in ${state.signalParams['days']} days',
      BriefingSignalType.overspending => 'Spending exceeds income',
      BriefingSignalType.improvement =>
        'Spending is down ${state.signalParams['percent']}%',
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
