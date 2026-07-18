import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';
import 'package:mudra_manager/features/analytics/data/tax_opportunity_service.dart';
import 'package:mudra_manager/features/analytics/presentation/screens/tax_deduction_input_screen.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class TaxEstimationScreen extends ConsumerStatefulWidget {
  const TaxEstimationScreen({super.key});

  @override
  ConsumerState<TaxEstimationScreen> createState() =>
      _TaxEstimationScreenState();
}

class _TaxEstimationScreenState extends ConsumerState<TaxEstimationScreen>
    with TickerProviderStateMixin {
  // Planning mode state
  bool _isPlanningMode = false;
  final Map<String, double> _plannedDeductions = {};
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _togglePlanningMode() {
    setState(() {
      _isPlanningMode = !_isPlanningMode;
      if (_isPlanningMode) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  void _updatePlannedDeduction(String key, double amount) {
    setState(() {
      if (amount <= 0) {
        _plannedDeductions.remove(key);
      } else {
        _plannedDeductions[key] = amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taxAsync = ref.watch(taxEstimationProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: _isPlanningMode ? ctxt.tax_plannerTitle : ctxt.tax_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () {
          if (_isPlanningMode) {
            _togglePlanningMode();
          } else {
            context.pop();
          }
        },
      ),
      actions: ScreenActions.build(
        trailing: ScreenTextAction(
          id: 'plan',
          label: _isPlanningMode ? ctxt.common_done : ctxt.tax_startPlanning,
          onTap: _togglePlanningMode,
        ),
      ),
      body: taxAsync.when(
        data: (tax) => _TaxContent(
          tax: tax,
          ctxt: ctxt,
          spacing: spacing,
          isPlanningMode: _isPlanningMode,
          plannedDeductions: _plannedDeductions,
          onUpdateDeduction: _updatePlannedDeduction,
        ),
        loading: () => const Center(child: DashboardCardSkeleton()),
        error: (_, __) => Center(child: Text(ctxt.tax_noData)),
      ),
    );
  }
}

typedef _DeductionUpdater = void Function(String key, double amount);

class _TaxContent extends ConsumerStatefulWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;
  final bool isPlanningMode;
  final Map<String, double> plannedDeductions;
  final _DeductionUpdater onUpdateDeduction;

  const _TaxContent({
    required this.tax,
    required this.ctxt,
    required this.spacing,
    required this.isPlanningMode,
    required this.plannedDeductions,
    required this.onUpdateDeduction,
  });

  @override
  ConsumerState<_TaxContent> createState() => _TaxContentState();
}

class _TaxContentState extends ConsumerState<_TaxContent> {
  bool get _isReducedMotion => MediaQuery.of(context).disableAnimations;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final isGuestMode = ref.watch(guestModeProvider);
    final opportunities = ref.watch(taxOpportunitiesProvider);
    final tax = widget.tax;
    final spacing = widget.spacing;
    final ctxt = AppLocalizations.of(context)!;
    final isReducedMotion = _isReducedMotion;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero summary with planning toggle
          RepaintBoundary(
            child: _buildSummaryCard(
              color,
              textTheme,
              brightness,
              isGuestMode,
              spacing,
              ctxt,
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          // 2. Planning mode indicator and quick actions
          AnimatedSize(
            duration: isReducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: widget.isPlanningMode
                ? RepaintBoundary(
                    child: _buildPlanningIndicator(
                      color,
                      textTheme,
                      spacing,
                      ctxt,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.isPlanningMode) SizedBox(height: spacing.sectionGap),

          // 3. Regime comparison (promoted — decision before detail)
          if (tax.oldRegimeEstimate != null)
            RepaintBoundary(
              child: _buildRegimeComparisonCard(
                color,
                textTheme,
                brightness,
                isGuestMode,
                spacing,
              ),
            ),
          if (tax.oldRegimeEstimate != null)
            SizedBox(height: spacing.sectionGap),

          // 4. Planning Mode: Interactive Deduction Planner
          AnimatedSize(
            duration: isReducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: widget.isPlanningMode
                ? RepaintBoundary(
                    child: Column(
                      key: const ValueKey('planning_widgets'),
                      children: [
                        RepaintBoundary(
                          child: _buildDeductionPlannerCard(
                            context,
                            color,
                            textTheme,
                            brightness,
                            isGuestMode,
                            spacing,
                            ctxt,
                          ),
                        ),
                        SizedBox(height: spacing.sectionGap),

                        // 5. Planning impact summary
                        RepaintBoundary(
                          child: _buildPlanningImpactCard(
                            color,
                            textTheme,
                            brightness,
                            isGuestMode,
                            spacing,
                            ctxt,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.isPlanningMode) SizedBox(height: spacing.sectionGap),

          // 6. Opportunities (what can reduce tax?)
          AnimatedSwitcher(
            duration: isReducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: !tax.isZeroTax && !widget.isPlanningMode
                ? opportunities.when(
                    data: (opps) => opps.isEmpty
                        ? const SizedBox.shrink()
                        : RepaintBoundary(
                            child: _buildOpportunitiesCard(
                              context,
                              opps,
                              color,
                              textTheme,
                              brightness,
                              isGuestMode,
                              spacing,
                              ctxt,
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                : const SizedBox.shrink(),
          ),
          if (!tax.isZeroTax && !widget.isPlanningMode)
            SizedBox(height: spacing.sectionGap),

          // 7. Tax computation
          RepaintBoundary(
            child: _buildDeductionsCard(
              color,
              textTheme,
              brightness,
              isGuestMode,
              spacing,
              ctxt,
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          // 8. Slab breakdown
          RepaintBoundary(
            child: _buildSlabCard(
              color,
              textTheme,
              brightness,
              isGuestMode,
              spacing,
              ctxt,
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          // 9. Income breakdown (with percentages)
          if (tax.incomeByCategory.isNotEmpty)
            RepaintBoundary(
              child: _buildCategoryCard(
                ctxt.tax_incomeBreakdown,
                tax.incomeByCategory,
                LucideIcons.trendingUp,
                FinanceColors.incomeColor(brightness),
                color,
                textTheme,
                isGuestMode,
                spacing,
              ),
            ),
          if (tax.incomeByCategory.isNotEmpty)
            SizedBox(height: spacing.sectionGap),

          // 10. Assumptions
          if (tax.assumptions.isNotEmpty)
            RepaintBoundary(
              child: _buildAssumptionsCard(
                color,
                textTheme,
                spacing,
                ctxt,
              ),
            ),
          if (tax.assumptions.isNotEmpty)
            SizedBox(height: spacing.sectionGap),

          // 11. Disclaimer
          RepaintBoundary(
            child: _buildDisclaimer(
              color,
              textTheme,
              spacing,
              ctxt,
            ),
          ),
        ],
      ),
    );
  }

  // ===== PLANNING MODE WIDGETS =====

  Widget _buildPlanningIndicator(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final totalPlanned =
        widget.plannedDeductions.values.fold<double>(0, (a, b) => a + b);
    final potentialSavings = totalPlanned * 0.3; // Rough estimate

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.08),
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(color: color.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                color: color.primary,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  ctxt.tax_planningMode,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          if (totalPlanned > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.tax_plannedDeductions,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                CurrencyText(
                  amount: totalPlanned,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGapMin),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.tax_potentialSavings,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                CurrencyText(
                  amount: potentialSavings,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        FinanceColors.goodColor(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              ctxt.tax_addDeductionsPrompt,
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildDeductionPlannerCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final deductionOptions = [
      (_PlannerOption.nps, ctxt.tax_nps80CCD1B, 50000.0),
      (_PlannerOption.section80C, ctxt.tax_section80C, 150000.0),
      (_PlannerOption.section80D, ctxt.tax_section80D, 50000.0),
      (_PlannerOption.hra, ctxt.tax_hraExemption, 60000.0),
      (_PlannerOption.homeLoan, ctxt.tax_homeLoanInterest, 200000.0),
    ];

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calculator,
                color: color.primary,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_plannerDeductions,
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          ...deductionOptions.map((option) {
            final (key, label, maxAmount) = option;
            final currentValue = widget.plannedDeductions[key.name] ?? 0;

            return Column(
              key: ValueKey(key.name),
              children: [
                _buildDeductionSlider(
                  label: label,
                  currentValue: currentValue,
                  maxValue: maxAmount,
                  color: color,
                  textTheme: textTheme,
                  onChanged: (value) =>
                      widget.onUpdateDeduction(key.name, value),
                  spacing: spacing,
                  ctxt: ctxt,
                ),
                SizedBox(height: spacing.elementGap),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeductionSlider({
    required String label,
    required double currentValue,
    required double maxValue,
    required ColorScheme color,
    required TextTheme textTheme,
    required ValueChanged<double> onChanged,
    required AppSpacing spacing,
    required AppLocalizations ctxt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: textTheme.bodyMedium),
            CurrencyText(
              amount: currentValue,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGapMin),
        Slider(
          value: currentValue,
          min: 0,
          max: maxValue,
          onChanged: onChanged,
          activeColor: color.primary,
          inactiveColor: color.surfaceContainerHighest,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style:
                  textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
            ),
            Text(
              ctxt.tax_upTo(maxValue.toInt()),
              style:
                  textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanningImpactCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final totalPlanned =
        widget.plannedDeductions.values.fold<double>(0, (a, b) => a + b);
    final currentTax = widget.tax.totalTax;
    final estimatedSavings = totalPlanned * 0.3; // Simplified rate
    final newTax =
        (currentTax - estimatedSavings).clamp(0, currentTax).toDouble();
    final savingsColor = FinanceColors.goodColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            savingsColor.withValues(alpha: 0.08),
            savingsColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(color: savingsColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.trendingDown,
                color: savingsColor,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_planningImpact,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: savingsColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: _impactColumn(
                  ctxt.tax_currentTax,
                  currentTax,
                  color,
                  textTheme,
                  isGuestMode,
                  spacing,
                ),
              ),
              Icon(LucideIcons.arrowRight, color: color.onSurfaceVariant),
              Expanded(
                child: _impactColumn(
                  ctxt.tax_projectedTax,
                  newTax,
                  color,
                  textTheme,
                  isGuestMode,
                  spacing,
                  highlight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: savingsColor.withValues(alpha: 0.1),
              borderRadius: spacing.borderRadiusMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.circleCheck, size: 16, color: savingsColor),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  ctxt.tax_totalSavings,
                  style: textTheme.bodySmall?.copyWith(color: savingsColor),
                ),
                SizedBox(width: spacing.elementGapMin),
                CurrencyText(
                  amount: estimatedSavings,
                  style: textTheme.bodySmall?.copyWith(
                    color: savingsColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactColumn(
    String label,
    double amount,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing, {
    bool highlight = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        CurrencyText(
          amount: GuestModeUtil.applyGuestMode(amount, isGuestMode),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? color.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final taxColor = widget.tax.isZeroTax
        ? FinanceColors.goodColor(brightness)
        : color.onSurface;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primary.withValues(alpha: 0.08),
            color.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // FY + Confidence badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.tax.financialYear,
                style: textTheme.titleSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              _buildConfidenceBadge(color, textTheme, spacing),
            ],
          ),
          if (widget.tax.isProjected)
            Text(
              ctxt.tax_projected,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          SizedBox(height: spacing.elementGap),
          Text(
            ctxt.tax_estimatedTax,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          CurrencyText(
            amount:
                GuestModeUtil.applyGuestMode(widget.tax.totalTax, isGuestMode),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: taxColor,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryChip(
                ctxt.tax_effectiveRate,
                '${GuestModeUtil.applyGuestMode(widget.tax.effectiveRate, isGuestMode).toStringAsFixed(1)}%',
                textTheme,
                color,
                spacing,
              ),
              _summaryChip(
                ctxt.tax_monthlyTax,
                null,
                textTheme,
                color,
                spacing,
                amount: GuestModeUtil.applyGuestMode(
                  widget.tax.monthlyTax,
                  isGuestMode,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          // FY progress
          LinearProgressIndicator(
            semanticsLabel: 'Progress',
            value: widget.tax.progressPercent.clamp(0.0, 1.0),
            backgroundColor: color.surfaceContainerHighest,
            color: color.primary,
            borderRadius: spacing.borderRadiusSmall,
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.tax_fyProgress(widget.tax.daysElapsed, widget.tax.totalDays),
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final (String label, Color badgeColor) =
        switch (widget.tax.confidenceTier) {
      ConfidenceTier.high => ('HIGH', color.primary),
      ConfidenceTier.medium => ('MEDIUM', Colors.amber.shade700),
      ConfidenceTier.low => ('LOW', color.error),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: spacing.borderRadiusSmall,
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _summaryChip(
    String label,
    String? value,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing, {
    double? amount,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        if (amount != null)
          CurrencyText(
            amount: amount,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Text(
            value!,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildSlabCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final activeSlabs =
        widget.tax.slabBreakdown.where((s) => s.taxableAmount > 0).toList();
    if (activeSlabs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.layers,
                color: color.primary,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_slabBreakdown,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          ...activeSlabs.map(
            (slab) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(slab.label, style: textTheme.bodyMedium),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${slab.rate.toStringAsFixed(0)}%',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: CurrencyText(
                      amount: GuestModeUtil.applyGuestMode(
                        slab.tax,
                        isGuestMode,
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
          SizedBox(height: spacing.elementGapMin),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ctxt.tax_totalSlabTax,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              CurrencyText(
                amount: GuestModeUtil.applyGuestMode(
                    widget.tax.baseTax, isGuestMode),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calculator,
                color: color.primary,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_computation,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          _computationRow(
            ctxt.tax_grossIncome,
            widget.tax.projectedAnnualIncome,
            textTheme,
            color,
            isGuestMode,
            spacing,
          ),
          _computationRow(
            ctxt.tax_standardDeduction,
            -widget.tax.standardDeduction,
            textTheme,
            color,
            isGuestMode,
            spacing,
          ),
          Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
          _computationRow(
            ctxt.tax_taxableIncome,
            widget.tax.taxableIncome,
            textTheme,
            color,
            isGuestMode,
            spacing,
            bold: true,
          ),
          SizedBox(height: spacing.elementGap),
          _computationRow(
            ctxt.tax_baseTax,
            widget.tax.baseTax,
            textTheme,
            color,
            isGuestMode,
            spacing,
          ),
          if (widget.tax.rebate > 0)
            _computationRow(
              ctxt.tax_rebate87A,
              -widget.tax.rebate,
              textTheme,
              color,
              isGuestMode,
              spacing,
              valueColor: FinanceColors.goodColor(brightness),
            ),
          _computationRow(
            ctxt.tax_cess,
            widget.tax.cess,
            textTheme,
            color,
            isGuestMode,
            spacing,
          ),
          Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
          _computationRow(
            ctxt.tax_totalTax,
            widget.tax.totalTax,
            textTheme,
            color,
            isGuestMode,
            spacing,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _computationRow(
    String label,
    double amount,
    TextTheme textTheme,
    ColorScheme color,
    bool isGuestMode,
    AppSpacing spacing, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.elementGapMin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: (bold ? textTheme.titleSmall : textTheme.bodyMedium)
                  ?.copyWith(
                fontWeight: bold ? FontWeight.w700 : null,
                color: bold ? null : color.onSurfaceVariant,
              ),
            ),
          ),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(amount, isGuestMode),
            style:
                (bold ? textTheme.titleSmall : textTheme.bodyMedium)?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegimeComparisonCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
  ) {
    final oldRegime = widget.tax.oldRegimeEstimate!;
    final newBetter = !widget.tax.oldRegimeBetter;
    final savings = widget.tax.regimeSavings;
    final savingsColor = FinanceColors.goodColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: savingsColor.withValues(alpha: 0.06),
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(color: savingsColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.scale,
                color: savingsColor,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                widget.ctxt.tax_regimeComparison,
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: _regimeColumn(
                  widget.ctxt.tax_newRegime,
                  widget.tax.totalTax,
                  newBetter,
                  color,
                  textTheme,
                  isGuestMode,
                  savingsColor,
                  spacing,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _regimeColumn(
                  widget.ctxt.tax_oldRegime,
                  oldRegime.totalTax,
                  !newBetter,
                  color,
                  textTheme,
                  isGuestMode,
                  savingsColor,
                  spacing,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: savingsColor.withValues(alpha: 0.08),
              borderRadius: spacing.borderRadiusMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.circleCheck, size: 16, color: savingsColor),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  widget.ctxt.tax_regimeSavings(
                    newBetter
                        ? widget.ctxt.tax_newRegime
                        : widget.ctxt.tax_oldRegime,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: savingsColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacing.elementGapMin),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(savings, isGuestMode),
                  fixedLength: 0,
                  style: textTheme.bodySmall?.copyWith(
                    color: savingsColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            widget.ctxt.tax_oldRegimeDisclaimer,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _regimeColumn(
    String label,
    double totalTax,
    bool isBetter,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    Color savingsColor,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.elementGap),
      decoration: BoxDecoration(
        color: isBetter
            ? savingsColor.withValues(alpha: 0.08)
            : color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(
          color: isBetter
              ? savingsColor.withValues(alpha: 0.3)
              : color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isBetter) ...[
                SizedBox(width: spacing.elementGapMin),
                Icon(LucideIcons.circleCheck, size: 14, color: savingsColor),
              ],
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(totalTax, isGuestMode),
            fixedLength: 0,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isBetter ? savingsColor : color.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    Map<String, double> categories,
    IconData icon,
    Color iconColor,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing,
  ) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5);
    final total = categories.values.fold<double>(0, (s, v) => s + v);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: spacing.iconLG),
              SizedBox(width: spacing.elementGap),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          ...top.map((e) {
            final pct = total > 0 ? (e.value / total * 100) : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.key, style: textTheme.bodyMedium),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  CurrencyText(
                    amount: GuestModeUtil.applyGuestMode(
                      e.value,
                      isGuestMode,
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildOpportunitiesCard(
    BuildContext context,
    List<TaxOpportunity> opportunities,
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    // Skip regime from this card — it has its own dedicated section above
    final nonRegime =
        opportunities.where((o) => o.type != OpportunityType.regime).toList();
    if (nonRegime.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                color: Colors.amber.shade700,
                size: spacing.iconLG,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_opportunities,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          ...nonRegime.map(
            (opp) => _buildOpportunityRow(
              opp,
              color,
              textTheme,
              isGuestMode,
              spacing,
              ctxt,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TaxDeductionInputScreen(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.pencil, size: 16),
              label: Text(ctxt.tax_editDeductions),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityRow(
    TaxOpportunity opp,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final title = _opportunityTitle(
      opp.type,
      ctxt,
    );
    final description = _opportunityDescription(
      opp.type,
      ctxt,
    );

    final isQuantified = opp.status == OpportunityStatus.quantified;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isQuantified ? LucideIcons.circleCheck : LucideIcons.circleHelp,
            size: 16,
            color: isQuantified ? color.primary : color.onSurfaceVariant,
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (isQuantified && opp.estimatedSavings != null)
                  Row(
                    children: [
                      Text(
                        ctxt.tax_oppSaveUpTo,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      CurrencyText(
                        amount: GuestModeUtil.applyGuestMode(
                          opp.estimatedSavings!,
                          isGuestMode,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _opportunityTitle(OpportunityType type, AppLocalizations ctxt) {
    return switch (type) {
      OpportunityType.regime => ctxt.tax_oppRegime,
      OpportunityType.nps => ctxt.tax_oppNps,
      OpportunityType.section80c => ctxt.tax_opp80c,
      OpportunityType.hra => ctxt.tax_oppHra,
      OpportunityType.homeLoan => ctxt.tax_oppHomeLoan,
      OpportunityType.medicalInsurance => ctxt.tax_oppMedical,
    };
  }

  String _opportunityDescription(OpportunityType type, AppLocalizations ctxt) {
    return switch (type) {
      OpportunityType.regime => ctxt.tax_oppRegimeDesc,
      OpportunityType.nps => ctxt.tax_oppNpsDesc,
      OpportunityType.section80c => ctxt.tax_opp80cDesc,
      OpportunityType.hra => ctxt.tax_oppHraDesc,
      OpportunityType.homeLoan => ctxt.tax_oppHomeLoanDesc,
      OpportunityType.medicalInsurance => ctxt.tax_oppMedicalDesc,
    };
  }

  Widget _buildAssumptionsCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: spacing.iconSM,
                color: Colors.amber.shade700,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_assumptions,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          ...widget.tax.assumptions.map(
            (a) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGapMin),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _assumptionLabel(a, ctxt),
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Warnings if any
          if (widget.tax.warnings.isNotEmpty) ...[
            SizedBox(height: spacing.elementGap),
            ...widget.tax.warnings.map(
              (w) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 12,
                      color: color.error,
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Expanded(
                      child: Text(
                        _warningLabel(w, ctxt),
                        style: textTheme.bodySmall?.copyWith(
                          color: color.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _assumptionLabel(TaxAssumption assumption, AppLocalizations ctxt) {
    return switch (assumption) {
      TaxAssumption.projectedIncome => ctxt.tax_assumeProjected,
      TaxAssumption.noDeductionsConsidered => ctxt.tax_assumeNoDeductions,
      TaxAssumption.noTdsConsidered => ctxt.tax_assumeNoTds,
      TaxAssumption.allIncomeTaxable => ctxt.tax_assumeAllTaxable,
      TaxAssumption.oldRegimeNoDeductions => ctxt.tax_assumeOldNoDeductions,
    };
  }

  String _warningLabel(TaxWarning warning, AppLocalizations ctxt) {
    return switch (warning) {
      TaxWarning.insufficientData => ctxt.tax_warnInsufficientData,
      TaxWarning.highIncomeVariance => ctxt.tax_warnHighVariance,
      TaxWarning.singleIncomeSource => ctxt.tax_warnSingleSource,
    };
  }

  Widget _buildDisclaimer(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: spacing.iconSM,
            color: color.onSurfaceVariant,
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              ctxt.tax_disclaimer,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlannerOption {
  nps,
  section80C,
  section80D,
  hra,
  homeLoan,
}
