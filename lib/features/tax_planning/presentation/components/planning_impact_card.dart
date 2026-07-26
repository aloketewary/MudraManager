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

/// Planning impact card showing current tax vs projected tax after deductions.
class PlanningImpactCard extends ConsumerWidget {
  final TaxEstimate tax;
  final Map<String, double> plannedDeductions;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const PlanningImpactCard({
    super.key,
    required this.tax,
    required this.plannedDeductions,
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

    final totalPlanned =
        plannedDeductions.values.fold<double>(0, (a, b) => a + b);
    final currentTax = tax.totalTax;
    final estimatedSavings = totalPlanned * 0.3;
    final newTax =
        (currentTax - estimatedSavings).clamp(0, currentTax).toDouble();

    return Semantics(
      label: ctxt.tax_planningImpact,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              savingsColor.withValues(alpha: 0.08),
              savingsColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: savingsColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ImpactColumn(
                    label: ctxt.tax_currentTax,
                    amount: currentTax,
                    isGuestMode: isGuestMode,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                ),
                Icon(LucideIcons.arrowRight, color: color.onSurfaceVariant),
                Expanded(
                  child: _ImpactColumn(
                    label: ctxt.tax_projectedTax,
                    amount: newTax,
                    isGuestMode: isGuestMode,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    highlight: true,
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
                color: savingsColor.withValues(alpha: 0.1),
                borderRadius: spacing.borderRadiusMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.circleCheck, size: 16, color: savingsColor),
                  SizedBox(width: spacing.elementGapMin),
                  Text(
                    ctxt.tax_totalSavings,
                    style: textTheme.bodySmall?.copyWith(color: savingsColor),
                  ),
                  SizedBox(width: spacing.elementGapMin),
                  CurrencyText(
                    amount: estimatedSavings,
                    style: textTheme.bodySmall?.copyWith(
                      color: savingsColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactColumn extends StatelessWidget {
  final String label;
  final double amount;
  final bool isGuestMode;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final bool highlight;

  const _ImpactColumn({
    required this.label,
    required this.amount,
    required this.isGuestMode,
    required this.color,
    required this.textTheme,
    required this.spacing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        CurrencyText(
          amount: GuestModeUtil.applyGuestMode(amount, isGuestMode),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? color.primary : null,
          ),
        ),
      ],
    );
  }
}