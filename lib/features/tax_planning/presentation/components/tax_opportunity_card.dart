import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Tax opportunity card showing tax-saving suggestions.
class TaxOpportunityCard extends ConsumerWidget {
  final List<TaxOpportunity> opportunities;
  final VoidCallback onEditDeductions;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxOpportunityCard({
    super.key,
    required this.opportunities,
    required this.onEditDeductions,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;

    final nonRegime =
        opportunities.where((o) => o.type != OpportunityType.regime).toList();
    if (nonRegime.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: ctxt.tax_opportunities,
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
            ...nonRegime.map(
              (opp) => TaxOpportunityRow(
                opp: opp,
                spacing: spacing,
                ctxt: ctxt,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            _EditDeductionsButton(
              onTap: onEditDeductions,
              spacing: spacing,
              ctxt: ctxt,
            ),
          ],
        ),
      ),
    );
  }
}

class TaxOpportunityRow extends ConsumerWidget {
  final TaxOpportunity opp;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const TaxOpportunityRow({
    super.key,
    required this.opp,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    final title = _opportunityTitle(opp.type, ctxt);
    final description = _opportunityDescription(opp.type, ctxt);
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
}

class _EditDeductionsButton extends StatelessWidget {
  final VoidCallback onTap;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _EditDeductionsButton({
    required this.onTap,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(LucideIcons.pencil, size: 16),
        label: Text(ctxt.tax_editDeductions),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
        ),
      ),
    );
  }
}