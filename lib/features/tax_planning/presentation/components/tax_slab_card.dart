import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Tax slab breakdown card showing tax by income slab.
class TaxSlabCard extends ConsumerWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxSlabCard({
    super.key,
    required this.tax,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    final activeSlabs =
        tax.slabBreakdown.where((s) => s.taxableAmount > 0).toList();
    if (activeSlabs.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: ctxt.tax_slabBreakdown,
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
      ),
    );
  }
}