import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class TaxEstimationScreen extends ConsumerWidget {
  const TaxEstimationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxEstimationProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.tax_title),
        elevation: 0,
      ),
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero summary
          _buildSummaryCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // Slab breakdown
          _buildSlabCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // Deductions & cess
          _buildDeductionsCard(color, textTheme, brightness, isGuestMode),
          SizedBox(height: spacing.sectionGap),

          // Regime comparison
          if (tax.oldRegimeEstimate != null)
            _buildRegimeComparisonCard(color, textTheme, brightness, isGuestMode),
          if (tax.oldRegimeEstimate != null)
            SizedBox(height: spacing.sectionGap),

          // Top income categories
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

          // Disclaimer
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
    final taxColor = tax.isZeroTax
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
          Text(
            tax.financialYear,
            style: textTheme.titleSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
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
              Icon(LucideIcons.layers, color: color.primary, size: spacing.iconLG),
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
          ...activeSlabs.map((slab) => Padding(
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
              )),
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
              Icon(LucideIcons.calculator, color: color.primary, size: spacing.iconLG),
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
            style: (bold ? textTheme.titleSmall : textTheme.bodyMedium)
                ?.copyWith(
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
          Row(children: [
            Icon(LucideIcons.scale, color: betterColor, size: spacing.iconLG),
            SizedBox(width: spacing.elementGap),
            Text(
              ctxt.tax_regimeComparison,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
          SizedBox(height: spacing.sectionGap),
          // Side-by-side comparison
          Row(children: [
            Expanded(child: _regimeColumn(
              ctxt.tax_newRegime,
              tax.totalTax,
              newBetter,
              color, textTheme, isGuestMode, betterColor,
            )),
            SizedBox(width: spacing.elementGap),
            Expanded(child: _regimeColumn(
              ctxt.tax_oldRegime,
              oldRegime.totalTax,
              !newBetter,
              color, textTheme, isGuestMode, betterColor,
            )),
          ]),
          SizedBox(height: spacing.sectionGap),
          // Verdict
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
                    color: betterColor, fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacing.elementGapMin),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(savings, isGuestMode),
                  fixedLength: 0,
                  style: textTheme.bodySmall?.copyWith(
                    color: betterColor, fontWeight: FontWeight.w700,
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
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
          if (isBetter) ...[
            SizedBox(width: spacing.elementGapMin),
            Icon(LucideIcons.circleCheck, size: 14, color: betterColor),
          ],
        ]),
        SizedBox(height: spacing.elementGapMin),
        CurrencyText(
          amount: GuestModeUtil.applyGuestMode(totalTax, isGuestMode),
          fixedLength: 0,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isBetter ? betterColor : color.onSurface,
          ),
        ),
      ]),
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
          ...top.map((e) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(e.key, style: textTheme.bodyMedium)),
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
              )),
        ],
      ),
    );
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
