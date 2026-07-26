import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/services/background_task_manager.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/features/transactions/data/bill_control_center_provider.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/subscription_list_card.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class BillControlCenterScreen extends ConsumerStatefulWidget {
  const BillControlCenterScreen({super.key});

  @override
  ConsumerState<BillControlCenterScreen> createState() =>
      _BillControlCenterScreenState();
}

class _BillControlCenterScreenState
    extends ConsumerState<BillControlCenterScreen> {
  @override
  void initState() {
    super.initState();
    TodayCardAnalytics.recordDestinationOpened(destination: 'billCenter');
    BackgroundTaskManager.processRecurringNow();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final ctxt = AppLocalizations.of(context)!;
    final dataAsync = ref.watch(billControlCenterProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.title_billControlCenter,
        appBarMode: AppBarMode.standard,
        enableRefresh: true,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_recurring',
            label: ctxt.common_add,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addRecurring);
            },
          ),
        ],
      ),
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.invalidate(billControlCenterProvider);
        await ref.read(billControlCenterProvider.future);
      }),
      body: dataAsync.when(
        data: (data) {
          if (data.activeCount == 0) {
            return NoDataFound(
              message: BuddyMessages.noBills,
              description: ctxt.billCenter_addBill,
              iconData: LucideIcons.receiptText,
              action: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.addRecurring);
                },
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.common_add),
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // 1. Balance Impact (affordability first)
              _buildBalanceImpact(
                data.affordability,
                color,
                textTheme,
                spacing,
                brightness,
                ctxt,
              ),
              SizedBox(height: spacing.elementGap),

              // 2. This week required strip
              if (data.thisWeekCount > 0)
                _buildThisWeekStrip(
                  data.thisWeekTotal,
                  data.thisWeekCount,
                  color,
                  textTheme,
                  spacing,
                  ctxt,
                ),
              if (data.thisWeekCount > 0) SizedBox(height: spacing.elementGap),

              // 3. Upcoming hero
              if (data.overdue.isNotEmpty || data.dueSoon.isNotEmpty)
                _buildUpcomingHero(
                  [...data.overdue, ...data.dueSoon],
                  data.affordability.upcomingTotal,
                  data.paidBillIds,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                  ctxt,
                ),
              if (data.overdue.isNotEmpty || data.dueSoon.isNotEmpty)
                SizedBox(height: spacing.elementGap),

              // 4. Monthly insight
              _buildMonthlyInsight(
                data.monthlyTotal,
                data.activeCount,
                data.largestBill,
                color,
                textTheme,
                spacing,
              ),
              SizedBox(height: spacing.sectionGap),

              // 5. Grouped bill lists
              if (data.overdue.isNotEmpty)
                _buildGroup(
                  ctxt.billCenter_overdue,
                  data.overdue,
                  data.paidBillIds,
                  FinanceColors.expenseColor(brightness),
                  LucideIcons.circleAlert,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                ),
              if (data.dueSoon.isNotEmpty)
                _buildGroup(
                  ctxt.billCenter_thisWeek,
                  data.dueSoon,
                  data.paidBillIds,
                  color.tertiary,
                  LucideIcons.clock,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                ),
              if (data.thisMonth.isNotEmpty)
                _buildGroup(
                  ctxt.billCenter_thisMonth,
                  data.thisMonth,
                  data.paidBillIds,
                  color.primary,
                  LucideIcons.calendar,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                ),
              if (data.later.isNotEmpty)
                _buildGroup(
                  ctxt.billCenter_later,
                  data.later,
                  data.paidBillIds,
                  color.onSurfaceVariant,
                  LucideIcons.calendarDays,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                ),

              // 6. Detected subscriptions (last — optional discovery)
              const SubscriptionListCard(),

              const AmbientBrandSection(),
            ],
          );
        },
        loading: () => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: const BudgetCardSkeleton(),
            ),
          ),
        ),
        error: (err, _) =>
            Center(child: Text(BuddyMessages.errorWith('$err'))),
      ),
    );
  }

  // ── Balance Impact (affordability hero) ──

  Widget _buildBalanceImpact(
    BillAffordabilitySummary affordability,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final Color accentColor;
    final IconData icon;
    final String? statusLabel;

    switch (affordability.state) {
      case AffordabilityState.negative:
        accentColor = FinanceColors.expenseColor(brightness);
        icon = LucideIcons.triangleAlert;
        statusLabel = null;
      case AffordabilityState.low:
        accentColor = color.tertiary;
        icon = LucideIcons.triangleAlert;
        statusLabel = ctxt.billCenter_lowBuffer;
      case AffordabilityState.safe:
        accentColor = FinanceColors.incomeColor(brightness);
        icon = LucideIcons.shieldCheck;
        statusLabel = ctxt.billCenter_safe;
    }

    final isDark = brightness == Brightness.dark;

    // This is the screen's one hero/glow card — the number the user came
    // to check ("what's left after upcoming bills"). Everything else below
    // (upcoming list, monthly insight, groups) stays flat/glass per the
    // one-glow-per-screen rule.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ctxt.billCenter_afterUpcoming,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      CurrencyText(
                        amount: affordability.remainingBalance,
                        fixedLength: 0,
                        compact: false,
                        showSign: true,
                        showPositiveSign: false,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (statusLabel != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.elementGap,
                      vertical: spacing.elementGapMin,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Text(
                      statusLabel,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            // Unfunded warning
            if (affordability.unfundedCount > 0) ...[
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                decoration: BoxDecoration(
                  color: FinanceColors.expenseColor(brightness)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 12,
                      color: FinanceColors.expenseColor(brightness),
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      ctxt.billCenter_unfundedCount(
                        affordability.unfundedCount,
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: FinanceColors.expenseColor(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── This Week Strip ──

  Widget _buildThisWeekStrip(
    double total,
    int count,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 16, color: color.tertiary),
          SizedBox(width: spacing.elementGap),
          Text(
            ctxt.billCenter_thisWeekRequired,
            style: textTheme.labelMedium?.copyWith(
              color: color.onSurface,
            ),
          ),
          const Spacer(),
          CurrencyText(
            amount: total,
            compact: true,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.tertiary,
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Text(
            '· $count',
            style: textTheme.labelMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming Hero ──

  Widget _buildUpcomingHero(
    List<RecurringTransaction> upcoming,
    double total,
    Set<int> paidBillIds,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    return Card(
      elevation: 0,
      color: color.primaryContainer,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bell, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  ctxt.billCenter_upcomingIn(7),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    '${upcoming.length}',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            ...upcoming.take(4).map(
                  (b) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: paidBillIds.contains(b.id)
                                ? FinanceColors.incomeColor(brightness)
                                : b.nextDueDate.isBefore(DateTime.now())
                                    ? FinanceColors.expenseColor(brightness)
                                    : color.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Text(
                            b.category.value?.name ?? 'Bill',
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onPrimaryContainer,
                              decoration: paidBillIds.contains(b.id)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CurrencyText(
                          amount: b.amount,
                          currencyCode: b.account.value?.currencyCode,
                          compact: false,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        SizedBox(
                          width: 64,
                          child: Text(
                            _dueLabel(b),
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (upcoming.length > 4)
              Padding(
                padding: EdgeInsets.only(top: spacing.elementGapMin),
                child: Text(
                  ctxt.billCenter_moreCount(upcoming.length - 4),
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ),
            Divider(
              height: spacing.sectionGap,
              color: color.onPrimaryContainer.withValues(alpha: 0.15),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.billCenter_totalUpcoming,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                CurrencyText(
                  amount: total,
                  compact: false,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Monthly Insight ──

  Widget _buildMonthlyInsight(
    double monthlyTotal,
    int count,
    RecurringTransaction? largest,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap * 1.5,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.repeat, size: 16, color: color.primary),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: ctxt.billCenter_activeBills(count),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '  \u2022  ',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  TextSpan(
                    // monthlyTotal is already converted to base currency by
                    // the provider, so formatCurrency's default base-code
                    // formatting is correct here (no per-bill currencyCode).
                    text: '${formatCurrency(monthlyTotal, decimals: 0)}/mo',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  if (largest != null) ...[
                    TextSpan(
                      text: '  \u2022  ',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    TextSpan(
                      // Show in the bill's own account currency (not
                      // base-converted) since this is a per-bill reference
                      // amount, not part of an aggregate total.
                      text:
                          '${largest.category.value?.name ?? 'Bill'} ${formatCurrency(largest.amount, code: largest.account.value?.currencyCode, decimals: 0)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Group Section ──

  Widget _buildGroup(
    String title,
    List<RecurringTransaction> bills,
    Set<int> paidBillIds,
    Color accent,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    // Bills can be linked to accounts in different currencies — summing raw
    // `amount` mixes currencies. CurrencyText with no currencyCode renders
    // in base currency, so convert each bill's amount first (rates were
    // already merged into the cache by billControlCenterProvider).
    final groupTotal = bills.fold(0.0, (s, b) {
      final code = b.account.value?.currencyCode;
      final rate = code != null ? (CurrencyService.getCachedRate(code) ?? 1.0) : 1.0;
      return s + b.amount * rate;
    });

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TypeSectionHeader(
                  label: title,
                  icon: icon,
                  accentColor: accent,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap * 0.75,
                  vertical: spacing.elementGapUltraMin,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  '${bills.length}',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              CurrencyText(
                amount: groupTotal,
                compact: false,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          ...bills.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: _buildBillCard(
                b,
                paidBillIds.contains(b.id),
                color,
                textTheme,
                spacing,
                brightness,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bill Card ──

  Widget _buildBillCard(
    RecurringTransaction bill,
    bool isPaid,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final days = bill.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = bill.nextDueDate.isBefore(DateTime.now());
    final isDueSoon = !isOverdue && days <= 7;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    final ctxt = AppLocalizations.of(context)!;
    if (isPaid) {
      statusColor = FinanceColors.incomeColor(brightness);
      statusText = ctxt.billCenter_paid;
      statusIcon = LucideIcons.circleCheck;
    } else if (isOverdue) {
      statusColor = FinanceColors.expenseColor(brightness);
      statusText = ctxt.billCenter_daysOverdue(days.abs());
      statusIcon = LucideIcons.circleAlert;
    } else if (isDueSoon) {
      statusColor = color.tertiary;
      statusText = days == 0
          ? ctxt.billCenter_dueToday
          : days == 1
              ? ctxt.billCenter_tomorrow
              : ctxt.billCenter_inDays(days);
      statusIcon = LucideIcons.clock;
    } else {
      statusColor = color.primary;
      statusText = DateFormat('MMM d').format(bill.nextDueDate);
      statusIcon = LucideIcons.calendar;
    }

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: isOverdue && !isPaid
              ? statusColor.withValues(alpha: 0.5)
              : color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.addRecurring,
          extra: {'recurring': bill},
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  IconHelper.iconFromName(
                    bill.category.value?.iconName ?? 'category',
                  ),
                  color: statusColor,
                  size: 22,
                ),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.category.value?.name ?? 'Bill',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          statusText,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' \u2022 ${_frequencyLabel(bill.frequency)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CurrencyText(
                    amount: bill.amount,
                    currencyCode: bill.account.value?.currencyCode,
                    compact: false,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? statusColor
                          : FinanceColors.expenseColor(brightness),
                    ),
                  ),
                  if (!isPaid && (isOverdue || isDueSoon))
                    Padding(
                      padding: EdgeInsets.only(top: spacing.elementGapMin),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _markAsPaid(bill, spacing);
                        },
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.elementGap,
                            vertical: spacing.elementGapMin,
                          ),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.check,
                                size: 12,
                                color: color.primary,
                              ),
                              SizedBox(width: spacing.elementGapMin),
                              Text(
                                AppLocalizations.of(context)!.billCenter_pay,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isPaid)
                    Padding(
                      padding: EdgeInsets.only(top: spacing.elementGapMin),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.elementGap * 0.75,
                          vertical: spacing.elementGapUltraMin,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.billCenter_paid.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: spacing.elementGapMin),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: color.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  String _dueLabel(RecurringTransaction b) {
    final ctxt = AppLocalizations.of(context)!;
    final days = b.nextDueDate.difference(DateTime.now()).inDays;
    if (days < 0) return ctxt.billCenter_daysAgo(days.abs());
    if (days == 0) return ctxt.billCenter_today;
    if (days == 1) return ctxt.billCenter_tomorrow;
    return ctxt.billCenter_inDays(days);
  }

  String _frequencyLabel(Frequency f) {
    final ctxt = AppLocalizations.of(context)!;
    return switch (f) {
      Frequency.daily => ctxt.frequency_daily,
      Frequency.weekly => ctxt.frequency_weekly,
      Frequency.monthly => ctxt.frequency_monthly,
      Frequency.yearly => ctxt.frequency_yearly,
    };
  }

  // ── Mark As Paid (preserved from original) ──

  void _markAsPaid(RecurringTransaction bill, AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );

    if (dueDate.isAfter(today)) {
      SnackbarService.error(
        '${ctxt.billCenter_cannotPayFuture}. Due on ${DateFormat('MMM d').format(bill.nextDueDate)}',
        spacing,
      );
      return;
    }

    final isar = await ref.read(isarServiceProvider).getInstance();

    final searchStart = dueDate.subtract(const Duration(days: 5));
    final searchEnd = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    ).add(const Duration(days: 2));

    final candidates = await isar.transactions
        .filter()
        .isExpenseEqualTo(bill.isExpense)
        .isTransferEqualTo(false)
        .dateBetween(searchStart, searchEnd)
        .amountBetween(bill.amount - 0.01, bill.amount + 0.01)
        .findAll();

    Transaction? matchingTxn;
    for (final txn in candidates) {
      await txn.recurringTransactionSource.load();
      await txn.account.load();
      if (txn.recurringTransactionSource.value == null &&
          txn.account.value?.id == bill.account.value?.id) {
        matchingTxn = txn;
        break;
      }
    }

    if (matchingTxn != null && mounted) {
      await matchingTxn.category.load();
      final action = await _showLinkOrCreateSheet(bill, matchingTxn);
      if (action == null) return;

      if (action == _PaidAction.link) {
        await _linkExistingTransaction(isar, matchingTxn, bill);
      } else {
        await _createNewPayment(isar, bill);
      }
    } else {
      await _createNewPayment(isar, bill);
    }

    await _advanceDueDate(isar, bill);
    ref.invalidate(transactionProvider);
    ref.invalidate(recurringTransactionsProvider);
    ref.invalidate(billControlCenterProvider);
    if (context.mounted) {
      HapticFeedback.mediumImpact();
      TodayCardAnalytics.recordBillResolved(
        billName: bill.category.value?.name ?? 'Bill',
      );
      SnackbarService.success(
        ctxt.billCenter_markedPaid(bill.category.value?.name ?? 'Bill'),
        spacing,
      );
    }
  }

  Future<_PaidAction?> _showLinkOrCreateSheet(
    RecurringTransaction bill,
    Transaction existing,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sp = ref.read(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return showModalBottomSheet<_PaidAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(sp.cardInner + sp.elementGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: sp.sectionGap),
              Icon(LucideIcons.search, size: 36, color: cs.primary),
              SizedBox(height: sp.elementGap),
              Text(
                ctxt.billCenter_existingTxnFound,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: sp.elementGap),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sp.radiusMedium),
                ),
                child: Padding(
                  padding: EdgeInsets.all(sp.cardInner),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing.category.value?.name ?? 'Transaction',
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${DateFormat('MMM d').format(existing.date)} \u2022 ${existing.account.value?.name ?? ''}',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      CurrencyText(
                        amount: existing.amount,
                        currencyCode: existing.account.value?.currencyCode,
                        compact: false,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sp.sectionGap),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, _PaidAction.link),
                  icon: const Icon(LucideIcons.link, size: 16),
                  label: Text(ctxt.billCenter_linkTransaction),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sp.radiusMedium),
                    ),
                  ),
                ),
              ),
              SizedBox(height: sp.elementGap),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, _PaidAction.create),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(ctxt.billCenter_createNewEntry),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sp.radiusMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _linkExistingTransaction(
    Isar isar,
    Transaction txn,
    RecurringTransaction bill,
  ) async {
    await isar.writeTxn(() async {
      txn.recurringTransactionSource.value = bill;
      await txn.recurringTransactionSource.save();
      await isar.transactions.put(txn);
    });
  }

  Future<void> _createNewPayment(
    Isar isar,
    RecurringTransaction bill,
  ) async {
    final transaction = Transaction.create(
      date: DateTime.now(),
      amount: bill.amount,
      isExpense: bill.isExpense,
      description: bill.description?.isNotEmpty == true
          ? '${bill.description} (Paid)'
          : '${bill.category.value?.name ?? "Bill"} (Paid)',
    )
      ..account.value = bill.account.value
      ..category.value = bill.category.value
      ..recurringTransactionSource.value = bill;

    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();
      await transaction.recurringTransactionSource.save();
    });
  }

  Future<void> _advanceDueDate(
    Isar isar,
    RecurringTransaction bill,
  ) async {
    final nextDate = calculateNextDueDate(
      bill.nextDueDate,
      bill.frequency,
      bill.startDate,
    );

    if (bill.endDate != null && nextDate.isAfter(bill.endDate!)) {
      bill.isActive = false;
    } else {
      bill.nextDueDate = nextDate;
    }

    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(bill);
    });
  }
}

enum _PaidAction { link, create }
