import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Regime comparison card showing old vs new tax regime comparison.
class RegimeComparisonCard extends ConsumerWidget {
  final TaxEstimate tax;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const RegimeComparisonCard({
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
    final savingsColor = FinanceColors.goodColor(brightness);

    final oldRegime = tax.oldRegimeEstimate!;
    final newBetter = !tax.oldRegimeBetter;
    final savings = tax.regimeSavings;

    return Semantics(
      label: ctxt.tax_regimeComparison,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: savingsColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: savingsColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _RegimeColumn(
                    label: ctxt.tax_newRegime,
                    totalTax: tax.totalTax,
                    isBetter: newBetter,
                    isGuestMode: isGuestMode,
                    color: color,
                    textTheme: textTheme,
                    savingsColor: savingsColor,
                    spacing: spacing,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: _RegimeColumn(
                    label: ctxt.tax_oldRegime,
                    totalTax: oldRegime.totalTax,
                    isBetter: !newBetter,
                    isGuestMode: isGuestMode,
                    color: color,
                    textTheme: textTheme,
                    savingsColor: savingsColor,
                    spacing: spacing,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
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
                    ctxt.tax_regimeSavings(
                      newBetter ? ctxt.tax_newRegime : ctxt.tax_oldRegime,
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
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ) ?? const TextStyle(),
              child: Text(ctxt.tax_oldRegimeDisclaimer),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegimeColumn extends ConsumerWidget {
  final String label;
  final double totalTax;
  final bool isBetter;
  final bool isGuestMode;
  final ColorScheme color;
  final TextTheme textTheme;
  final Color savingsColor;
  final AppSpacing spacing;

  const _RegimeColumn({
    required this.label,
    required this.totalTax,
    required this.isBetter,
    required this.isGuestMode,
    required this.color,
    required this.textTheme,
    required this.savingsColor,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: spacing.elementGap, vertical: spacing.elementGap),
      decoration: BoxDecoration(
        color: isBetter
            ? savingsColor.withValues(alpha: 0.08)
            : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: isBetter
              ? savingsColor.withValues(alpha: 0.3)
              : color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ?? const TextStyle(),
                child: Text(label),
              ),
              if (isBetter) ...[
                SizedBox(width: spacing.elementGapMin),
                Icon(
                  LucideIcons.circleCheck,
                  size: 14,
                  color: savingsColor,
                ),
              ],
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isBetter ? savingsColor : color.onSurface,
            ) ?? const TextStyle(),
            child: CurrencyText(
              amount: GuestModeUtil.applyGuestMode(totalTax, isGuestMode),
              fixedLength: 0,
            ),
          ),
        ],
      ),
    );
  }
}