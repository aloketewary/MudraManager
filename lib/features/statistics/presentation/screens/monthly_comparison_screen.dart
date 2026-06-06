import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/statistics/data/comparison_provider.dart';
import 'package:mudra_manager/features/statistics/data/monthly_comparison_service.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/month_picker_sheet.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class MonthlyComparisonScreen extends ConsumerWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final compareMonth = ref.watch(compareMonthProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: l10n.title_compareMonths,
        appBarMode: AppBarMode.standard,
        enableRefresh: true,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'pick_month',
            label:
                safeDateFormat('MMM yy', l10n.localeName).format(compareMonth),
            icon: LucideIcons.calendarSearch,
            onTap: () => _pickMonth(context, ref),
          ),
        ],
      ),
      onRefresh: () async {
        ref.invalidate(comparisonAnalysisProvider);
        // Wait for the provider to recompute
        await ref.read(comparisonAnalysisProvider.future);
      },
      body: ref.watch(comparisonAnalysisProvider).when(
            data: (d) => _Body(data: d),
            loading: () => _buildSkeleton(ref),
            error: (e, _) => Center(child: Text('$e')),
          ),
    );
  }

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final current = ref.read(compareMonthProvider);
    final picked = await showMonthPicker(
      context: context,
      initialMonth: current,
      lastMonth: DateTime(now.year, now.month - 1, 1),
    );
    if (picked != null) {
      HapticFeedback.mediumImpact();
      ref.read(compareMonthProvider.notifier).set(picked);
    }
  }

  Widget _buildSkeleton(WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: List.generate(3, (_) => const BudgetCardSkeleton()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _Body extends ConsumerWidget {
  final ComparisonAnalysis data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuest = ref.watch(guestModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final compareMonth = ref.watch(compareMonthProvider);

    final curName =
        safeDateFormat('MMMM', l10n.localeName).format(DateTime.now());
    final cmpName =
        safeDateFormat('MMMM', l10n.localeName).format(compareMonth);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _HeroSummary(data: data, isGuest: isGuest, cmpName: cmpName),
        SizedBox(height: spacing.elementGap),
        _ConfidenceBanner(data: data),
        SizedBox(height: spacing.elementGap),
        _InsightCard(data: data, isGuest: isGuest, cmpName: cmpName),
        SizedBox(height: spacing.sectionGap),
        _PaceCard(
          data: data,
          isGuest: isGuest,
          curName: curName,
          cmpName: cmpName,
        ),
        SizedBox(height: spacing.sectionGap),
        if (data.contributions
            .where((c) => c.currentSpend > 0 || c.compareSpend > 0)
            .isNotEmpty) ...[
          _CategoryChart(
            data: data,
            isGuest: isGuest,
            curName: curName,
            cmpName: cmpName,
          ),
          SizedBox(height: spacing.sectionGap),
        ],
        if (data.contributions.isNotEmpty) ...[
          _CategoryImpact(data: data, isGuest: isGuest),
          SizedBox(height: spacing.sectionGap),
        ],
        _ActivityCard(
          data: data,
          isGuest: isGuest,
          curName: curName,
          cmpName: cmpName,
        ),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. HERO SUMMARY
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroSummary extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;
  final String cmpName;

  const _HeroSummary({
    required this.data,
    required this.isGuest,
    required this.cmpName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    final net = GuestModeUtil.applyGuestMode(data.currentNet, isGuest);
    final pct = data.netVariancePct;
    final isUp = pct > 0;
    final isFlat = pct.abs() < 1;

    final deltaColor = isFlat
        ? color.onSurfaceVariant
        : isUp
            ? FinanceColors.incomeColor(brightness)
            : FinanceColors.expenseColor(brightness);

    final curInc = GuestModeUtil.applyGuestMode(data.currentIncome, isGuest);
    final cmpInc = GuestModeUtil.applyGuestMode(data.compareIncome, isGuest);
    final curExp = GuestModeUtil.applyGuestMode(data.currentExpense, isGuest);
    final cmpExp = GuestModeUtil.applyGuestMode(data.compareExpense, isGuest);
    final incPct = cmpInc > 0 ? ((curInc - cmpInc) / cmpInc * 100) : 0.0;
    final expPct = cmpExp > 0 ? ((curExp - cmpExp) / cmpExp * 100) : 0.0;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net — hero number (36px, w900)
          CurrencyText(
            amount: net,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
            compact: true,
            showSign: true,
            showPositiveSign: true,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Net Balance',
                style: text.bodySmall?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              if (!isFlat)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(Tone.current.borderRadius),
                  ),
                  child: Text(
                    '${isUp ? '▲' : '▼'} ${pct.abs().toStringAsFixed(0)}% vs $cmpName',
                    style: text.labelSmall?.copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),

          // Income / Expense — subordinate (12-14px)
          _SubMetricRow(
            label: 'Income',
            amount: curInc,
            pct: incPct,
            icon: LucideIcons.trendingUp,
            accentColor: FinanceColors.incomeColor(brightness),
          ),
          SizedBox(height: spacing.elementGapMin),
          _SubMetricRow(
            label: 'Expense',
            amount: curExp,
            pct: expPct,
            icon: LucideIcons.trendingDown,
            accentColor: FinanceColors.expenseColor(brightness),
          ),
        ],
      ),
    );
  }
}

class _SubMetricRow extends StatelessWidget {
  final String label;
  final double amount;
  final double pct;
  final IconData icon;
  final Color accentColor;

  const _SubMetricRow({
    required this.label,
    required this.amount,
    required this.pct,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isUp = pct > 0;
    final isFlat = pct.abs() < 1;

    return Row(
      children: [
        Icon(icon, size: 14, color: accentColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        CurrencyText(
          amount: amount,
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          compact: true,
        ),
        const Spacer(),
        if (!isFlat)
          Text(
            '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%',
            style: text.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. CONFIDENCE BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class _ConfidenceBanner extends ConsumerWidget {
  final ComparisonAnalysis data;
  const _ConfidenceBanner({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final message = data.isPartialPeriod
        ? 'Current month is still in progress. Analysis uses first ${data.comparedDays} days of both months.'
        : 'Compared using complete monthly data.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: spacing.borderRadiusSmall,
        border: Border.all(color: color.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 14, color: color.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. INSIGHT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _InsightCard extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;
  final String cmpName;

  const _InsightCard({
    required this.data,
    required this.isGuest,
    required this.cmpName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final code = BaseCurrency.code;

    final isDown = data.isExpenseDown;
    final isFlat = data.isExpenseFlat;
    final accent = isFlat
        ? color.primary
        : isDown
            ? FinanceColors.incomeColor(brightness)
            : FinanceColors.expenseColor(brightness);

    // Build narrative lines
    final lines = <String>[];

    if (isFlat) {
      lines.add('Spending is steady compared to $cmpName.');
    } else {
      final dir = isDown ? 'decreased' : 'increased';
      final amt = formatCurrencyCompact(data.expenseVariance.abs(), code: code);
      final pct = data.expenseVariancePct.abs().toStringAsFixed(0);
      lines.add('Spending $dir $pct% ($amt).');
    }

    if (data.topIncrease != null && !isFlat) {
      final pct = data.topIncrease!.contributionPct.abs().toStringAsFixed(0);
      lines.add('${data.topIncrease!.name} contributed +$pct% of the change.');
    }
    if (data.topDecrease != null && !isFlat) {
      final pct = data.topDecrease!.contributionPct.abs().toStringAsFixed(0);
      lines.add('${data.topDecrease!.name} offset −$pct%.');
    }

    if (data.forecastEligible && !isFlat) {
      if (data.projectedMonthEndSpend > data.compareExpense) {
        final over = formatCurrencyCompact(
          data.projectedMonthEndSpend - data.compareExpense,
          code: code,
        );
        lines.add('At current pace, $over above $cmpName.');
      } else {
        lines.add('On track to finish below $cmpName.');
      }
    }

    final IconData icon;
    if (isFlat) {
      icon = LucideIcons.shieldCheck;
    } else if (isDown) {
      icon = LucideIcons.trendingDown;
    } else {
      icon = LucideIcons.trendingUp;
    }

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: spacing.borderRadiusMedium,
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
            child: Text(
              lines.join('\n'),
              style: text.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. PACE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PaceCard extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;
  final String curName;
  final String cmpName;

  const _PaceCard({
    required this.data,
    required this.isGuest,
    required this.curName,
    required this.cmpName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final code = BaseCurrency.code;

    final curDaily =
        GuestModeUtil.applyGuestMode(data.currentDailySpend, isGuest);
    final cmpDaily =
        GuestModeUtil.applyGuestMode(data.compareDailySpend, isGuest);
    final maxVal = math.max(curDaily, cmpDaily);
    final curFrac = maxVal > 0 ? (curDaily / maxVal).clamp(0.0, 1.0) : 0.0;
    final cmpFrac = maxVal > 0 ? (cmpDaily / maxVal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.gauge, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Text(
                'Daily Spending Pace',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PaceBar(
            label: curName.split(' ').first,
            value: curDaily,
            fraction: curFrac,
            barColor: color.primary,
          ),
          const SizedBox(height: 10),
          _PaceBar(
            label: cmpName.split(' ').first,
            value: cmpDaily,
            fraction: cmpFrac,
            barColor: color.primary.withValues(alpha: 0.4),
          ),
          if (data.forecastEligible) ...[
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
                    'Projected: ${formatCurrencyCompact(GuestModeUtil.applyGuestMode(data.projectedMonthEndSpend, isGuest), code: code)} this month',
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
}

class _PaceBar extends StatelessWidget {
  final String label;
  final double value;
  final double fraction;
  final Color barColor;

  const _PaceBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final code = BaseCurrency.code;

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
          '${formatCurrencyCompact(value, code: code)}/d',
          style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. CATEGORY CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryChart extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;
  final String curName;
  final String cmpName;

  const _CategoryChart({
    required this.data,
    required this.isGuest,
    required this.curName,
    required this.cmpName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final cats = data.contributions.take(5).toList();
    final maxVal = cats.fold<double>(
      0,
      (m, c) => math.max(m, math.max(c.currentSpend, c.compareSpend)),
    );
    if (maxVal <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.chartBarBig, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Text(
                'Top Categories',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _LegendDot(color: color.primary),
              const SizedBox(width: 4),
              Text(
                curName.split(' ').first,
                style: text.labelSmall?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              _LegendDot(color: color.primary.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(
                cmpName.split(' ').first,
                style: text.labelSmall?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...cats.map((cat) {
            final cur = GuestModeUtil.applyGuestMode(cat.currentSpend, isGuest);
            final cmp = GuestModeUtil.applyGuestMode(cat.compareSpend, isGuest);
            final curFrac = (cur / maxVal).clamp(0.0, 1.0);
            final cmpFrac = (cmp / maxVal).clamp(0.0, 1.0);

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
                  _AnimatedBar(fraction: curFrac, barColor: color.primary),
                  const SizedBox(height: 2),
                  _AnimatedBar(
                    fraction: cmpFrac,
                    barColor: color.primary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double fraction;
  final Color barColor;
  const _AnimatedBar({required this.fraction, required this.barColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: barColor.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation(barColor),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. CATEGORY IMPACT
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryImpact extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;

  const _CategoryImpact({required this.data, required this.isGuest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final code = BaseCurrency.code;
    final netVar = data.expenseVariance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY IMPACT',
          style: text.labelSmall?.copyWith(
            color: color.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        ...data.contributions.take(6).map((cat) {
          final cur = GuestModeUtil.applyGuestMode(cat.currentSpend, isGuest);
          final cmp = GuestModeUtil.applyGuestMode(cat.compareSpend, isGuest);
          final delta = cur - cmp;
          final isUp = delta > 0;
          final isZero = delta.abs() < 1;
          final contribPct = cat.contributionPct(netVar);

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
                borderRadius: spacing.borderRadiusMedium,
                border: Border.all(color: color.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(Tone.current.borderRadius),
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
                          style: text.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${formatCurrencyCompact(cur, code: code)} vs ${formatCurrencyCompact(cmp, code: code)}',
                          style: text.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: deltaColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(Tone.current.borderRadius),
                        ),
                        child: Text(
                          isZero
                              ? '—'
                              : '${isUp ? '+' : ''}${formatCurrencyCompact(delta, code: code)}',
                          style: text.labelSmall?.copyWith(
                            color: deltaColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isZero && netVar.abs() > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${contribPct >= 0 ? '+' : ''}${contribPct.toStringAsFixed(0)}% of change',
                          style: text.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivityCard extends ConsumerWidget {
  final ComparisonAnalysis data;
  final bool isGuest;
  final String curName;
  final String cmpName;

  const _ActivityCard({
    required this.data,
    required this.isGuest,
    required this.curName,
    required this.cmpName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final code = BaseCurrency.code;

    final curCount = data.currentTxnCount;
    final cmpCount = data.compareTxnCount;
    final countDelta = curCount - cmpCount;
    final countPct =
        cmpCount > 0 ? ((countDelta / cmpCount) * 100).toStringAsFixed(0) : '—';

    final curAvg = GuestModeUtil.applyGuestMode(data.currentAvgTxn, isGuest);
    final cmpAvg = GuestModeUtil.applyGuestMode(data.compareAvgTxn, isGuest);
    final avgDelta = curAvg - cmpAvg;
    final avgPct =
        cmpAvg > 0 ? ((avgDelta / cmpAvg) * 100).toStringAsFixed(0) : '—';

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Text(
                'Activity',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          _MetricRow(
            label: 'Transactions',
            value: '$curCount vs $cmpCount',
            delta: countDelta.toDouble(),
            pctLabel: countPct,
            positiveColor: color.primary,
            negativeColor: FinanceColors.incomeColor(brightness),
          ),
          SizedBox(height: spacing.elementGapMin),
          _MetricRow(
            label: 'Avg transaction',
            value:
                '${formatCurrencyCompact(curAvg, code: code)} vs ${formatCurrencyCompact(cmpAvg, code: code)}',
            delta: avgDelta,
            pctLabel: avgPct,
            positiveColor: FinanceColors.expenseColor(brightness),
            negativeColor: FinanceColors.incomeColor(brightness),
          ),
          SizedBox(height: spacing.elementGap),
          _BehaviorExplanation(countDelta: countDelta, avgDelta: avgDelta),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final double delta;
  final String pctLabel;
  final Color positiveColor;
  final Color negativeColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.delta,
    required this.pctLabel,
    required this.positiveColor,
    required this.negativeColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        const Spacer(),
        Text(value,
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        if (delta.abs() > 0.5)
          Text(
            '${delta > 0 ? '+' : ''}$pctLabel%',
            style: text.labelSmall?.copyWith(
              color: delta > 0 ? positiveColor : negativeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _BehaviorExplanation extends StatelessWidget {
  final int countDelta;
  final double avgDelta;
  const _BehaviorExplanation({
    required this.countDelta,
    required this.avgDelta,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final String explanation;
    if (countDelta > 0 && avgDelta > 1) {
      explanation = 'More purchases, bigger amounts.';
    } else if (countDelta > 0 && avgDelta < -1) {
      explanation = 'More purchases, but smaller amounts.';
    } else if (countDelta < 0 && avgDelta > 1) {
      explanation = 'Fewer purchases, but bigger amounts.';
    } else if (countDelta < 0 && avgDelta < -1) {
      explanation = 'Fewer purchases, smaller amounts.';
    } else if (countDelta > 0) {
      explanation = 'More frequent spending at similar amounts.';
    } else if (countDelta < 0) {
      explanation = 'Less frequent spending at similar amounts.';
    } else {
      explanation = 'Spending pattern unchanged.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
      ),
      child: Text(
        explanation,
        style: text.bodySmall?.copyWith(
          color: color.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
