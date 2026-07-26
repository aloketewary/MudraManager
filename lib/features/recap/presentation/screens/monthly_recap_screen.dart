import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_service.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_pdf.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/widgets/progress_ring.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

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
    final isarService = ref.read(isarServiceProvider);
    return MonthlyRecapService(isarService)
        .generate(_selectedMonth, currency: _currency);
  }

  Future<void> _downloadPdf(MonthlyRecapData data, AppSpacing spacing) async {
    setState(() => _downloading = true);
    try {
      final bytes = await MonthlyRecapPdf.generate(data);
      final monthStr = safeDateFormat('MMM_yyyy').format(data.month);
      await saveExportedFile(
        bytes,
        'MudraManager_Recap_$monthStr.pdf',
        askUser: true,
      );
      SnackbarService.success(BuddyMessages.exportSuccess, spacing);
    } catch (e) {
      SnackbarService.error(BuddyMessages.exportFailed('$e'), spacing);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _fmt(double v) =>
      '$_currency${NumberFormat('#,##0', 'en_IN').format(v.round())}';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final monthName =
        safeDateFormat('MMMM yyyy', l10n.localeName).format(_selectedMonth);

    return ScreenShell(
      config: ScreenShellConfig(
        title: '${l10n.recap_recapTitle} — $monthName',
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: FutureBuilder<MonthlyRecapData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children:
                  List.generate(4, (_) => const DashboardCardSkeleton()),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── 1. HERO SECTION ──
              _buildHeroSection(data, color, textTheme, spacing, isDark, monthName, l10n),
              SizedBox(height: spacing.sectionGap),

              // ── 2. AI INSIGHT CARD ──
              if (!data.insight.isEmpty) ...[
                TypeSectionHeader(
                  label: 'Summary',
                  icon: LucideIcons.sparkles,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                _buildInsightCard(data.insight, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 3. ACHIEVEMENT/WARNING ──
              if (data.achievements.isNotEmpty) ...[
                TypeSectionHeader(
                  label: 'Achievements',
                  icon: LucideIcons.trophy,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                _buildAchievements(data.achievements, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 4. CATEGORY CHANGE LEADERS ──
              if (data.categoryChanges.isNotEmpty) ...[
                TypeSectionHeader(
                  label: l10n.recap_topCategories,
                  icon: LucideIcons.chartPie,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                _buildCategoryChanges(data.categoryChanges, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 5. BUDGET UTILIZATION ──
              if (data.budgetDetails.isNotEmpty) ...[
                TypeSectionHeader(
                  label: l10n.recap_budgetHealth,
                  icon: LucideIcons.gauge,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                _buildBudgetUtilization(data.budgetDetails, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 6. BIGGEST EXPENSES ──
              if (data.topTransactions.isNotEmpty) ...[
                TypeSectionHeader(
                  label: l10n.recap_biggestExpenses,
                  icon: LucideIcons.trendingDown,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                _buildTopExpenses(data.topTransactions, color, textTheme, spacing, l10n),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── DOWNLOAD PDF ──
              FilledButton.icon(
                onPressed: _downloading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _downloadPdf(data, spacing);
                      },
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
                label: Text(
                    _downloading ? l10n.stats_generating : l10n.stats_downloadPdf,),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
            ],
          );
        },
      ),
    );
  }

  // ── HERO SECTION ──
  Widget _buildHeroSection(
    MonthlyRecapData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    String monthName,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.cardInner,
      ),
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
          // Month + Download
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthName,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.transactionCount} transactions',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.download),
                onPressed: _downloading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _downloadPdf(data, spacing);
                      },
                tooltip: l10n.stats_downloadPdf,
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),

          // Income / Expense / Saved
          Row(
            children: [
              _summaryTile(l10n.recap_income, data.totalIncome, color.primary,
                  color, textTheme, spacing,),
              SizedBox(width: spacing.elementGap),
              _summaryTile(l10n.recap_expense, data.totalExpense, color.error,
                  color, textTheme, spacing,),
              SizedBox(width: spacing.elementGap),
              _summaryTile(l10n.recap_saved, data.netSavings,
                  data.netSavings >= 0 ? color.primary : color.error,
                  color, textTheme, spacing,),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),

          // Financial Score
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ProgressRing(
                  progress: data.financialScore / 100,
                  color: _scoreColor(data.financialScore, color),
                  size: 44,
                  strokeWidth: 5,
                  labelBuilder: (_) => Text(
                    '${data.financialScore}',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(data.financialScore, color),
                    ),
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    'Financial Score',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (data.financialScoreDelta != 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (data.financialScoreDelta > 0
                              ? FinanceColors.incomeColor(
                                  Theme.of(context).brightness,)
                              : FinanceColors.expenseColor(
                                  Theme.of(context).brightness,))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.financialScoreDelta > 0
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 12,
                          color: data.financialScoreDelta > 0
                              ? FinanceColors.incomeColor(
                                  Theme.of(context).brightness,)
                              : FinanceColors.expenseColor(
                                  Theme.of(context).brightness,),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${data.financialScoreDelta.abs()}',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: data.financialScoreDelta > 0
                                ? FinanceColors.incomeColor(
                                    Theme.of(context).brightness,)
                                : FinanceColors.expenseColor(
                                    Theme.of(context).brightness,),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score, ColorScheme color) {
    if (score >= 80) return color.primary;
    if (score >= 50) return color.tertiary;
    return color.error;
  }

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
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap,
          vertical: spacing.elementGap * 1.5,
        ),
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
              style: textTheme.labelSmall
                  ?.copyWith(color: color.onSurfaceVariant),
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

  // ── AI INSIGHT CARD ──
  Widget _buildInsightCard(
    RecapInsight insight,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...insight.lines.map((line) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
                    Expanded(
                      child: Text(
                        line,
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),),
          if (insight.suggestedFocus != null) ...[
            SizedBox(height: spacing.elementGap),
            Container(
              padding: EdgeInsets.all(spacing.elementGap),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.lightbulb, size: 16, color: color.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next month: ${insight.suggestedFocus}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ACHIEVEMENTS/WARNINGS ──
  Widget _buildAchievements(
    List<RecapAchievement> achievements,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Column(
      children: achievements.map((a) {
        final accent = a.isWarning ? color.error : color.primary;
        final bg = accent.withValues(alpha: 0.08);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.elementGap),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    a.isWarning
                        ? LucideIcons.alertTriangle
                        : LucideIcons.trophy,
                    size: spacing.iconSM,
                    color: accent,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    a.text,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── CATEGORY CHANGE LEADERS ──
  Widget _buildCategoryChanges(
    List<CategoryChange> changes,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final b = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: changes.asMap().entries.map((entry) {
          final c = entry.value;
          final isLast = entry.key == changes.length - 1;
          final deltaColor = c.increased
              ? FinanceColors.expenseColor(b)
              : FinanceColors.incomeColor(b);

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.cardVertical,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      c.increased
                          ? LucideIcons.arrowUp
                          : LucideIcons.arrowDown,
                      size: 12,
                      color: deltaColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _fmt(c.delta.abs()),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: spacing.cardInner,
                  endIndent: spacing.cardInner,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── BUDGET UTILIZATION ──
  Widget _buildBudgetUtilization(
    List<BudgetUtilization> budgets,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: budgets.asMap().entries.map((entry) {
          final b = entry.value;
          final isLast = entry.key == budgets.length - 1;
          final barColor = b.overBudget ? color.error : color.primary;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.cardVertical,
                ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (b.overBudget) ...[
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 12,
                            color: color.error,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${_fmt(b.spent)} / ${_fmt(b.allocated)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: b.overBudget
                                ? color.error
                                : color.onSurfaceVariant,
                            fontWeight: b.overBudget
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (b.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            color.outlineVariant.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: spacing.cardInner,
                  endIndent: spacing.cardInner,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── BIGGEST EXPENSES ──
  Widget _buildTopExpenses(
    List<TransactionSummary> transactions,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final txn = entry.value;
          final isLast = entry.key == transactions.length - 1;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.cardVertical,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
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
                            '${txn.category} • ${safeDateFormat('dd MMM', l10n.localeName).format(txn.date)}',
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
                        color: color.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: spacing.cardInner + 40,
                  endIndent: spacing.cardInner,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
