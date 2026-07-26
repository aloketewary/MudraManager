import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Hero summary card showing estimated tax, effective rate, and FY progress.
class TaxSummaryCard extends ConsumerWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxSummaryCard({
    super.key,
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
    final taxColor = tax.isZeroTax
        ? FinanceColors.goodColor(brightness)
        : color.onSurface;

    return Semantics(
      label: ctxt.tax_estimatedTax,
      hint: ctxt.tax_fyProgress(tax.daysElapsed, tax.totalDays),
      child: Container(
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
                _ConfidenceBadge(
                  confidenceTier: tax.confidenceTier,
                  spacing: spacing,
                ),
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
                _SummaryChip(
                  label: ctxt.tax_effectiveRate,
                  value:
                      '${GuestModeUtil.applyGuestMode(tax.effectiveRate, isGuestMode).toStringAsFixed(1)}%',
                  spacing: spacing,
                ),
                _SummaryChip(
                  label: ctxt.tax_monthlyTax,
                  amount: GuestModeUtil.applyGuestMode(tax.monthlyTax, isGuestMode),
                  spacing: spacing,
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            // FY progress
            Semantics(
              label: 'Financial year ${tax.financialYear} progress',
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: tax.progressPercent.clamp(0.0, 1.0),
                  backgroundColor: color.surfaceContainerHighest,
                  color: color.primary,
                  borderRadius: spacing.borderRadiusSmall,
                ),
              ),
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
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final ConfidenceTier confidenceTier;
  final AppSpacing spacing;

  const _ConfidenceBadge({
    required this.confidenceTier,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (String label, Color badgeColor) = switch (confidenceTier) {
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
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String? value;
  final double? amount;
  final AppSpacing spacing;

  const _SummaryChip({
    required this.label,
    this.value,
    this.amount,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        if (amount != null)
          CurrencyText(
            amount: amount!,
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
}