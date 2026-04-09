import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'dart:math' as math;

class AdaptiveBudgetDashboard extends ConsumerStatefulWidget {
  const AdaptiveBudgetDashboard({super.key});

  @override
  ConsumerState<AdaptiveBudgetDashboard> createState() =>
      _AdaptiveBudgetDashboardState();
}

class _AdaptiveBudgetDashboardState
    extends ConsumerState<AdaptiveBudgetDashboard> {
  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(ctxt.budget_dashboardPageTitle),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addBudget);
            },
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noBudgets,
              iconData: LucideIcons.chartPie,
            );
          }

          final totalBudget =
              budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
          final remaining = totalBudget - totalSpent;
          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final daysLeft = daysInMonth - now.day + 1;
          final safePerDay = daysLeft > 0 ? remaining / daysLeft : 0.0;
          final pct = totalBudget > 0
              ? (totalSpent / totalBudget).clamp(0.0, 1.5)
              : 0.0;
          final isOver = totalSpent > totalBudget;

          final accent = isOver
              ? FinanceColors.expenseColor(brightness)
              : pct > 0.8
                  ? FinanceColors.statusWarning
                  : FinanceColors.incomeColor(brightness);

          // Sort: over-budget first, then by % used descending
          final sorted = List<BudgetWithProgress>.from(budgets)
            ..sort((a, b2) {
              final aPct =
                  a.budget.amount > 0 ? a.spent / a.budget.amount : 0.0;
              final bPct =
                  b2.budget.amount > 0 ? b2.spent / b2.budget.amount : 0.0;
              return bPct.compareTo(aPct);
            });

          // Highlight = most critical (highest % used), extracted from list
          BudgetWithProgress? highlight;
          List<BudgetWithProgress> rest = sorted;
          if (sorted.length > 1) {
            highlight = sorted.first;
            rest = sorted.sublist(1);
          } else if (sorted.length == 1) {
            highlight = sorted.first;
            rest = [];
          }

          // Group remaining: over-budget + on-track
          final overBudget = rest.where((b) => b.spent > b.budget.amount).toList();
          final onTrack = rest.where((b) => b.spent <= b.budget.amount).toList();

          // Emotional headline
          final emotionLine = isOver
              ? ctxt.budget_emotionExceeded
              : pct > 0.8
                  ? ctxt.budget_emotionAlmostThere
                  : pct > 0.5
                      ? ctxt.budget_emotionHalfway
                      : ctxt.budget_emotionUnderControl;

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(budgetsWithProgressProvider);
            }),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. HERO ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.cardVertical,
                      spacing.cardHorizontal,
                      spacing.elementGap,
                    ),
                    child: _buildHero(
                      remaining, totalBudget, totalSpent, pct, isOver,
                      accent, emotionLine, color, textTheme, spacing, isDark, ctxt,
                    ),
                  ),
                ),

                // ── 2. SMART INSIGHT ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.elementGap,
                    ),
                    child: _buildInsight(
                      pct, safePerDay, daysLeft, isOver, remaining,
                      color, textTheme, spacing, brightness,
                    ),
                  ),
                ),

                // ── 3. HIGHLIGHT CARD ──
                if (highlight != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.sectionGap,
                        spacing.cardHorizontal,
                        spacing.elementGap,
                      ),
                      child: _buildHighlightCard(
                        highlight, color, textTheme, spacing, brightness, ctxt,
                      ),
                    ),
                  ),

                // ── 4. OVER BUDGET SECTION ──
                if (overBudget.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.sectionGap,
                        spacing.cardHorizontal,
                        spacing.elementGap,
                      ),
                      child: _sectionHeader(
                        ctxt.budget_overBudgetSection,
                        LucideIcons.triangleAlert,
                        FinanceColors.expenseColor(brightness),
                        textTheme,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildBudgetTile(
                          overBudget[i], color, textTheme, spacing, brightness, ctxt,
                        ),
                        childCount: overBudget.length,
                      ),
                    ),
                  ),
                ],

                // ── 5. ON TRACK SECTION ──
                if (onTrack.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.sectionGap,
                        spacing.cardHorizontal,
                        spacing.elementGap,
                      ),
                      child: _sectionHeader(
                        sorted.length > 1
                            ? ctxt.budget_onTrackSection
                            : ctxt.budget_activeBudgets,
                        LucideIcons.shieldCheck,
                        FinanceColors.incomeColor(brightness),
                        textTheme,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildBudgetTile(
                          onTrack[i], color, textTheme, spacing, brightness, ctxt,
                        ),
                        childCount: onTrack.length,
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: spacing.sectionGap),
                    child: const AmbientBrandSection(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        kBottomNavigationBarHeight +
                        spacing.sectionGap,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => ListView(
          children: List.generate(4, (_) => const BudgetCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  // ── SECTION HEADER ──

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color accent,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }

  // ── 1. HERO ──

  Widget _buildHero(
    double remaining, double total, double spent, double pct, bool isOver,
    Color accent, String emotionLine, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, bool isDark, AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
      decoration: BoxDecoration(
        color: color.primaryContainer,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 104,
            height: 104,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CustomPaint(
                painter: _BudgetRingPainter(
                  progress: value,
                  accent: color.onPrimaryContainer,
                  trackColor: color.onPrimaryContainer.withValues(alpha: 0.08),
                  strokeWidth: 10,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBalance(
                        value: remaining.abs(),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.onPrimaryContainer,
                          height: 1,
                        ),
                        fixedStringLength: 0,
                        compact: true,
                      ),
                      Text(
                        isOver ? ctxt.budget_over : ctxt.budget_left,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onPrimaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.sectionGap),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emotionLine,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  compact: false,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Row(
                  children: [
                    Text(
                      '${ctxt.budget_used.toLowerCase()} · ',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                    CurrencyText(
                      amount: total,
                      fixedLength: 0,
                      compact: false,
                      suffixText: ctxt.budget_totalBudget.toLowerCase(),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.onPrimaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: CurrencyText(
                    amount: remaining.abs(),
                    fixedLength: 0,
                    compact: false,
                    suffixText: isOver ? ctxt.budget_over : ctxt.budget_left,
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. SMART INSIGHT ──

  Widget _buildInsight(
    double pct, double safePerDay, int daysLeft, bool isOver, double remaining,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    Brightness brightness,
  ) {
    final (String message, IconData icon, Color iconColor) = isOver
        ? (
            BuddyMessages.budgetExceededBy(
              formatCurrency(remaining.abs(), code: BaseCurrency.code),
            ),
            LucideIcons.triangleAlert,
            FinanceColors.expenseColor(brightness),
          )
        : pct > 0.8
            ? (
                BuddyMessages.budgetSlowDown(
                  formatCurrency(remaining, code: BaseCurrency.code),
                  daysLeft,
                ),
                LucideIcons.clock,
                FinanceColors.statusWarning,
              )
            : (
                BuddyMessages.budgetSafePerDay(
                  formatCurrency(safePerDay, code: BaseCurrency.code),
                ),
                LucideIcons.shieldCheck,
                FinanceColors.incomeColor(brightness),
              );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap * 1.5,
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. HIGHLIGHT CARD ──

  Widget _buildHighlightCard(
    BudgetWithProgress bwp, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, Brightness brightness, AppLocalizations ctxt,
  ) {
    final spent = bwp.spent;
    final budget = bwp.budget.amount;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final isOver = spent > budget;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? FinanceColors.statusWarning
            : color.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.budgetDetails, extra: bwp);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner + spacing.elementGapMin),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctxt.budget_highlightLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      bwp.budget.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.elementGap),
                    CurrencyText(
                      amount: spent,
                      fixedLength: 0,
                      compact: true,
                      suffixText: ctxt.budget_used.toLowerCase(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    CurrencyText(
                      amount: remaining.abs(),
                      fixedLength: 0,
                      compact: true,
                      suffixText: isOver
                          ? ctxt.budget_over
                          : ctxt.budget_left,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGap),
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}% ${ctxt.budget_used.toLowerCase()}',
                        style: textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              // Progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => CustomPaint(
                    painter: _BudgetRingPainter(
                      progress: value,
                      accent: accent,
                      trackColor: accent.withValues(alpha: 0.1),
                      strokeWidth: 8,
                    ),
                    child: Center(
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
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

  // ── 4. BUDGET TILE ──

  Widget _buildBudgetTile(
    BudgetWithProgress bwp, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, Brightness brightness, AppLocalizations ctxt,
  ) {
    final spent = bwp.spent;
    final budget = bwp.budget.amount;
    final name = bwp.budget.name;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final isOver = spent > budget;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? FinanceColors.statusWarning
            : color.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isOver
                ? accent.withValues(alpha: 0.4)
                : color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.budgetDetails, extra: bwp);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                // Mini circular progress
                SizedBox(
                  width: 40,
                  height: 40,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.elementGapUltraMin),
                      Row(
                        children: [
                          CurrencyText(
                            amount: spent,
                            fixedLength: 0,
                            compact: true,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                          Text(
                            ' / ',
                            style: textTheme.labelSmall?.copyWith(
                              color: color.outlineVariant,
                            ),
                          ),
                          CurrencyText(
                            amount: budget,
                            fixedLength: 0,
                            compact: true,
                            style: textTheme.labelSmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CurrencyText(
                      amount: remaining.abs(),
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Text(
                      isOver ? ctxt.budget_over : ctxt.budget_left,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: spacing.elementGapMin),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom ring painter ──

class _BudgetRingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color trackColor;
  final double strokeWidth;

  _BudgetRingPainter({
    required this.progress,
    required this.accent,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_BudgetRingPainter old) =>
      old.progress != progress || old.accent != accent;
}
