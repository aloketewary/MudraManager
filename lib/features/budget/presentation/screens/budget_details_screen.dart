import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
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

  // ── Emotional headline ──
  String _emotionLine(double pct, bool isOver, AppLocalizations ctxt) {
    if (isOver) return ctxt.budget_emotionExceeded;
    if (pct > 0.8) return ctxt.budget_emotionAlmostThere;
    if (pct > 0.5) return ctxt.budget_emotionHalfway;
    return ctxt.budget_emotionUnderControl;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;
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
    final daysPassed = now.day;
    final safePerDay =
        daysLeft > 0 && remaining > 0 ? remaining / daysLeft : 0.0;
    final actualDailySpend = daysPassed > 0 ? spent / daysPassed : 0.0;
    final allowedDaily = daysInMonth > 0 ? total / daysInMonth : 0.0;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? FinanceColors.statusWarning
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
                  title: '${ctxt.budget_delete} \'${b.name}\'',
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
                    SizedBox(width: spacing.elementGap),
                    Text(
                      ctxt.budget_delete,
                      style: TextStyle(color: color.error),
                    ),
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
          // ── INVALID CATEGORIES WARNING ──
          if (data.hasInvalidCategories)
            _buildWarningBanner(color, textTheme, spacing, ctxt),

          // ── 1. HERO ──
          _buildHero(
            remaining, total, spent, pct, isOver, accent,
            color, textTheme, spacing, isDark, ctxt,
          ),
          SizedBox(height: spacing.sectionGap),

          // ── 2. BUDGET PERIOD ──
          _buildPeriodCard(b, daysLeft, color, textTheme, spacing, ctxt),
          SizedBox(height: spacing.elementGap),

          // ── 3. STATS ROW ──
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '${formatCurrency(safePerDay, code: BaseCurrency.code)}/day',
                  ctxt.budget_safeToSpend,
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
                  ctxt.budget_daysRemaining(daysLeft),
                  ctxt.budget_remaining,
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

          // ── 4. SPENDING PACE ──
          _buildSpendingPace(
            actualDailySpend, allowedDaily,
            color, textTheme, spacing, brightness, ctxt,
          ),
          SizedBox(height: spacing.elementGap * 1.5),

          // ── 5. SMART INSIGHT ──
          _buildInsight(
            pct, isOver, remaining, safePerDay, daysLeft, accent,
            color, textTheme, spacing, brightness,
          ),
          SizedBox(height: spacing.sectionGap),

          // ── 6. CATEGORY BREAKDOWN ──
          if (sortedCategories.isNotEmpty) ...[
            Text(
              ctxt.budget_breakdown,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            ...sortedCategories.map(
              (cat) => _buildCategoryTile(
                cat, isGuestMode, color, textTheme, spacing, brightness, ctxt,
              ),
            ),
          ],

          SizedBox(height: spacing.elementGap),
          const AmbientBrandSection(),
        ],
      ),
    );
  }

  // ── WARNING BANNER ──

  Widget _buildWarningBanner(
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.errorContainer,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: color.error, size: 20),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                ctxt.budget_invalidCategories,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Icon(
              LucideIcons.pencil,
              size: 16,
              color: color.onErrorContainer.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO ──

  Widget _buildHero(
    double remaining, double total, double spent, double pct, bool isOver,
    Color accent, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, bool isDark, AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGapMin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.2 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emotional headline
                Text(
                  _emotionLine(pct, isOver, ctxt),
                  style: textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                // Spent amount (hero number)
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  compact: false,
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
                  compact: false,
                  suffixText: isOver ? ctxt.budget_over : ctxt.budget_left,
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
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    '${(pct.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}% ${ctxt.budget_used.toLowerCase()}',
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
            width: 88,
            height: 88,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  accent: accent,
                  track: accent.withValues(alpha: 0.1),
                  width: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBalance(
                        value: remaining.abs(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                          height: 1,
                        ),
                        fixedStringLength: 0,
                        compact: true,
                      ),
                      Text(
                        isOver ? ctxt.budget_over : ctxt.budget_left,
                        style: textTheme.labelSmall?.copyWith(
                          color: accent.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUDGET PERIOD ──

  Widget _buildPeriodCard(
    dynamic b, int daysLeft, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap * 0.75),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(LucideIcons.calendar, color: color.primary, size: 20),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${safeDateFormat('dd MMM', ctxt.localeName).format(b.startDate)}'
                  ' — '
                  '${safeDateFormat('dd MMM yyyy', ctxt.localeName).format(b.endDate)}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (daysLeft > 0)
                  Text(
                    ctxt.budget_daysRemaining(daysLeft),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SPENDING PACE ──

  Widget _buildSpendingPace(
    double actualDaily, double allowedDaily,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    Brightness brightness, AppLocalizations ctxt,
  ) {
    final isOverPace = actualDaily > allowedDaily;
    final paceAccent = isOverPace
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);
    final paceIcon = isOverPace ? LucideIcons.trendingUp : LucideIcons.trendingDown;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(paceIcon, size: 18, color: paceAccent),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.budget_spendingPace,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          // Pace comparison bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctxt.budget_dailyActual(
                        formatCurrency(actualDaily, code: BaseCurrency.code),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: paceAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      child: LinearProgressIndicator(
                        value: allowedDaily > 0
                            ? (actualDaily / allowedDaily).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 6,
                        backgroundColor: paceAccent.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(paceAccent),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sectionGap),
              Text(
                ctxt.budget_dailyAllowed(
                  formatCurrency(allowedDaily, code: BaseCurrency.code),
                ),
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── MINI STAT ──

  Widget _buildMiniStat(
    String value, String label, IconData icon, Color accent,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
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
    double pct, bool isOver, double remaining, double safePerDay,
    int daysLeft, Color accent, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, Brightness brightness,
  ) {
    final String message;
    final IconData icon;

    if (isOver) {
      message = BuddyMessages.budgetExceededAdjust;
      icon = LucideIcons.triangleAlert;
    } else if (pct > 0.8) {
      message = BuddyMessages.budgetSlowDown(
        formatCurrency(remaining, code: BaseCurrency.code),
        daysLeft,
      );
      icon = LucideIcons.clock;
    } else if (pct > 0.5) {
      message = BuddyMessages.budgetOnTrack(
        formatCurrency(safePerDay, code: BaseCurrency.code),
      );
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
    CategorySpending cat, bool isGuestMode, ColorScheme color,
    TextTheme textTheme, AppSpacing spacing, Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final catSpent = GuestModeUtil.applyGuestMode(cat.spent, isGuestMode);
    final catAlloc = GuestModeUtil.applyGuestMode(cat.allocated, isGuestMode);
    final pct = catAlloc > 0 ? (catSpent / catAlloc).clamp(0.0, 1.0) : 0.0;
    final isOver = catSpent > catAlloc;
    final remaining = catAlloc - catSpent;

    final accent = isOver
        ? FinanceColors.expenseColor(brightness)
        : pct > 0.8
            ? FinanceColors.statusWarning
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
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing.elementGapUltraMin),
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
                  isOver ? ctxt.budget_over : ctxt.budget_left,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    try {
      await ref.read(budgetServiceProvider).deleteBudget(data.budget.id);
      SnackbarService.success(BuddyMessages.budgetDeleted);
      router.pop();
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
