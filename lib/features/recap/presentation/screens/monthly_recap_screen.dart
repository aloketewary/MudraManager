import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
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
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

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
              padding: EdgeInsets.all(spacing.cardHorizontal),
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
                _buildInsightCard(data.insight, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 3. ACHIEVEMENT/WARNING ──
              if (data.achievements.isNotEmpty) ...[
                _buildAchievements(data.achievements, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 4. CATEGORY CHANGE LEADERS ──
              if (data.categoryChanges.isNotEmpty) ...[
                _sectionHeader(l10n.recap_topCategories, LucideIcons.arrowLeftRight, color, textTheme),
                SizedBox(height: spacing.elementGap),
                _buildCategoryChanges(data.categoryChanges, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 5. BUDGET UTILIZATION ──
              if (data.budgetDetails.isNotEmpty) ...[
                _sectionHeader(l10n.recap_budgetHealth, LucideIcons.target, color, textTheme),
                SizedBox(height: spacing.elementGap),
                _buildBudgetUtilization(data.budgetDetails, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── 6. BIGGEST EXPENSES ──
              if (data.topTransactions.isNotEmpty) ...[
                _sectionHeader(l10n.recap_biggestExpenses, LucideIcons.arrowUpDown, color, textTheme),
                SizedBox(height: spacing.elementGap),
                _buildTopExpenses(data.topTransactions, color, textTheme, spacing, l10n),
                SizedBox(height: spacing.sectionGap),
              ],

              // ── DOWNLOAD PDF ──
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
                onPressed: _downloading ? null : () {},
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
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap,
            ),
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.gauge, size: spacing.iconSM, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    'Financial Score',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                ),
                Text(
                  '${data.financialScore}/100',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _scoreColor(data.financialScore, color),
                  ),
                ),
                if (data.financialScoreDelta != 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${data.financialScoreDelta > 0 ? "↑" : "↓"}${data.financialScoreDelta.abs()}',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: data.financialScoreDelta > 0
                          ? FinanceColors.incomeColor(Theme.of(context).brightness)
                          : FinanceColors.expenseColor(Theme.of(context).brightness),
                    ),
                  ),
                ],
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
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: spacing.iconSM, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(
                'Summary',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
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
          padding: EdgeInsets.only(bottom: spacing.elementGapMin),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  a.isWarning ? LucideIcons.alertTriangle : LucideIcons.trophy,
                  size: spacing.iconSM,
                  color: accent,
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
        border: Border.all(color: color.outlineVariant),
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
                  vertical: spacing.elementGap + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${c.increased ? "+" : "-"}${_fmt(c.delta.abs())}',
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
    List<BudgetUtilization> budgets,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
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
                  vertical: spacing.elementGap + 2,
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
                  color: color.outlineVariant.withValues(alpha: 0.4),
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
        border: Border.all(color: color.outlineVariant),
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
                  vertical: spacing.elementGap + 2,
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
                  indent: 56,
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
}
