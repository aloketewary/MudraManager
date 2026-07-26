import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Tax computation card showing income, deductions, and tax breakdown.
class TaxComputationCard extends ConsumerWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxComputationCard({
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

    return Semantics(
      label: ctxt.tax_computation,
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
            _ComputationRow(
              label: ctxt.tax_grossIncome,
              amount: tax.projectedAnnualIncome,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            _ComputationRow(
              label: ctxt.tax_standardDeduction,
              amount: -tax.standardDeduction,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
            _ComputationRow(
              label: ctxt.tax_taxableIncome,
              amount: tax.taxableIncome,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
              bold: true,
            ),
            SizedBox(height: spacing.elementGap),
            _ComputationRow(
              label: ctxt.tax_baseTax,
              amount: tax.baseTax,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            if (tax.rebate > 0)
              _ComputationRow(
                label: ctxt.tax_rebate87A,
                amount: -tax.rebate,
                isGuestMode: isGuestMode,
                color: color,
                textTheme: textTheme,
                spacing: spacing,
                valueColor: FinanceColors.goodColor(brightness),
              ),
            _ComputationRow(
              label: ctxt.tax_cess,
              amount: tax.cess,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            Divider(color: color.outlineVariant.withValues(alpha: 0.5)),
            _ComputationRow(
              label: ctxt.tax_totalTax,
              amount: tax.totalTax,
              isGuestMode: isGuestMode,
              color: color,
              textTheme: textTheme,
              spacing: spacing,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComputationRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isGuestMode;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final bool bold;
  final Color? valueColor;

  const _ComputationRow({
    required this.label,
    required this.amount,
    required this.isGuestMode,
    required this.color,
    required this.textTheme,
    required this.spacing,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
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
}