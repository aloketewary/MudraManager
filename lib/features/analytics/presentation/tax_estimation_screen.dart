import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class TaxEstimationScreen extends ConsumerWidget {
  const TaxEstimationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxEstimationProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.tax_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: taxAsync.when(
        data: (tax) => _TaxContent(tax: tax, ctxt: ctxt, spacing: spacing),
        loading: () => const Center(child: DashboardCardSkeleton()),
        error: (_, __) => Center(child: Text(ctxt.tax_noData)),
      ),
    );
  }
}

class _TaxContent extends ConsumerWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const _TaxContent({
    required this.tax,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final isGuestMode = ref.watch(guestModeProvider);
    final opportunities = ref.watch(taxOpportunitiesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero summary
          _buildSummaryCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // 2. Regime comparison (promoted — decision before detail)
          if (tax.oldRegimeEstimate != null) ...[
            _buildRegimeComparisonCard(
              color,
              textTheme,
              brightness,
              isGuestMode,
            ),
            SizedBox(height: spacing.sectionGap),
          ],

          // 3. Opportunities (what can reduce tax?)
          if (!tax.isZeroTax)
            opportunities.when(
              data: (opps) => opps.isEmpty
                  ? const SizedBox.shrink()
                  : _buildOpportunitiesCard(
                      context,
                      opps,
                      color,
                      textTheme,
                      brightness,
                      isGuestMode,
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          if (!tax.isZeroTax) SizedBox(height: spacing.sectionGap),

          // 4. Tax computation
          _buildDeductionsCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // 5. Slab breakdown
          _buildSlabCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // 6. Income breakdown (with percentages)
          if (tax.incomeByCategory.isNotEmpty) ...[
            _buildCategoryCard(
              ctxt.tax_incomeBreakdown,
              tax.incomeByCategory,
              LucideIcons.trendingUp,
              FinanceColors.incomeColor(brightness),
              color,
              textTheme,
              isGuestMode,
            ),
            SizedBox(height: spacing.sectionGap),
          ],

          // 7. Assumptions
          if (tax.assumptions.isNotEmpty)
            _buildAssumptionsCard(color, textTheme),
          if (tax.assumptions.isNotEmpty) SizedBox(height: spacing.sectionGap),

          // 8. Disclaimer
          _buildDisclaimer(color, textTheme),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ColorScheme color,
    TextTheme textTheme,
    Brightness brightness,
    bool isGuestMode,
  ) {
    final taxColor =
        tax.isZeroTax ? FinanceColors.goodColor(brightness) : color.onSurface;

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
                tax.financialYear,
                style: textTheme.titleSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              _buildConfidenceBadge(color, textTheme),
            ],
          ),
          if (tax.isProjected)
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
            amount: GuestModeUtil.applyGuestMode(tax.totalTax, isGuestMode),
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
                '${GuestModeUtil.applyGuestMode(tax.effectiveRate, isGuestMode).toStringAsFixed(1)}%',
                textTheme,
                color,
              ),
              _summaryChip(
                ctxt.tax_monthlyTax,
                null,
                textTheme,
                color,
                amount: GuestModeUtil.applyGuestMode(
                  tax.monthlyTax,
                  isGuestMode,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          // FY progress
          LinearProgressIndicator(
            semanticsLabel: 'Progress',
            value: tax.progressPercent.clamp(0.0, 1.0),
            backgroundColor: color.surfaceContainerHighest,
            color: color.primary,
            borderRadius: spacing.borderRadiusSmall,
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.tax_fyProgress(tax.daysElapsed, tax.totalDays),
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(ColorScheme color, TextTheme textTheme) {
    final (String label, Color badgeColor) = switch (tax.confidenceTier) {
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
    ColorScheme color, {
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
  ) {
    final activeSlabs =
        tax.slabBreakdown.where((s) => s.taxableAmount > 0).toList();
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
                amount: GuestModeUtil.applyGuestMode(tax.baseTax, isGuestMode),
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
            tax.projectedAnnualIncome,
            textTheme,
            color,
            isGuestMode,
          ),
          _computationRow(
            ctxt.tax_standardDeduction,
            -tax.standardDeduction,
            textTheme,
            color,
            isGuestMode,
          ),
          Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
          _computationRow(
            ctxt.tax_taxableIncome,
            tax.taxableIncome,
            textTheme,
            color,
            isGuestMode,
            bold: true,
          ),
          SizedBox(height: spacing.elementGap),
          _computationRow(
            ctxt.tax_baseTax,
            tax.baseTax,
            textTheme,
            color,
            isGuestMode,
          ),
          if (tax.rebate > 0)
            _computationRow(
              ctxt.tax_rebate87A,
              -tax.rebate,
              textTheme,
              color,
              isGuestMode,
              valueColor: FinanceColors.goodColor(brightness),
            ),
          _computationRow(
            ctxt.tax_cess,
            tax.cess,
            textTheme,
            color,
            isGuestMode,
          ),
          Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
          _computationRow(
            ctxt.tax_totalTax,
            tax.totalTax,
            textTheme,
            color,
            isGuestMode,
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
    bool isGuestMode, {
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
  ) {
    final oldRegime = tax.oldRegimeEstimate!;
    final newBetter = !tax.oldRegimeBetter;
    final savings = tax.regimeSavings;
    final betterColor = FinanceColors.goodColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: betterColor.withValues(alpha: 0.06),
        borderRadius: spacing.borderRadiusLarge,
        border: Border.all(color: betterColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, color: betterColor, size: spacing.iconLG),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.tax_regimeComparison,
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
                  ctxt.tax_newRegime,
                  tax.totalTax,
                  newBetter,
                  color,
                  textTheme,
                  isGuestMode,
                  betterColor,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _regimeColumn(
                  ctxt.tax_oldRegime,
                  oldRegime.totalTax,
                  !newBetter,
                  color,
                  textTheme,
                  isGuestMode,
                  betterColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: betterColor.withValues(alpha: 0.08),
              borderRadius: spacing.borderRadiusMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.circleCheck, size: 16, color: betterColor),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  ctxt.tax_regimeSavings(
                    newBetter ? ctxt.tax_newRegime : ctxt.tax_oldRegime,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: betterColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacing.elementGapMin),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(savings, isGuestMode),
                  fixedLength: 0,
                  style: textTheme.bodySmall?.copyWith(
                    color: betterColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            ctxt.tax_oldRegimeDisclaimer,
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
    Color betterColor,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.elementGap),
      decoration: BoxDecoration(
        color: isBetter
            ? betterColor.withValues(alpha: 0.08)
            : color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(
          color: isBetter
              ? betterColor.withValues(alpha: 0.3)
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
                Icon(LucideIcons.circleCheck, size: 14, color: betterColor),
              ],
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(totalTax, isGuestMode),
            fixedLength: 0,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isBetter ? betterColor : color.onSurface,
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
            (opp) => _buildOpportunityRow(opp, color, textTheme, isGuestMode),
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
  ) {
    final title = _opportunityTitle(opp.type);
    final description = _opportunityDescription(opp.type);

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

  String _opportunityTitle(OpportunityType type) {
    return switch (type) {
      OpportunityType.regime => ctxt.tax_oppRegime,
      OpportunityType.nps => ctxt.tax_oppNps,
      OpportunityType.section80c => ctxt.tax_opp80c,
      OpportunityType.hra => ctxt.tax_oppHra,
      OpportunityType.homeLoan => ctxt.tax_oppHomeLoan,
      OpportunityType.medicalInsurance => ctxt.tax_oppMedical,
    };
  }

  String _opportunityDescription(OpportunityType type) {
    return switch (type) {
      OpportunityType.regime => ctxt.tax_oppRegimeDesc,
      OpportunityType.nps => ctxt.tax_oppNpsDesc,
      OpportunityType.section80c => ctxt.tax_opp80cDesc,
      OpportunityType.hra => ctxt.tax_oppHraDesc,
      OpportunityType.homeLoan => ctxt.tax_oppHomeLoanDesc,
      OpportunityType.medicalInsurance => ctxt.tax_oppMedicalDesc,
    };
  }

  Widget _buildAssumptionsCard(ColorScheme color, TextTheme textTheme) {
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
          ...tax.assumptions.map(
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
          if (tax.warnings.isNotEmpty) ...[
            SizedBox(height: spacing.elementGap),
            ...tax.warnings.map(
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

  Widget _buildDisclaimer(ColorScheme color, TextTheme textTheme) {
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
