import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/services/background_task_manager.dart';
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
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

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
    BackgroundTaskManager.processRecurringNow();
  }

  // ── Helpers ──
  static const _dueSoonDays = 7;

  List<RecurringTransaction> _overdue(List<RecurringTransaction> active) {
    final now = DateTime.now();
    return active.where((b) => b.nextDueDate.isBefore(now)).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  List<RecurringTransaction> _dueSoon(List<RecurringTransaction> active) {
    final now = DateTime.now();
    return active
        .where(
          (b) =>
              !b.nextDueDate.isBefore(now) &&
              b.nextDueDate.difference(now).inDays <= _dueSoonDays,
        )
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  List<RecurringTransaction> _thisMonth(List<RecurringTransaction> active) {
    final now = DateTime.now();
    return active
        .where(
          (b) =>
              b.nextDueDate.difference(now).inDays > _dueSoonDays &&
              b.nextDueDate.month == now.month &&
              b.nextDueDate.year == now.year,
        )
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  List<RecurringTransaction> _later(List<RecurringTransaction> active) {
    final now = DateTime.now();
    return active
        .where(
          (b) =>
              b.nextDueDate.difference(now).inDays > _dueSoonDays &&
              (b.nextDueDate.month != now.month ||
                  b.nextDueDate.year != now.year),
        )
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  String _frequencyLabel(Frequency f) => switch (f) {
        Frequency.daily => 'Daily',
        Frequency.weekly => 'Weekly',
        Frequency.monthly => 'Monthly',
        Frequency.yearly => 'Yearly',
      };

  int _daysUntil(RecurringTransaction b) =>
      b.nextDueDate.difference(DateTime.now()).inDays;

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title_billControlCenter),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addRecurring);
            },
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noBills,
              iconData: LucideIcons.receiptText,
            );
          }

          final active = bills.where((b) => b.isActive).toList();
          final overdue = _overdue(active);
          final dueSoon = _dueSoon(active);
          final thisMonth = _thisMonth(active);
          final later = _later(active);

          final monthlyTotal =
              active.fold(0.0, (sum, b) => sum + _monthlyEquivalent(b));

          return accountsAsync.when(
            data: (accounts) {
              final totalBalance =
                  accounts.fold(0.0, (sum, a) => sum + a.initialBalance);
              final upcomingTotal =
                  [...overdue, ...dueSoon].fold(0.0, (s, b) => s + b.amount);
              final afterBills = totalBalance - upcomingTotal;

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  // 1. Upcoming hero
                  if (overdue.isNotEmpty || dueSoon.isNotEmpty)
                    _buildUpcomingHero(
                      [...overdue, ...dueSoon],
                      upcomingTotal,
                      color,
                      textTheme,
                      spacing,
                      brightness,
                    ),
                  if (overdue.isNotEmpty || dueSoon.isNotEmpty)
                    SizedBox(height: spacing.elementGap),

                  // 2. Balance impact
                  _buildBalanceImpact(
                    totalBalance,
                    afterBills,
                    color,
                    textTheme,
                    spacing,
                    brightness,
                  ),
                  SizedBox(height: spacing.elementGap),

                  // 3. Monthly insight
                  _buildMonthlyInsight(
                    monthlyTotal,
                    active.length,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // 4. Grouped lists
                  if (overdue.isNotEmpty)
                    _buildGroup(
                      AppLocalizations.of(context)!.billCenter_overdue,
                      overdue,
                      FinanceColors.expenseColor(brightness),
                      LucideIcons.circleAlert,
                      color,
                      textTheme,
                      spacing,
                      brightness,
                    ),
                  if (dueSoon.isNotEmpty)
                    _buildGroup(
                      AppLocalizations.of(context)!.billCenter_thisWeek,
                      dueSoon,
                      color.tertiary,
                      LucideIcons.clock,
                      color,
                      textTheme,
                      spacing,
                      brightness,
                    ),
                  if (thisMonth.isNotEmpty)
                    _buildGroup(
                      AppLocalizations.of(context)!.billCenter_thisMonth,
                      thisMonth,
                      color.primary,
                      LucideIcons.calendar,
                      color,
                      textTheme,
                      spacing,
                      brightness,
                    ),
                  if (later.isNotEmpty)
                    _buildGroup(
                      AppLocalizations.of(context)!.billCenter_later,
                      later,
                      color.onSurfaceVariant,
                      LucideIcons.calendarDays,
                      color,
                      textTheme,
                      spacing,
                      brightness,
                    ),

                  const AmbientBrandSection(),
                ],
              );
            },
            loading: () => ListView(
              children: List.generate(3, (_) => const BudgetCardSkeleton()),
            ),
            error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
          );
        },
        loading: () => ListView(
          children: List.generate(3, (_) => const BudgetCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  double _monthlyEquivalent(RecurringTransaction b) => switch (b.frequency) {
        Frequency.daily => b.amount * 30,
        Frequency.weekly => b.amount * 4.33,
        Frequency.monthly => b.amount,
        Frequency.yearly => b.amount / 12,
      };

  // ── BATCH 2: Upcoming Hero ──
  Widget _buildUpcomingHero(
    List<RecurringTransaction> upcoming,
    double total,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
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
                  'Upcoming in $_dueSoonDays days',
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
            // Bill rows (max 4)
            ...upcoming.take(4).map(
                  (b) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: b.nextDueDate.isBefore(DateTime.now())
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
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatCurrency(
                            b.amount,
                            code: b.account.value?.currencyCode ??
                                BaseCurrency.code,
                            decimals: 0,
                          ),
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
                  '+${upcoming.length - 4} more',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ),
            Divider(
                height: spacing.sectionGap,
                color: color.onPrimaryContainer.withValues(alpha: 0.15),),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.billCenter_totalUpcoming,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  formatCurrency(total, decimals: 0),
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

  String _dueLabel(RecurringTransaction b) {
    final days = _daysUntil(b);
    if (days < 0) return '${days.abs()}d ago';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  // ── BATCH 3: Balance Impact ──
  Widget _buildBalanceImpact(
    double balance,
    double afterBills,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final isNegative = afterBills < 0;
    final accentColor = isNegative
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Card(
      elevation: 0,
      color: accentColor.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGap),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Icon(
                isNegative
                    ? LucideIcons.triangleAlert
                    : LucideIcons.shieldCheck,
                color: accentColor,
                size: 24,
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.billCenter_afterUpcoming,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  CurrencyText(
                    amount: afterBills,
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
            if (isNegative)
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
                  'LOW',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── BATCH 4: Monthly Insight ──
  Widget _buildMonthlyInsight(
    double monthlyTotal,
    int count,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
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
                    text: '$count active bills',
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
                    text: '${formatCurrency(monthlyTotal, decimals: 0)}/mo',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BATCH 5: Group Section ──
  Widget _buildGroup(
    String title,
    List<RecurringTransaction> bills,
    Color accent,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final groupTotal = bills.fold(0.0, (s, b) => s + b.amount);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              SizedBox(width: spacing.elementGap),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent,
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
              Text(
                formatCurrency(groupTotal, decimals: 0),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          // Bill cards
          ...bills.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: _buildBillCard(b, color, textTheme, spacing, brightness),
            ),
          ),
        ],
      ),
    );
  }

  // ── BATCH 6: Bill Card ──
  Widget _buildBillCard(
    RecurringTransaction bill,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final days = _daysUntil(bill);
    final isOverdue = days < 0;
    final isDueSoon = days >= 0 && days <= _dueSoonDays;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (isOverdue) {
      statusColor = FinanceColors.expenseColor(brightness);
      statusText = '${days.abs()}d overdue';
      statusIcon = LucideIcons.circleAlert;
    } else if (isDueSoon) {
      statusColor = color.tertiary;
      statusText = days == 0
          ? 'Due today'
          : days == 1
              ? 'Tomorrow'
              : 'In $days days';
      statusIcon = LucideIcons.clock;
    } else {
      statusColor = color.primary;
      statusText = DateFormat('MMM d').format(bill.nextDueDate);
      statusIcon = LucideIcons.calendar;
    }

    return FutureBuilder<bool>(
      future: _isAlreadyPaid(bill),
      builder: (context, snap) {
        final isPaid = snap.data ?? false;
        final effectiveColor =
            isPaid ? FinanceColors.incomeColor(brightness) : statusColor;
        final effectiveText = isPaid ? 'Paid' : statusText;
        final effectiveIcon = isPaid ? LucideIcons.circleCheck : statusIcon;

        return Card(
          elevation: 0,
          color: color.surfaceContainerLow,
          margin: const EdgeInsets.only(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: isOverdue && !isPaid
                  ? effectiveColor.withValues(alpha: 0.5)
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
                  // Icon
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      IconHelper.iconFromName(
                        bill.category.value?.iconName ?? 'category',
                      ),
                      color: effectiveColor,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  // Name + status
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
                            Icon(effectiveIcon,
                                size: 12, color: effectiveColor,),
                            SizedBox(width: spacing.elementGapMin),
                            Text(
                              effectiveText,
                              style: textTheme.bodySmall?.copyWith(
                                color: effectiveColor,
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
                  // Amount + action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(
                          bill.amount,
                          code: bill.account.value?.currencyCode ??
                              BaseCurrency.code,
                          decimals: 0,
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? effectiveColor
                              : FinanceColors.expenseColor(brightness),
                        ),
                      ),
                      if (!isPaid && (isOverdue || isDueSoon))
                        Padding(
                          padding: EdgeInsets.only(top: spacing.elementGapMin),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _markAsPaid(bill);
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
                                  Icon(LucideIcons.check,
                                      size: 12, color: color.primary,),
                                  SizedBox(width: spacing.elementGapMin),
                                  Text(
                                    'Pay',
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
                              color: effectiveColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusSmall),
                            ),
                            child: Text(
                              'PAID',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: effectiveColor,
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
      },
    );
  }

  // ── BATCH 7: Mark Paid + helpers ──
  Future<bool> _isAlreadyPaid(RecurringTransaction bill) async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    final dueDate = bill.nextDueDate;
    final searchStart = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .subtract(const Duration(days: 1));
    final searchEnd =
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59)
            .add(const Duration(days: 1));

    final count = await isar.transactions
        .filter()
        .dateBetween(searchStart, searchEnd)
        .recurringTransactionSource((q) => q.idEqualTo(bill.id))
        .count();
    return count > 0;
  }

  void _markAsPaid(RecurringTransaction bill) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );

    if (dueDate.isAfter(today)) {
      SnackbarService.error(
        'Cannot mark future bills as paid. Due on ${DateFormat('MMM d').format(bill.nextDueDate)}',
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
    if (context.mounted) {
      HapticFeedback.mediumImpact();
      SnackbarService.success('${bill.category.value?.name} marked as paid');
    }
  }

  Future<_PaidAction?> _showLinkOrCreateSheet(
    RecurringTransaction bill,
    Transaction existing,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sp = ref.read(spacingProvider);

    return showModalBottomSheet<_PaidAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                'Existing Transaction Found',
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
                      Text(
                        formatCurrency(existing.amount,
                            code: existing.account.value?.currencyCode ??
                                BaseCurrency.code,),
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
                  label: const Text('Link This Transaction'),
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
                  label: const Text('Create New Entry'),
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
