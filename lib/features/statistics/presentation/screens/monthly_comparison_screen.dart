import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/shared/widgets/month_picker_sheet.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

// ── Data model ──

class _ComparisonData {
  final double currentIncome, currentExpense, lastIncome, lastExpense;
  final double lastExpenseByThisDay;
  final int currentTxnCount, lastTxnCount;
  final List<_CategoryDelta> categories;

  _ComparisonData({
    required this.currentIncome,
    required this.currentExpense,
    required this.lastIncome,
    required this.lastExpense,
    required this.lastExpenseByThisDay,
    required this.currentTxnCount,
    required this.lastTxnCount,
    required this.categories,
  });

  double get variance => currentExpense - lastExpense;
  double get variancePct =>
      lastExpense > 0 ? (variance / lastExpense * 100) : 0;
  bool get isDown => variance < 0;
  bool get isFlat => variance.abs() < 1;
}

class _CategoryDelta {
  final String name, iconName;
  final double current, last;

  _CategoryDelta({
    required this.name,
    required this.iconName,
    required this.current,
    required this.last,
  });

  double get delta => current - last;
  double get absDelta => delta.abs();
  double get pct => last > 0 ? (delta / last * 100) : (current > 0 ? 100 : 0);
}

// ── Screen ──

class MonthlyComparisonScreen extends ConsumerStatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  ConsumerState<MonthlyComparisonScreen> createState() =>
      _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState
    extends ConsumerState<MonthlyComparisonScreen> {
  late Future<_ComparisonData> _future;
  late DateTime _compareMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _compareMonth = DateTime(now.year, now.month - 1, 1);
    _future = _load();
  }

  Future<void> _pickCompareMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showMonthPicker(
      context: context,
      initialMonth: _compareMonth,
      lastMonth: DateTime(now.year, now.month - 1, 1),
    );
    if (picked != null) {
      setState(() {
        _compareMonth = picked;
        _future = _load();
      });
    }
  }

  Future<_ComparisonData> _load() async {
    final isar = ref.read(isarServiceProvider);
    final now = DateTime.now();
    final curStart = DateTime(now.year, now.month, 1);
    final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastStart = _compareMonth;
    final lastEnd =
        DateTime(lastStart.year, lastStart.month + 1, 0, 23, 59, 59);
    final lastSameDayEnd = DateTime(
      lastStart.year,
      lastStart.month,
      math.min(now.day, DateTime(lastStart.year, lastStart.month + 1, 0).day),
      23,
      59,
      59,
    );

    final db = await isar.getInstance();
    final curTxns =
        await db.transactions.where().dateBetween(curStart, curEnd).findAll();
    final lastTxns =
        await db.transactions.where().dateBetween(lastStart, lastEnd).findAll();

    double curInc = 0, curExp = 0, lastInc = 0, lastExp = 0;
    double lastExpByThisDay = 0;
    final catMap = <String, Map<String, dynamic>>{};

    for (final t in curTxns) {
      if (t.isTransfer) continue;
      if (t.isExpense) {
        curExp += t.effectiveAmount;
        await t.category.load();
        final c = t.category.value;
        if (c != null) {
          catMap.putIfAbsent(
            c.name,
            () => {'icon': c.iconName, 'cur': 0.0, 'last': 0.0},
          );
          catMap[c.name]!['cur'] =
              (catMap[c.name]!['cur'] as double) + t.amount;
        }
      } else {
        curInc += t.effectiveAmount;
      }
    }
    for (final t in lastTxns) {
      if (t.isTransfer) continue;
      if (t.isExpense) {
        lastExp += t.effectiveAmount;
        if (!t.date.isAfter(lastSameDayEnd)) {
          lastExpByThisDay += t.effectiveAmount;
        }
        await t.category.load();
        final c = t.category.value;
        if (c != null) {
          catMap.putIfAbsent(
            c.name,
            () => {'icon': c.iconName, 'cur': 0.0, 'last': 0.0},
          );
          catMap[c.name]!['last'] =
              (catMap[c.name]!['last'] as double) + t.amount;
        }
      } else {
        lastInc += t.effectiveAmount;
      }
    }

    final cats = catMap.entries
        .map(
          (e) => _CategoryDelta(
            name: e.key,
            iconName: e.value['icon'] as String,
            current: e.value['cur'] as double,
            last: e.value['last'] as double,
          ),
        )
        .toList()
      ..sort((a, b) => b.absDelta.compareTo(a.absDelta));

    return _ComparisonData(
      currentIncome: curInc,
      currentExpense: curExp,
      lastIncome: lastInc,
      lastExpense: lastExp,
      lastExpenseByThisDay: lastExpByThisDay,
      currentTxnCount: curTxns.where((t) => !t.isTransfer).length,
      lastTxnCount: lastTxns.where((t) => !t.isTransfer).length,
      categories: cats,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final isGuest = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final ctxt = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final curName = safeDateFormat('MMMM', ctxt.localeName).format(now);
    final lastName =
        safeDateFormat('MMMM yyyy', ctxt.localeName).format(_compareMonth);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title_compareMonths),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => _pickCompareMonth(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.calendarSearch,
                    size: 16,
                    color: color.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    safeDateFormat('MMM yy', ctxt.localeName)
                        .format(_compareMonth),
                    style: text.labelLarge?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_ComparisonData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: List.generate(3, (_) => const BudgetCardSkeleton()),
            );
          }

          final d = snap.data!;
          final curExp =
              GuestModeUtil.applyGuestMode(d.currentExpense, isGuest);
          final lastExp = GuestModeUtil.applyGuestMode(d.lastExpense, isGuest);
          final curInc = GuestModeUtil.applyGuestMode(d.currentIncome, isGuest);
          final lastInc = GuestModeUtil.applyGuestMode(d.lastIncome, isGuest);
          final variance = curExp - lastExp;
          final variancePct = lastExp > 0 ? (variance / lastExp * 100) : 0.0;
          final isDown = variance < 0;
          final isFlat = variance.abs() < 1;

          final accent = isFlat
              ? color.primary
              : isDown
                  ? FinanceColors.incomeColor(brightness)
                  : FinanceColors.expenseColor(brightness);

          // Prediction: project current month-end based on daily avg so far
          final dayOfMonth = now.day;
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final dailyAvgCur = dayOfMonth > 0 ? curExp / dayOfMonth : 0.0;
          final dailyAvgLast = DateTime(now.year, now.month, 0).day > 0
              ? lastExp / DateTime(now.year, now.month, 0).day
              : 0.0;
          final projected = dailyAvgCur * daysInMonth;

          // Top category delta
          final topIncrease = d.categories.where((c) => c.delta > 0).toList();
          final topDecrease = d.categories.where((c) => c.delta < 0).toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              final f = _load();
              setState(() => _future = f);
              await f;
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── 1. HERO ──
                _buildHero(
                  curInc,
                  lastInc,
                  curExp,
                  lastExp,
                  variance,
                  variancePct,
                  GuestModeUtil.applyGuestMode(d.lastExpenseByThisDay, isGuest),
                  curName,
                  lastName,
                  accent,
                  isDown,
                  isFlat,
                  color,
                  text,
                  spacing,
                  brightness,
                  ctxt,
                ),
                SizedBox(height: spacing.elementGap),

                // ── 2. VERDICT ──
                _buildVerdict(
                  variance,
                  isDown,
                  isFlat,
                  accent,
                  topIncrease,
                  topDecrease,
                  projected,
                  color,
                  text,
                  spacing,
                  ctxt,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── 3. INCOME / EXPENSE / BALANCE ──
                _buildMiniStats(
                  curInc,
                  lastInc,
                  curExp,
                  lastExp,
                  color,
                  text,
                  spacing,
                  brightness,
                  ctxt,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── 4. CATEGORY CHART ──
                if (d.categories
                    .where((c) => c.current > 0 || c.last > 0)
                    .isNotEmpty) ...[
                  _buildCategoryChart(
                    d.categories.take(5).toList(),
                    curName,
                    lastName,
                    color,
                    text,
                    spacing,
                    brightness,
                    ctxt,
                  ),
                  SizedBox(height: spacing.sectionGap),
                ],

                // ── 5. SPENDING PACE ──
                _buildPaceCard(
                  dailyAvgCur,
                  dailyAvgLast,
                  projected,
                  curName,
                  lastName,
                  color,
                  text,
                  spacing,
                  brightness,
                  ctxt,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── 6. CATEGORY IMPACT ──
                if (d.categories.isNotEmpty) ...[
                  _sectionLabel(ctxt.stats_categoryImpact, color, text),
                  SizedBox(height: spacing.elementGap),
                  ...d.categories.take(6).map(
                        (cat) => _buildCategoryTile(
                          cat,
                          isGuest,
                          color,
                          text,
                          spacing,
                          brightness,
                        ),
                      ),
                  SizedBox(height: spacing.sectionGap),
                ],

                // ── 7. ACTIVITY ──
                _buildActivityRow(
                  d.currentTxnCount,
                  d.lastTxnCount,
                  curName,
                  lastName,
                  color,
                  text,
                  spacing,
                ),

                SizedBox(height: spacing.sectionGap),
                const AmbientBrandSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 1. HERO ──

  Widget _buildHero(
    double curInc,
    double lastInc,
    double curExp,
    double lastExp,
    double variance,
    double variancePct,
    double lastExpByThisDay,
    String curName,
    String lastName,
    Color accent,
    bool isDown,
    bool isFlat,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final code = BaseCurrency.code;
    final incColor = FinanceColors.incomeColor(brightness);
    final expColor = FinanceColors.expenseColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: Text(
                  curName.split(' ').first,
                  textAlign: TextAlign.center,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  lastName.split(' ').first,
                  textAlign: TextAlign.center,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
          const SizedBox(height: 12),
          // Income row
          _heroRow(
            ctxt.stats_income,
            curInc,
            lastInc,
            incColor,
            code,
            color,
            text,
            brightness,
          ),
          const SizedBox(height: 8),
          // Expense row
          _heroRow(
            ctxt.stats_expense,
            curExp,
            lastExp,
            expColor,
            code,
            color,
            text,
            brightness,
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          // Net row
          _heroRow(
            ctxt.stats_net,
            curInc - curExp,
            lastInc - lastExp,
            (curInc - curExp) >= 0 ? incColor : expColor,
            code,
            color,
            text,
            brightness,
          ),
          if (lastExpByThisDay > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Text(
                'By day ${DateTime.now().day}: ${formatCurrencyCompact(lastExpByThisDay, code: code)} in ${lastName.split(' ').first}',
                style: text.bodySmall?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroRow(
    String label,
    double curVal,
    double lastVal,
    Color rowColor,
    String code,
    ColorScheme color,
    TextTheme text,
    Brightness brightness, {
    String? customCur,
    String? customDelta,
    Color? deltaColor,
  }) {
    final delta = curVal - lastVal;
    final pct = lastVal > 0 ? (delta / lastVal * 100) : 0.0;
    final isUp = delta > 0;
    final dColor = deltaColor ??
        (isUp
            ? FinanceColors.expenseColor(brightness)
            : FinanceColors.incomeColor(brightness));

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: text.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            customCur ?? formatCurrencyCompact(curVal, code: code),
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(
            formatCurrencyCompact(lastVal, code: code),
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: dColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Tone.current.borderRadius),
            ),
            child: Text(
              customDelta ??
                  (delta.abs() < 1
                      ? '\u2014'
                      : '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%'),
              textAlign: TextAlign.center,
              style: text.labelSmall
                  ?.copyWith(color: dColor, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. VERDICT ──

  Widget _buildVerdict(
    double variance,
    bool isDown,
    bool isFlat,
    Color accent,
    List<_CategoryDelta> topIncrease,
    List<_CategoryDelta> topDecrease,
    double projected,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final code = BaseCurrency.code;
    String headline;
    String detail;
    IconData icon;

    if (isFlat) {
      headline = ctxt.stats_steadyHeadline;
      detail = ctxt.stats_steadyDetail;
      icon = LucideIcons.shieldCheck;
    } else if (isDown) {
      headline = ctxt.stats_doingGreatHeadline;
      detail =
          'Spending is down ${formatCurrencyCompact(variance.abs(), code: code)}. ';
      if (topDecrease.isNotEmpty) {
        detail += '${topDecrease.first.name} dropped the most.';
      }
      icon = LucideIcons.trendingDown;
    } else {
      headline = ctxt.stats_spendingUpHeadline;
      detail =
          '${formatCurrencyCompact(variance.abs(), code: code)} more than before. ';
      if (topIncrease.isNotEmpty) {
        detail += '${topIncrease.first.name} grew the most.';
      }
      icon = LucideIcons.trendingUp;
    }

    if (projected > 0) {
      detail +=
          '\nOn track to spend ${formatCurrencyCompact(projected, code: code)} this month.';
    }

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Tone.current.borderRadius),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. MINI STATS ──

  Widget _buildMiniStats(
    double curInc,
    double lastInc,
    double curExp,
    double lastExp,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final incColor = FinanceColors.incomeColor(brightness);
    final expColor = FinanceColors.expenseColor(brightness);
    final curBal = curInc - curExp;
    final lastBal = lastInc - lastExp;
    final balColor = curBal >= 0 ? incColor : expColor;

    return Row(
      children: [
        Expanded(
          child: _miniStat(
            ctxt.stats_income,
            curInc,
            lastInc,
            LucideIcons.trendingUp,
            incColor,
            color,
            text,
            spacing,
            ctxt,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _miniStat(
            ctxt.stats_expense,
            curExp,
            lastExp,
            LucideIcons.trendingDown,
            expColor,
            color,
            text,
            spacing,
            ctxt,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _miniStat(
            'Balance',
            curBal,
            lastBal,
            LucideIcons.wallet,
            balColor,
            color,
            text,
            spacing,
            ctxt,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    String label,
    double current,
    double previous,
    IconData icon,
    Color accent,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final pct =
        previous != 0 ? ((current - previous) / previous.abs() * 100) : 0.0;
    final isUp = pct > 0;
    // For expense: down is good. For income/balance: up is good.
    final isGood = label == ctxt.stats_expense ? !isUp : isUp;
    final changeColor = previous == 0
        ? color.onSurfaceVariant
        : isGood
            ? FinanceColors.incomeColor(Theme.of(context).brightness)
            : FinanceColors.expenseColor(Theme.of(context).brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: accent),
          SizedBox(height: spacing.elementGapMin),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: color.onSurfaceVariant),
          ),
          SizedBox(height: spacing.elementGapMin),
          AnimatedBalance(
            value: current,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
            fixedStringLength: 0,
            compact: true,
          ),
          if (previous != 0) ...[
            SizedBox(height: spacing.elementGapMin),
            Text(
              '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%',
              style: text.labelSmall?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. CATEGORY TILE ──

  Widget _buildCategoryTile(
    _CategoryDelta cat,
    bool isGuest,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final cur = GuestModeUtil.applyGuestMode(cat.current, isGuest);
    final last = GuestModeUtil.applyGuestMode(cat.last, isGuest);
    final delta = cur - last;
    final isUp = delta > 0;
    final isZero = delta.abs() < 1;
    final pct = cat.pct;

    final deltaColor = isZero
        ? color.onSurfaceVariant
        : isUp
            ? FinanceColors.expenseColor(brightness)
            : FinanceColors.incomeColor(brightness);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardInner,
          vertical: spacing.elementGap * 1.2,
        ),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Icon(
                IconHelper.getIconData(cat.iconName),
                size: 16,
                color: deltaColor,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${formatCurrencyCompact(cur, code: BaseCurrency.code)} vs ${formatCurrencyCompact(last, code: BaseCurrency.code)}',
                    style: text.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Text(
                isZero ? '—' : '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%',
                style: text.labelSmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. SPENDING PACE ──

  Widget _buildPaceCard(
    double dailyAvgCur,
    double dailyAvgLast,
    double projected,
    String curName,
    String lastName,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final maxAvg = math.max(dailyAvgCur, dailyAvgLast);
    final curFrac = maxAvg > 0 ? (dailyAvgCur / maxAvg).clamp(0.0, 1.0) : 0.0;
    final lastFrac = maxAvg > 0 ? (dailyAvgLast / maxAvg).clamp(0.0, 1.0) : 0.0;
    final code = BaseCurrency.code;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.gauge, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Text(
                ctxt.stats_dailySpendingPace,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current month bar
          _paceBar(
            curName.split(' ').first,
            dailyAvgCur,
            curFrac,
            color.primary,
            code,
            color,
            text,
          ),
          const SizedBox(height: 10),
          // Compare month bar
          _paceBar(
            lastName.split(' ').first,
            dailyAvgLast,
            lastFrac,
            color.primary.withValues(alpha: 0.4),
            code,
            color,
            text,
          ),
          if (projected > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 14, color: color.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Projected: ${formatCurrencyCompact(projected, code: code)} this month',
                    style: text.bodySmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w600,
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

  Widget _paceBar(
    String label,
    double value,
    double fraction,
    Color barColor,
    String code,
    ColorScheme color,
    TextTheme text,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: text.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: barColor.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatCurrencyCompact(value, code: code),
          style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── 6. ACTIVITY ROW ──

  Widget _buildActivityRow(
    int curCount,
    int lastCount,
    String curName,
    String lastName,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
  ) {
    final delta = curCount - lastCount;
    final isUp = delta > 0;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.activity, size: 18, color: color.primary),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              '$curCount transactions this month vs $lastCount in ${lastName.split(' ').first}',
              style: text.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
          ),
          if (delta != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isUp ? color.primary : color.tertiary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Text(
                '${isUp ? '+' : ''}$delta',
                style: text.labelSmall?.copyWith(
                  color: isUp ? color.primary : color.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── CATEGORY CHART ──

  Widget _buildCategoryChart(
    List<_CategoryDelta> categories,
    String curName,
    String lastName,
    ColorScheme color,
    TextTheme text,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final maxVal = categories.fold<double>(
      0,
      (m, c) => math.max(m, math.max(c.current, c.last)),
    );
    if (maxVal <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.chartBarBig, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Text(
                ctxt.stats_topCategories,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Legend
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                curName.split(' ').first,
                style: text.labelSmall?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                lastName.split(' ').first,
                style: text.labelSmall?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bars
          ...categories.map((cat) {
            final curFrac = (cat.current / maxVal).clamp(0.0, 1.0);
            final lastFrac = (cat.last / maxVal).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Current month bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: curFrac),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: color.primary.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(color.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Compare month bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: lastFrac),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: color.primary.withValues(alpha: 0.03),
                        valueColor: AlwaysStoppedAnimation(
                          color.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── HELPERS ──

  Widget _sectionLabel(String label, ColorScheme color, TextTheme text) {
    return Text(
      label,
      style: text.labelSmall?.copyWith(
        color: color.onSurfaceVariant.withValues(alpha: 0.5),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
