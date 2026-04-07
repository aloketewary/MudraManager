import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Budget'),
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
              iconData: Icons.pie_chart_outline,
            );
          }

          final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
          final remaining = totalBudget - totalSpent;
          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final daysLeft = daysInMonth - now.day + 1;
          final safePerDay = daysLeft > 0 ? remaining / daysLeft : 0.0;
          final pct = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.5) : 0.0;
          final isOver = totalSpent > totalBudget;

          final accent = isOver
              ? FinanceColors.expenseColor(brightness)
              : pct > 0.8
                  ? Colors.orange
                  : FinanceColors.incomeColor(brightness);

          // Sort budgets: over-budget first, then by % used descending
          final sorted = List<BudgetWithProgress>.from(budgets)
            ..sort((a, b2) {
              final aPct = a.budget.amount > 0 ? a.spent / a.budget.amount : 0.0;
              final bPct = b2.budget.amount > 0 ? b2.spent / b2.budget.amount : 0.0;
              return bPct.compareTo(aPct);
            });

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(budgetsWithProgressProvider);
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── 1. HERO: Circular progress + remaining ──
                _buildHero(remaining, totalBudget, totalSpent, pct, isOver, accent, color, textTheme, spacing, isDark),
                SizedBox(height: spacing.sectionGap),

                // ── 2. SMART INSIGHT ──
                _buildInsight(pct, safePerDay, daysLeft, isOver, remaining, color, textTheme, spacing, brightness),
                SizedBox(height: spacing.sectionGap),

                // ── 3. CATEGORY BREAKDOWN ──
                if (sorted.length > 1) ...[
                  Text(
                    'BREAKDOWN',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                ],
                ...sorted.map((b) => _buildBudgetTile(b, color, textTheme, spacing, brightness)),

                SizedBox(height: spacing.sectionGap),
                const AmbientBrandSection(),
              ],
            ),
          );
        },
        loading: () => ListView(
          children: List.generate(4, (_) => BudgetCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  // ── 1. HERO ──

  Widget _buildHero(
    double remaining, double total, double spent, double pct, bool isOver,
    Color accent, ColorScheme color, TextTheme textTheme, AppSpacing spacing, bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Column(
          children: [
            // Circular progress ring
            SizedBox(
              width: 160,
              height: 160,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  painter: _BudgetRingPainter(
                    progress: value,
                    accent: accent,
                    trackColor: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                    strokeWidth: 12,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBalance(
                          value: remaining.abs(),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                            letterSpacing: -0.5,
                          ),
                          fixedStringLength: 0,
                          compact: true,
                        ),
                        Text(
                          isOver ? 'over' : 'left',
                          style: textTheme.labelMedium?.copyWith(
                            color: accent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            // Used / Total
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Used ',
                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                ),
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  ' of ',
                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                ),
                CurrencyText(
                  amount: total,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. SMART INSIGHT ──

  Widget _buildInsight(
    double pct, double safePerDay, int daysLeft, bool isOver, double remaining,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing, Brightness brightness,
  ) {
    final (String message, IconData icon, Color iconColor) = isOver
        ? (
            BuddyMessages.budgetExceededBy(formatCurrency(remaining.abs(), code: BaseCurrency.code)),
            LucideIcons.triangleAlert,
            FinanceColors.expenseColor(brightness),
          )
        : pct > 0.8
            ? (
                BuddyMessages.budgetSlowDown(formatCurrency(remaining, code: BaseCurrency.code), daysLeft),
                LucideIcons.clock,
                Colors.orange,
              )
            : (
                BuddyMessages.budgetSafePerDay(formatCurrency(safePerDay, code: BaseCurrency.code)),
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

  // ── 3. BUDGET TILE ──

  Widget _buildBudgetTile(
    BudgetWithProgress bwp,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing, Brightness brightness,
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
            ? Colors.orange
            : color.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        margin: const EdgeInsets.only(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(
            color: isOver
                ? accent.withValues(alpha: 0.4)
                : color.outlineVariant.withValues(alpha: 0.3),
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
            child: Column(
              children: [
                Row(
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
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGapUltraMin),
                          Text(
                            '${formatCurrency(spent, code: BaseCurrency.code)} of ${formatCurrency(budget, code: BaseCurrency.code)}',
                            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
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
                          isOver ? 'over' : 'left',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Icon(LucideIcons.chevronRight, size: 16, color: color.onSurfaceVariant.withValues(alpha: 0.3)),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
                // Thin progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom ring painter with rounded caps ──

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

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
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
