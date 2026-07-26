import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';

/// Tax assumptions card showing calculation assumptions and warnings.
class TaxAssumptionsCard extends StatelessWidget {
  final List<TaxAssumption> assumptions;
  final List<TaxWarning> warnings;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxAssumptionsCard({
    super.key,
    required this.assumptions,
    required this.warnings,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Semantics(
      label: ctxt.tax_assumptions,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...assumptions.map(
              (a) => AssumptionRow(
                assumption: a,
                spacing: spacing,
                ctxt: ctxt,
              ),
            ),
            if (warnings.isNotEmpty) ...[
              SizedBox(height: spacing.elementGap),
              ...warnings.map(
                (w) => WarningRow(
                  warning: w,
                  spacing: spacing,
                  ctxt: ctxt,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AssumptionRow extends StatelessWidget {
  final TaxAssumption assumption;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const AssumptionRow({
    super.key,
    required this.assumption,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
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
              _assumptionLabel(assumption, ctxt),
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
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
}

class WarningRow extends StatelessWidget {
  final TaxWarning warning;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const WarningRow({
    super.key,
    required this.warning,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
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
              _warningLabel(warning, ctxt),
              style: textTheme.bodySmall?.copyWith(
                color: color.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _warningLabel(TaxWarning warning, AppLocalizations ctxt) {
    return switch (warning) {
      TaxWarning.insufficientData => ctxt.tax_warnInsufficientData,
      TaxWarning.highIncomeVariance => ctxt.tax_warnHighVariance,
      TaxWarning.singleIncomeSource => ctxt.tax_warnSingleSource,
    };
  }
}