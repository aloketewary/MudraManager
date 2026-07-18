import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Trip transaction card body with trip indicator badge.
///
/// Features:
/// - Category icon with trip badge overlay
/// - Trip name and account info
/// - Consistent spacing via AppSpacing
/// - Reduced motion support
class TripTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TripTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final brightness = Theme.of(context).brightness;

    final categoryColor = Color(data.category?.colorValue ?? 0xFF9E9E9E);
    final amountColor = data.isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCategoryWithBadge(categoryColor, spacing, colorScheme),
        SizedBox(width: spacing.elementGap * 1.75),
        Expanded(
          child: _buildInfoColumn(
            textTheme,
            colorScheme,
            spacing,
            ctxt,
            isReducedMotion,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        _buildAmountColumn(
          textTheme,
          colorScheme,
          spacing,
          ctxt,
          amountColor,
        ),
      ],
    );
  }

  Widget _buildCategoryWithBadge(
    Color categoryColor,
    AppSpacing spacing,
    ColorScheme colorScheme,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: spacing.iconXL * 2,
          height: spacing.iconXL * 2,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          child: Icon(
            IconHelper.getIconData(data.category?.iconName),
            color: categoryColor,
            size: spacing.iconLG,
          ),
        ),
        Positioned(
          right: -spacing.elementGapUltraMin,
          bottom: -spacing.elementGapUltraMin,
          child: _TripBadge(spacing: spacing, colorScheme: colorScheme),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isReducedMotion,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveText(
          data.category?.name ?? 'Uncategorized',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TripTag(
              tripName: data.tripName ?? '',
              spacing: spacing,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            if (data.account?.name != null) ...[
              SizedBox(width: spacing.elementGapMin),
              Flexible(
                child: AdaptiveText(
                  data.account!.name,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
        if (data.hasDetails)
          Padding(
            padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
            child: AnimatedRotation(
              turns: data.expanded ? 0.5 : 0.0,
              duration: isReducedMotion ? Duration.zero : spacing.animFast,
              child: Icon(
                LucideIcons.chevronDown,
                size: spacing.iconSM,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmountColumn(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    Color amountColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyText(
          currencyCode: data.currencyCode,
          amount: data.displayAmount,
          showSign: true,
          isExpense: data.isExpense,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
          maxLines: 1,
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          DateFormat('MMM dd', ctxt.localeName).format(data.date),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Trip badge indicator (small plane icon in circle).
class _TripBadge extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const _TripBadge({
    required this.spacing,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trip indicator',
      child: Container(
        padding: EdgeInsets.all(spacing.elementGapUltraMin + 1),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.surfaceContainerLow,
            width: spacing.strokeThin,
          ),
        ),
        child: Icon(
          LucideIcons.planeTakeoff,
          size: spacing.iconXS,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Trip name tag with plane icon.
class _TripTag extends StatelessWidget {
  final String tripName;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TripTag({
    required this.tripName,
    required this.spacing,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGapMin + 2,
        vertical: spacing.elementGapUltraMin,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.planeTakeoff,
            size: spacing.iconXS - 2,
            color: colorScheme.primary,
          ),
          SizedBox(width: spacing.elementGapUltraMin),
          Text(
            tripName,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}