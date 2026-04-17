import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_service.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_pdf.dart';

class MonthlyRecapScreen extends ConsumerStatefulWidget {
  final DateTime? month;
  const MonthlyRecapScreen({super.key, this.month});

  @override
  ConsumerState<MonthlyRecapScreen> createState() => _MonthlyRecapScreenState();
}

class _MonthlyRecapScreenState extends ConsumerState<MonthlyRecapScreen> {
  late DateTime _selectedMonth;
  bool _downloading = false;
  static String get _currency => BaseCurrency.symbol;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = widget.month ?? DateTime(now.year, now.month - 1, 1);
  }

  Future<MonthlyRecapData> _loadData() async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    return MonthlyRecapService(isar)
        .generate(_selectedMonth, currency: _currency);
  }

  Future<void> _downloadPdf(MonthlyRecapData data) async {
    setState(() => _downloading = true);
    try {
      final bytes = await MonthlyRecapPdf.generate(data);
      final monthStr = safeDateFormat('MMM_yyyy').format(data.month);
      await saveExportedFile(
        bytes,
        'MudraManager_Recap_$monthStr.pdf',
        askUser: true,
      );
      SnackbarService.success(BuddyMessages.exportSuccess);
    } catch (e) {
      SnackbarService.error(BuddyMessages.exportFailed('$e'));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _fmt(double v) =>
      '$_currency${NumberFormat('#,##0', 'en_IN').format(v.round())}';

  String _delta(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthName = safeDateFormat('MMMM yyyy', AppLocalizations.of(context)!.localeName).format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.recap_recapTitle} — $monthName'),
      ),
      body: FutureBuilder<MonthlyRecapData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: EdgeInsets.all(spacing.cardHorizontal),
              children: List.generate(4, (_) => const DashboardCardSkeleton()),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── HERO SUMMARY ──
              Container(
                padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      color.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                monthName,
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data.transactionCount} transactions',
                                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: _downloading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.download),
                          onPressed: _downloading ? null : () => _downloadPdf(data),
                          tooltip: AppLocalizations.of(context)!.stats_downloadPdf,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGap * 1.5),
                    Row(
                      children: [
                        _summaryTile(AppLocalizations.of(context)!.recap_income, data.totalIncome, color.primary, color, textTheme, spacing),
                        SizedBox(width: spacing.elementGap),
                        _summaryTile(AppLocalizations.of(context)!.recap_expense, data.totalExpense, color.error, color, textTheme, spacing),
                        SizedBox(width: spacing.elementGap),
                        _summaryTile(AppLocalizations.of(context)!.recap_saved, data.netSavings, color.primary, color, textTheme, spacing),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.sectionGap),

                    // ── MONTH-OVER-MONTH ──
                    if (data.prevMonthIncome > 0 ||
                        data.prevMonthExpense > 0) ...[
                      _sectionHeader(
                        'vs Last Month',
                        LucideIcons.arrowLeftRight,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildMoMComparison(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── HIGHLIGHTS ──
                    _buildHighlights(data, color, textTheme, spacing),
                    SizedBox(height: spacing.sectionGap),

                    // ── DAILY SPENDING CHART ──
                    if (data.dailySpending.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_dailySpending,
                        LucideIcons.chartBar,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildDailyChart(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── SPENDING VELOCITY ──
                    _sectionHeader(
                      AppLocalizations.of(context)!.recap_spendingPace,
                      LucideIcons.gauge,
                      color,
                      textTheme,
                    ),
                    const SizedBox(height: 10),
                    _buildSpendingVelocity(data, color, textTheme, spacing),
                    SizedBox(height: spacing.sectionGap),

                    // ── RECURRING VS ONE-TIME ──
                    if (data.recurringExpense > 0 ||
                        data.oneTimeExpense > 0) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_recurringVsOneTime,
                        LucideIcons.repeat,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildRecurringVsOneTime(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── TOP CATEGORIES ──
                    if (data.topCategories.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_topCategories,
                        LucideIcons.chartPie,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryList(
                        data.topCategories,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── CATEGORY BY FREQUENCY ──
                    if (data.categoryByFrequency.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_mostFrequent,
                        LucideIcons.hash,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryFrequency(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── INCOME SOURCES ──
                    if (data.incomeCategories.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_incomeSources,
                        LucideIcons.trendingUp,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryList(
                        data.incomeCategories,
                        color,
                        textTheme,
                        spacing,
                        accent: color.primary,
                      ),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── ACCOUNT BREAKDOWN ──
                    if (data.accountBreakdown.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_byAccount,
                        LucideIcons.wallet,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildAccountBreakdown(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── BUDGET UTILIZATION ──
                    if (data.budgetDetails.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_budgetHealth,
                        LucideIcons.target,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildBudgetUtilization(data, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── TOP EXPENSES ──
                    if (data.topTransactions.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_biggestExpenses,
                        LucideIcons.arrowUpDown,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildTopTransactions(
                        data.topTransactions,
                        color.error,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── TOP INCOME ──
                    if (data.topIncomeTransactions.isNotEmpty) ...[
                      _sectionHeader(
                        AppLocalizations.of(context)!.recap_biggestIncome,
                        LucideIcons.arrowDownUp,
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 10),
                      _buildTopTransactions(
                        data.topIncomeTransactions,
                        color.primary,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.sectionGap),
                    ],

                    // ── DOWNLOAD BUTTON ──
                    FilledButton.icon(
                      onPressed: _downloading ? null : () => _downloadPdf(data),
                      icon: _downloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.download, size: 18),
                      label:
                          Text(_downloading ? AppLocalizations.of(context)!.stats_generating : AppLocalizations.of(context)!.stats_downloadPdf),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AmbientBrandSection(),
                  ],
                );
              },
            ),
          );
        }

  // ── SUMMARY TILE ──
  Widget _summaryTile(
    String label,
    double amount,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(amount),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── MONTH-OVER-MONTH COMPARISON ──
  Widget _buildMoMComparison(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            _momItem(
              AppLocalizations.of(context)!.recap_income,
              data.totalIncome,
              data.prevMonthIncome,
              data.incomeChange,
              color.primary,
              textTheme,
              color,
            ),
            SizedBox(width: spacing.elementGap),
            _momItem(
              AppLocalizations.of(context)!.recap_expense,
              data.totalExpense,
              data.prevMonthExpense,
              data.expenseChange,
              color.error,
              textTheme,
              color,
            ),
            SizedBox(width: spacing.elementGap),
            _momItem(
              AppLocalizations.of(context)!.recap_savings,
              data.netSavings,
              data.prevMonthSavings,
              data.prevMonthSavings != 0
                  ? (data.netSavings - data.prevMonthSavings) /
                      data.prevMonthSavings.abs() *
                      100
                  : 0,
              color.primary,
              textTheme,
              color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _momItem(
    String label,
    double current,
    double prev,
    double pctChange,
    Color accent,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    final isUp = pctChange >= 0;
    // For expense, up is bad; for income/savings, up is good
    final isExpenseLabel = label == AppLocalizations.of(context)!.recap_expense;
    final changeColor = (isUp && !isExpenseLabel) || (!isUp && isExpenseLabel)
        ? color.primary
        : color.error;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            _fmt(current),
            style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: accent),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 12,
                color: changeColor,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _delta(pctChange),
                  style: textTheme.labelSmall?.copyWith(color: changeColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HIGHLIGHTS ──
  Widget _buildHighlights(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            Row(
              children: [
                _highlightChip(
                  LucideIcons.calendar,
                  AppLocalizations.of(context)!.recap_avgPerDay,
                  _fmt(data.avgDailySpend),
                  color,
                  textTheme,
                ),
                SizedBox(width: spacing.elementGap),
                _highlightChip(
                  LucideIcons.percent,
                  AppLocalizations.of(context)!.recap_saved,
                  '${data.savingsRate.toStringAsFixed(1)}%',
                  color,
                  textTheme,
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              children: [
                _highlightChip(
                  LucideIcons.sun,
                  AppLocalizations.of(context)!.recap_weekdayAvg,
                  _fmt(data.weekdayAvg),
                  color,
                  textTheme,
                ),
                SizedBox(width: spacing.elementGap),
                _highlightChip(
                  LucideIcons.moon,
                  AppLocalizations.of(context)!.recap_weekendAvg,
                  _fmt(data.weekendAvg),
                  color,
                  textTheme,
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              children: [
                _highlightChip(
                  LucideIcons.piggyBank,
                  AppLocalizations.of(context)!.recap_budgets,
                  '${data.budgetsKept}/${data.budgetsTotal} kept',
                  color,
                  textTheme,
                ),
                SizedBox(width: spacing.elementGap),
                _highlightChip(
                  LucideIcons.trophy,
                  AppLocalizations.of(context)!.recap_badges,
                  '${data.achievementsUnlocked} unlocked',
                  color,
                  textTheme,
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              children: [
                _highlightChip(
                  LucideIcons.flame,
                  AppLocalizations.of(context)!.recap_streak,
                  '${data.currentStreak} days',
                  color,
                  textTheme,
                  accent: color.tertiary,
                ),
                SizedBox(width: spacing.elementGap),
                _highlightChip(
                  LucideIcons.award,
                  AppLocalizations.of(context)!.recap_best,
                  '${data.longestStreak} days',
                  color,
                  textTheme,
                  accent: color.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightChip(
    IconData icon,
    String label,
    String value,
    ColorScheme color,
    TextTheme textTheme, {
    Color? accent,
  }) {
    final c = accent ?? color.primary;
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DAILY SPENDING BAR CHART ──
  Widget _buildDailyChart(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final maxSpend =
        data.dailySpending.values.fold<double>(0, (a, b) => a > b ? a : b);
    final daysInMonth = DateTime(data.month.year, data.month.month + 1, 0).day;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final amount = data.dailySpending[day] ?? 0;
                  final fraction = maxSpend > 0 ? amount / maxSpend : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: Tooltip(
                        message: 'Day $day: ${_fmt(amount)}',
                        child: FractionallySizedBox(
                          heightFactor: fraction.clamp(0.02, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: amount > data.avgDailySpend
                                  ? color.error.withValues(alpha: 0.7)
                                  : color.primary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1',
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Text(
                  '$daysInMonth',
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.recap_belowAvg,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.error.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.recap_aboveAvg,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SPENDING VELOCITY ──
  Widget _buildSpendingVelocity(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final total = data.firstHalfSpend + data.secondHalfSpend;
    final firstPct = total > 0 ? data.firstHalfSpend / total : 0.5;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    Flexible(
                      flex: (firstPct * 100).round().clamp(1, 99),
                      child: Container(
                        color: color.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    Flexible(
                      flex: ((1 - firstPct) * 100).round().clamp(1, 99),
                      child: Container(
                        color: color.tertiary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1st Half',
                        style: textTheme.labelSmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                      Text(
                        _fmt(data.firstHalfSpend),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '2nd Half',
                        style: textTheme.labelSmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                      Text(
                        _fmt(data.secondHalfSpend),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── RECURRING VS ONE-TIME ──
  Widget _buildRecurringVsOneTime(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final total = data.recurringExpense + data.oneTimeExpense;
    final recurPct = total > 0 ? data.recurringExpense / total * 100 : 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Expanded(
              child: _miniStatCard(
                LucideIcons.repeat,
                AppLocalizations.of(context)!.recap_recurring,
                _fmt(data.recurringExpense),
                '${recurPct.toStringAsFixed(0)}%',
                color.secondary,
                color,
                textTheme,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _miniStatCard(
                LucideIcons.zap,
                AppLocalizations.of(context)!.recap_oneTime,
                _fmt(data.oneTimeExpense),
                '${(100 - recurPct).toStringAsFixed(0)}%',
                color.tertiary,
                color,
                textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(
    IconData icon,
    String label,
    String value,
    String pct,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(height: 6),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(pct, style: textTheme.labelSmall?.copyWith(color: accent)),
      ],
    );
  }

  // ── CATEGORY FREQUENCY ──
  Widget _buildCategoryFrequency(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: data.categoryByFrequency.asMap().entries.map((entry) {
          final cat = entry.value;
          final isLast = entry.key == data.categoryByFrequency.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${cat.count}x',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        _fmt(cat.totalAmount),
                        style: textTheme.labelSmall
                            ?.copyWith(color: color.onSurfaceVariant),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── ACCOUNT BREAKDOWN ──
  Widget _buildAccountBreakdown(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: data.accountBreakdown.asMap().entries.map((entry) {
          final acc = entry.value;
          final isLast = entry.key == data.accountBreakdown.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.name,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (acc.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor:
                                  color.outlineVariant.withValues(alpha: 0.2),
                              valueColor:
                                  AlwaysStoppedAnimation(color.tertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(acc.amount),
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${acc.percentage.toStringAsFixed(1)}%',
                          style: textTheme.labelSmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── BUDGET UTILIZATION ──
  Widget _buildBudgetUtilization(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: data.budgetDetails.asMap().entries.map((entry) {
          final b = entry.value;
          final isLast = entry.key == data.budgetDetails.length - 1;
          final pct = b.percentage.clamp(0, 150);
          final barColor = b.overBudget ? color.error : color.primary;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${_fmt(b.spent)} / ${_fmt(b.allocated)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: b.overBudget
                                ? color.error
                                : color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            color.outlineVariant.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${b.percentage.toStringAsFixed(0)}% used',
                        style: textTheme.labelSmall?.copyWith(color: barColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION HEADER ──
  Widget _sectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color.primary),
        ),
      ],
    );
  }

  // ── GENERIC CATEGORY LIST (reused for expense & income) ──
  Widget _buildCategoryList(
    List<CategorySpend> categories,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    Color? accent,
  }) {
    final barColor = accent ?? color.primary;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final cat = entry.value;
          final isLast = entry.key == categories.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (cat.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor:
                                  color.outlineVariant.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(barColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(cat.amount),
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${cat.percentage.toStringAsFixed(1)}%',
                          style: textTheme.labelSmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── GENERIC TOP TRANSACTIONS (reused for expense & income) ──
  Widget _buildTopTransactions(
    List<TransactionSummary> transactions,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final txn = entry.value;
          final isLast = entry.key == transactions.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.description.isEmpty
                                ? txn.category
                                : txn.description,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${txn.category} • ${safeDateFormat('dd MMM', AppLocalizations.of(context)!.localeName).format(txn.date)}',
                            style: textTheme.labelSmall
                                ?.copyWith(color: color.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _fmt(txn.amount),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 64,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
