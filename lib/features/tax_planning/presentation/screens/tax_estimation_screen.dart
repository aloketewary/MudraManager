export '../components/index.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/tax_planning/index.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

class TaxEstimationScreen extends ConsumerStatefulWidget {
  const TaxEstimationScreen({super.key});

  @override
  ConsumerState<TaxEstimationScreen> createState() =>
      _TaxEstimationScreenState();
}

class _TaxEstimationScreenState extends ConsumerState<TaxEstimationScreen> {
  bool _isPlanningMode = false;
  final Map<String, double> _plannedDeductions = {};

  void _togglePlanningMode() {
    setState(() {
      _isPlanningMode = !_isPlanningMode;
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

  void _handleBackButton() {
    if (_isPlanningMode) {
      _togglePlanningMode();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taxAsync = ref.watch(taxEstimationProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return ScreenShell(
      config: ScreenShellConfig(
        title: _isPlanningMode ? ctxt.tax_plannerTitle : ctxt.tax_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _handleBackButton();
        },
      ),
      actions: ScreenActions.build(
        trailing: ScreenTextAction(
          id: 'plan',
          label: _isPlanningMode ? ctxt.common_done : ctxt.tax_startPlanning,
          onTap: _togglePlanningMode,
        ),
      ),
      body: PopScope(
        canPop: !_isPlanningMode,
        onPopInvokedWithResult: (didPop, result) {
          if (_isPlanningMode) {
            _togglePlanningMode();
          }
        },
        child: taxAsync.when(
          data: (tax) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── REGIME COMPARISON ── (High priority, top of content)
                if (tax.oldRegimeEstimate != null) ...[
                  TypeSectionHeader(
                    label: ctxt.tax_regimeComparison,
                    icon: LucideIcons.scale,
                    accentColor: color.primary,
                  ),
                  SizedBox(height: spacing.elementGap),
                  RegimeComparisonCard(tax: tax, ctxt: ctxt, spacing: spacing),
                  SizedBox(height: spacing.elementGap * 2),
                ],

                // ── PLANNING MODE INDICATOR ──
                AnimatedSize(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isPlanningMode
                      ? TaxPlanningIndicatorCard(
                          plannedDeductions: _plannedDeductions,
                          ctxt: ctxt,
                          spacing: spacing,
                        )
                      : const SizedBox.shrink(),
                ),
                if (_isPlanningMode) SizedBox(height: spacing.elementGap * 2),

                // ── PLANNING MODE WIDGETS ──
                AnimatedSize(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isPlanningMode
                      ? Column(
                          key: const ValueKey('planning_widgets'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TypeSectionHeader(
                              label: ctxt.tax_plannerDeductions,
                              icon: LucideIcons.slidersHorizontal,
                              accentColor: color.primary,
                            ),
                            SizedBox(height: spacing.elementGap),
                            DeductionPlannerCard(
                              plannedDeductions: _plannedDeductions,
                              onUpdateDeduction: _updatePlannedDeduction,
                              ctxt: ctxt,
                              spacing: spacing,
                            ),
                            SizedBox(height: spacing.elementGap * 2),
                            TypeSectionHeader(
                              label: ctxt.tax_planningImpact,
                              icon: LucideIcons.trendingUp,
                              accentColor: color.primary,
                            ),
                            SizedBox(height: spacing.elementGap),
                            PlanningImpactCard(
                              tax: tax,
                              plannedDeductions: _plannedDeductions,
                              ctxt: ctxt,
                              spacing: spacing,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                if (_isPlanningMode) SizedBox(height: spacing.sectionGap),

                // ── TAX SUMMARY (if not planning) ──
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  child: !tax.isZeroTax && !_isPlanningMode
                      ? TaxSummaryCard(
                          tax: tax,
                          ctxt: ctxt,
                          spacing: spacing,
                        )
                      : const SizedBox.shrink(),
                ),
                if (!tax.isZeroTax && !_isPlanningMode)
                  SizedBox(height: spacing.elementGap * 2),

                // ── TAX OPPORTUNITIES ──
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  child: !tax.isZeroTax && !_isPlanningMode
                      ? ref.watch(taxOpportunitiesProvider).when(
                          data: (opps) => opps.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TypeSectionHeader(
                                      label: ctxt.tax_opportunities,
                                      icon: LucideIcons.lightbulb,
                                      accentColor: color.primary,
                                    ),
                                    SizedBox(height: spacing.elementGap),
                                    TaxOpportunityCard(
                                      opportunities: opps,
                                      onEditDeductions: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const TaxDeductionInputScreen(),
                                          ),
                                        );
                                      },
                                      ctxt: ctxt,
                                      spacing: spacing,
                                    ),
                                  ],
                                ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
                if (!tax.isZeroTax && !_isPlanningMode)
                  SizedBox(height: spacing.elementGap * 2),

                // ── TAX COMPUTATION ── (Important section)
                TypeSectionHeader(
                  label: ctxt.tax_computation,
                  icon: LucideIcons.calculator,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                TaxComputationCard(tax: tax, ctxt: ctxt, spacing: spacing),
                SizedBox(height: spacing.elementGap * 2),

                // ── TAX SLAB BREAKDOWN ── (Important section)
                TypeSectionHeader(
                  label: ctxt.tax_slabBreakdown,
                  icon: LucideIcons.layers,
                  accentColor: color.primary,
                ),
                SizedBox(height: spacing.elementGap),
                TaxSlabCard(tax: tax, ctxt: ctxt, spacing: spacing),
                SizedBox(height: spacing.elementGap * 2),

                // ── INCOME BREAKDOWN ──
                if (tax.incomeByCategory.isNotEmpty) ...[
                  TypeSectionHeader(
                    label: ctxt.tax_incomeBreakdown,
                    icon: LucideIcons.trendingUp,
                    accentColor: color.primary,
                  ),
                  SizedBox(height: spacing.elementGap),
                  IncomeBreakdownCard(
                    title: ctxt.tax_incomeBreakdown,
                    categories: tax.incomeByCategory,
                    icon: LucideIcons.trendingUp,
                    iconColor: FinanceColors.incomeColor(brightness),
                    ctxt: ctxt,
                    spacing: spacing,
                  ),
                  SizedBox(height: spacing.elementGap * 2),
                ],

                // ── ASSUMPTIONS ──
                if (tax.assumptions.isNotEmpty) ...[
                  TypeSectionHeader(
                    label: ctxt.tax_assumptions,
                    icon: LucideIcons.circleAlert,
                    accentColor: color.onSurfaceVariant,
                  ),
                  SizedBox(height: spacing.elementGap),
                  TaxAssumptionsCard(
                    assumptions: tax.assumptions,
                    warnings: tax.warnings,
                    ctxt: ctxt,
                    spacing: spacing,
                  ),
                  SizedBox(height: spacing.elementGap * 2),
                ],

                // ── DISCLAIMER ──
                TaxDisclaimerCard(
                  ctxt: ctxt,
                  spacing: spacing,
                ),
                SizedBox(height: spacing.sectionGap * 1.33),
              ],
            ),
          ),
          loading: () => ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: List.generate(
              3,
              (_) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap * 2),
                child: const DashboardCardSkeleton(),
              ),
            ),
          ),
          error: (_, __) => NoDataFound(
            message: ctxt.tax_noData,
            iconData: LucideIcons.receiptIndianRupee,
          ),
        ),
      ),
    );
  }
}
