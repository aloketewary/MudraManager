import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
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
  double get variancePct => lastExpense > 0 ? (variance / lastExpense * 100) : 0;
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ComparisonData> _load() async {
    final isar = ref.read(isarServiceProvider);
    final now = DateTime.now();
    final curStart = DateTime(now.year, now.month, 1);
    final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastStart = DateTime(now.year, now.month - 1, 1);
    final lastEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    // Same day cutoff in last month (e.g. if today is 15th, get 1st-15th of last month)
    final lastSameDayEnd = DateTime(
      lastStart.year,
      lastStart.month,
      math.min(now.day, DateTime(lastStart.year, lastStart.month + 1, 0).day),
      23, 59, 59,
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
              c.name, () => {'icon': c.iconName, 'cur': 0.0, 'last': 0.0});
          catMap[c.name]!['cur'] = (catMap[c.name]!['cur'] as double) + t.amount;
        }
      } else {
        curInc += t.effectiveAmount;
      }
    }
    for (final t in lastTxns) {
      if (t.isTransfer) continue;
      if (t.isExpense) {
        lastExp += t.effectiveAmount;
        if (!t.date.isAfter(lastSameDayEnd)) lastExpByThisDay += t.effectiveAmount;
        await t.category.load();
        final c = t.category.value;
        if (c != null) {
          catMap.putIfAbsent(
              c.name, () => {'icon': c.iconName, 'cur': 0.0, 'last': 0.0});
          catMap[c.name]!['last'] =
              (catMap[c.name]!['last'] as double) + t.amount;
        }
      } else {
        lastInc += t.effectiveAmount;
      }
    }

    final cats = catMap.entries
        .map((e) => _CategoryDelta(
              name: e.key,
              iconName: e.value['icon'] as String,
              current: e.value['cur'] as double,
              last: e.value['last'] as double,
            ))
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
    final now = DateTime.now();
    final curName = DateFormat('MMMM').format(now);
    final lastStart = DateTime(now.year, now.month - 1, 1);
    final lastName = DateFormat('MMMM').format(lastStart);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(title: const Text('Monthly Comparison'), elevation: 0),
      body: FutureBuilder<_ComparisonData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: List.generate(3, (_) => BudgetCardSkeleton()),
            );
          }

          final d = snap.data!;
          final curExp = GuestModeUtil.applyGuestMode(d.currentExpense, isGuest);
          final lastExp = GuestModeUtil.applyGuestMode(d.lastExpense, isGuest);
          final curInc = GuestModeUtil.applyGuestMode(d.currentIncome, isGuest);
          final lastInc = GuestModeUtil.applyGuestMode(d.lastIncome, isGuest);
          final variance = curExp - lastExp;
          final variancePct =
              lastExp > 0 ? (variance / lastExp * 100) : 0.0;
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
          final dailyAvgCur =
              dayOfMonth > 0 ? curExp / dayOfMonth : 0.0;
          final dailyAvgLast = DateTime(now.year, now.month, 0).day > 0
              ? lastExp / DateTime(now.year, now.month, 0).day
              : 0.0;
          final projected = dailyAvgCur * daysInMonth;

          // Top category delta
          final topIncrease = d.categories
              .where((c) => c.delta > 0)
              .toList();
          final topDecrease = d.categories
              .where((c) => c.delta < 0)
              .toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              setState(() => _future = _load());
              await _future;
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
                  variance, variancePct, curExp, lastExp,
                  GuestModeUtil.applyGuestMode(d.lastExpenseByThisDay, isGuest),
                  curName, lastName, accent, isDown, isFlat,
                  color, text, spacing, brightness,
                ),
                SizedBox(height: spacing.elementGap * 1.5),

                // ── 2. SMART INSIGHT ──
                _buildInsight(
                  variance, isDown, isFlat, accent,
                  topIncrease, topDecrease,
                  color, text, spacing,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── 3. MINI STATS ──
                _buildMiniStats(
                  curInc, lastInc, curExp, lastExp,
                  color, text, spacing, brightness,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── 4. CATEGORY BREAKDOWN ──
                if (d.categories.isNotEmpty) ...[
                  Text(
                    'CATEGORY IMPACT',
                    style: text.labelSmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  ...d.categories.take(8).map((cat) => _buildCategoryTile(
                        cat, isGuest, color, text, spacing, brightness,
                      )),
                  SizedBox(height: spacing.sectionGap),
                ],

                // ── 5. BEHAVIORAL STATS ──
                _buildBehavior(
                  d.currentTxnCount, d.lastTxnCount,
                  dailyAvgCur, dailyAvgLast, projected,
                  color, text, spacing, brightness,
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
    double variance, double variancePct,
    double curExp, double lastExp, double lastExpByThisDay,
    String curName, String lastName,
    Color accent, bool isDown, bool isFlat,
    ColorScheme color, TextTheme text, AppSpacing spacing, Brightness brightness,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Column(
          children: [
            // Delta amount + badge
            AnimatedBalance(
              value: variance.abs(),
              style: text.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: -0.5,
              ),
              fixedStringLength: 0,
              compact: true,
            ),
            SizedBox(height: spacing.elementGapMin),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isFlat)
                  Icon(
                    isDown ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                    size: 14,
                    color: accent,
                  ),
                if (!isFlat) SizedBox(width: spacing.elementGapMin),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    isFlat
                        ? 'No change'
                        : '${variancePct.abs().toStringAsFixed(1)}% ${isDown ? 'less' : 'more'}',
                    style: text.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            // Side-by-side months
            Row(
              children: [
                Expanded(
                  child: _buildMonthColumn(
                    curName, curExp, true, color, text, spacing,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildMonthColumn(
                    lastName, lastExp, false, color, text, spacing,
                  ),
                ),
              ],
            ),
            // "By this day last month" context line
            if (lastExpByThisDay > 0) ...[
              SizedBox(height: spacing.elementGap * 1.5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap * 1.5,
                  vertical: spacing.elementGap,
                ),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.calendarClock, size: 14, color: color.onSurfaceVariant),
                    SizedBox(width: spacing.elementGap),
                    Flexible(
                      child: Text(
                        BuddyMessages.comparisonByThisDay(
                          formatCurrency(lastExpByThisDay, code: BaseCurrency.code),
                        ),
                        style: text.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildMonthColumn(
    String label, double amount, bool isCurrent,
    ColorScheme color, TextTheme text, AppSpacing spacing,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        CurrencyText(
          amount: amount,
          fixedLength: 0,
          compact: true,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isCurrent ? color.onSurface : color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── 2. SMART INSIGHT ──

  Widget _buildInsight(
    double variance, bool isDown, bool isFlat, Color accent,
    List<_CategoryDelta> topIncrease, List<_CategoryDelta> topDecrease,
    ColorScheme color, TextTheme text, AppSpacing spacing,
  ) {
    final code = BaseCurrency.code;
    final lines = <String>[];

    // Primary insight
    if (isFlat) {
      lines.add(BuddyMessages.comparisonSpentSame);
    } else if (isDown) {
      lines.add(BuddyMessages.comparisonSpentLess(
          formatCurrencyFull(variance.abs(), code: code)));
    } else {
      lines.add(BuddyMessages.comparisonSpentMore(
          formatCurrencyFull(variance.abs(), code: code)));
    }

    // Category highlight
    if (topIncrease.isNotEmpty) {
      final t = topIncrease.first;
      lines.add(BuddyMessages.comparisonTopIncrease(
          t.name, formatCurrency(t.absDelta, code: code)));
    } else if (topDecrease.isNotEmpty) {
      final t = topDecrease.first;
      lines.add(BuddyMessages.comparisonTopDecrease(
          t.name, formatCurrency(t.absDelta, code: code)));
    }

    final icon = isFlat
        ? LucideIcons.minus
        : isDown
            ? LucideIcons.sparkles
            : LucideIcons.triangleAlert;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              lines.join('\n'),
              style: text.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. MINI STATS ──

  Widget _buildMiniStats(
    double curInc, double lastInc, double curExp, double lastExp,
    ColorScheme color, TextTheme text, AppSpacing spacing, Brightness brightness,
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
            'Income', curInc, lastInc, LucideIcons.trendingUp,
            incColor, color, text, spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _miniStat(
            'Expense', curExp, lastExp, LucideIcons.trendingDown,
            expColor, color, text, spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _miniStat(
            'Balance', curBal, lastBal, LucideIcons.wallet,
            balColor, color, text, spacing,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    String label, double current, double previous, IconData icon,
    Color accent, ColorScheme color, TextTheme text, AppSpacing spacing,
  ) {
    final pct = previous != 0
        ? ((current - previous) / previous.abs() * 100)
        : 0.0;
    final isUp = pct > 0;
    // For expense: down is good. For income/balance: up is good.
    final isGood = label == 'Expense' ? !isUp : isUp;
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
    _CategoryDelta cat, bool isGuest,
    ColorScheme color, TextTheme text, AppSpacing spacing, Brightness brightness,
  ) {
    final cur = GuestModeUtil.applyGuestMode(cat.current, isGuest);
    final last = GuestModeUtil.applyGuestMode(cat.last, isGuest);
    final delta = cur - last;
    final isUp = delta > 0;
    final isZero = delta.abs() < 1;
    final maxVal = math.max(cur, last);

    final deltaColor = isZero
        ? color.onSurfaceVariant
        : isUp
            ? FinanceColors.expenseColor(brightness)
            : FinanceColors.incomeColor(brightness);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Category icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    IconHelper.getIconData(cat.iconName),
                    size: 16,
                    color: color.primary,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.elementGapUltraMin),
                      Text(
                        '${formatCurrency(cur, code: BaseCurrency.code)} vs ${formatCurrency(last, code: BaseCurrency.code)}',
                        style: text.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delta chip
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isZero)
                        Icon(
                          isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                          size: 12,
                          color: deltaColor,
                        ),
                      if (!isZero) SizedBox(width: spacing.elementGapUltraMin),
                      Text(
                        isZero
                            ? '—'
                            : formatCurrency(delta.abs(), code: BaseCurrency.code),
                        style: text.labelSmall?.copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            // Dual progress bars
            if (maxVal > 0) ...[
              _dualBar(cur, maxVal, color.primary, spacing),
              SizedBox(height: spacing.elementGapMin),
              _dualBar(last, maxVal, color.primary.withValues(alpha: 0.35), spacing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dualBar(double value, double max, Color barColor, AppSpacing spacing) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: max > 0 ? (value / max).clamp(0.0, 1.0) : 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: 4,
          backgroundColor: barColor.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation(barColor),
        ),
      ),
    );
  }

  // ── 5. BEHAVIORAL STATS ──

  Widget _buildBehavior(
    int curTxnCount, int lastTxnCount,
    double dailyAvgCur, double dailyAvgLast, double projected,
    ColorScheme color, TextTheme text, AppSpacing spacing, Brightness brightness,
  ) {
    final code = BaseCurrency.code;
    final items = <_BehaviorItem>[];

    // Transaction count
    if (curTxnCount > 0 || lastTxnCount > 0) {
      items.add(_BehaviorItem(
        icon: LucideIcons.hash,
        message: BuddyMessages.comparisonTxnCount(curTxnCount, lastTxnCount),
      ));
    }

    // Daily average
    if (dailyAvgCur > 0 || dailyAvgLast > 0) {
      items.add(_BehaviorItem(
        icon: LucideIcons.calendarDays,
        message: BuddyMessages.comparisonDailyAvg(
          formatCurrency(dailyAvgCur, code: code),
          formatCurrency(dailyAvgLast, code: code),
        ),
      ));
    }

    // Prediction
    if (projected > 0) {
      items.add(_BehaviorItem(
        icon: LucideIcons.sparkles,
        message: BuddyMessages.comparisonPrediction(
          formatCurrency(projected, code: code),
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSIGHTS',
          style: text.labelSmall?.copyWith(
            color: color.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: color.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: color.primary),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        item.message,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _BehaviorItem {
  final IconData icon;
  final String message;
  const _BehaviorItem({required this.icon, required this.message});
}
