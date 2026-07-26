import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Planning indicator card with smooth fade and slide animations.
class TaxPlanningIndicatorCard extends StatelessWidget {
  final Map<String, double> plannedDeductions;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxPlanningIndicatorCard({
    super.key,
    required this.plannedDeductions,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalPlanned =
        plannedDeductions.values.fold<double>(0, (a, b) => a + b);
    final potentialSavings = totalPlanned * 0.3;
    final hasDeductions = totalPlanned > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctxt.tax_plannedDeductions,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.primary,
                      ) ?? const TextStyle(),
                      child: CurrencyText(amount: totalPlanned),
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FinanceColors.goodColor(
                          Theme.of(context).brightness,
                        ),
                      ) ?? const TextStyle(),
                      child: CurrencyText(amount: potentialSavings),
                    ),
                  ],
                ),
              ],
            ),
            secondChild: Text(
              ctxt.tax_addDeductionsPrompt,
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
            crossFadeState: hasDeductions
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}