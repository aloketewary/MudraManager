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
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'dart:math' as math;

class BudgetDetailsScreen extends ConsumerWidget {
  final BudgetWithProgress data;

  const BudgetDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final b = data.budget;
    final spent = GuestModeUtil.applyGuestMode(data.spent, isGuestMode);
    final total = GuestModeUtil.applyGuestMode(b.amount, isGuestMode);
    final remaining = total - spent;
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.5) : 0.0;
    final isOver = spent > total;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final safePerDay =
        daysLeft > 0 && remaining > 0 ? remaining / daysLeft : 0.0;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? Colors.orange
            : FinanceColors.incomeColor(brightness);

    final sortedCategories = List<CategorySpending>.from(data.categorySpendings)
      ..sort((a, b2) {
        final aPct = a.allocated > 0 ? a.spent / a.allocated : 0.0;
        final bPct = b2.allocated > 0 ? b2.spent / b2.allocated : 0.0;
        return bPct.compareTo(aPct);
      });

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(b.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.addBudget, extra: {'budget': b});
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (value) async {
              if (value == 'delete') {
                HapticFeedback.mediumImpact();
                final confirmed = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: 'Delete \'${b.name}\'',
                );
                if (confirmed == true && context.mounted) {
                  await _deleteBudget(context, ref);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: color.error),
                    const SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: color.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ── 1. HERO RING ──
          _buildHero(remaining, total, spent, pct, isOver, accent, color,
              textTheme, spacing, isDark),
          SizedBox(height: spacing.sectionGap),

          // ── 2. DAILY HINT + HEALTH ──
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '${formatCurrency(safePerDay, code: BaseCurrency.code)}/day',
                  'Safe to spend',
                  LucideIcons.shieldCheck,
                  accent,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _buildMiniStat(
                  '$daysLeft days',
                  'Remaining',
                  LucideIcons.calendar,
                  color.primary,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),

          // ── 3. SMART INSIGHT ──
          _buildInsight(pct, isOver, remaining, safePerDay, daysLeft, accent,
              color, textTheme, spacing, brightness),
          SizedBox(height: spacing.sectionGap),

          // ── 4. CATEGORY BREAKDOWN ──
          if (sortedCategories.isNotEmpty) ...[
            Text(
              'BREAKDOWN',
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            ...sortedCategories.map((cat) => _buildCategoryTile(
                  cat,
                  isGuestMode,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                )),
          ],

          SizedBox(height: spacing.elementGap),
          const AmbientBrandSection(),
        ],
      ),
    );
  }

  // ── HERO ──

  Widget _buildHero(
    double remaining,
    double total,
    double spent,
    double pct,
    bool isOver,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
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
            SizedBox(
              width: 140,
              height: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    accent: accent,
                    track: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                    width: 10,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBalance(
                          value: remaining.abs(),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                          fixedStringLength: 0,
                          compact: true,
                        ),
                        Text(
                          isOver ? 'over' : 'left',
                          style: textTheme.labelMedium?.copyWith(
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Used ',
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant)),
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(' of ',
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant)),
                CurrencyText(
                  amount: total,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── MINI STAT ──

  Widget _buildMiniStat(
    String value,
    String label,
    IconData icon,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accent),
          SizedBox(height: spacing.elementGap),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            label,
            style:
                textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── INSIGHT ──

  Widget _buildInsight(
    double pct,
    bool isOver,
    double remaining,
    double safePerDay,
    int daysLeft,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final String message;
    final IconData icon;

    if (isOver) {
      message = BuddyMessages.budgetExceededAdjust;
      icon = LucideIcons.triangleAlert;
    } else if (pct > 0.8) {
      message = BuddyMessages.budgetSlowDown(
          formatCurrency(remaining, code: BaseCurrency.code), daysLeft);
      icon = LucideIcons.clock;
    } else if (pct > 0.5) {
      message = BuddyMessages.budgetOnTrack(
          formatCurrency(safePerDay, code: BaseCurrency.code));
      icon = LucideIcons.circleCheck;
    } else {
      message = BuddyMessages.budgetGreatDiscipline;
      icon = LucideIcons.sparkles;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap * 1.5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY TILE ──

  Widget _buildCategoryTile(
    CategorySpending cat,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final catSpent = GuestModeUtil.applyGuestMode(cat.spent, isGuestMode);
    final catAlloc = GuestModeUtil.applyGuestMode(cat.allocated, isGuestMode);
    final pct = catAlloc > 0 ? (catSpent / catAlloc).clamp(0.0, 1.0) : 0.0;
    final isOver = catSpent > catAlloc;
    final remaining = catAlloc - catSpent;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? Colors.orange
            : color.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isOver
                ? accent.withValues(alpha: 0.4)
                : color.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Category icon in circular progress
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                  Icon(
                    IconHelper.getIconData(cat.category.iconName),
                    size: 16,
                    color: accent,
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.category.name,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing.elementGapUltraMin),
                  // Thin inline bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
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

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(budgetServiceProvider).deleteBudget(data.budget.id);
      SnackbarService.success(BuddyMessages.budgetDeleted);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) SnackbarService.error(BuddyMessages.genericError);
    }
  }
}

// ── Ring painter ──

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color track;
  final double width;

  _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - width) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint..color = track);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent;
}
