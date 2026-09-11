import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_row.dart';

/// Trip transaction card body with trip indicator badge.
class TripTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TripTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final brightness = Theme.of(context).brightness;
    final categoryColor = Color(data.category?.colorValue ?? 0xFF9E9E9E);
    final amountColor = data.isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TransactionCardIconTile(
          color: categoryColor,
          icon: IconHelper.getIconData(data.category?.iconName),
          spacing: spacing,
          colorScheme: colorScheme,
          badge: Positioned(
            right: -spacing.elementGapUltraMin,
            bottom: -spacing.elementGapUltraMin,
            child: _TripBadge(spacing: spacing, colorScheme: colorScheme),
          ),
        ),
        SizedBox(width: spacing.elementGap + spacing.elementGapMin),
        Expanded(
          child: TransactionCardInfoColumn(
            title: TransactionCardTitle(data: data, textTheme: textTheme),
            metadata: Row(
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
                    child: Text(
                      data.account!.name,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            hasDetails: data.hasDetails,
            expanded: data.expanded,
            isReducedMotion: isReducedMotion,
            spacing: spacing,
            colorScheme: colorScheme,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        TransactionCardAmountColumn(
          data: data,
          textTheme: textTheme,
          colorScheme: colorScheme,
          spacing: spacing,
          amountColor: amountColor,
          datePattern: 'MMM dd',
        ),
      ],
    );
  }
}

class _TripBadge extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const _TripBadge({required this.spacing, required this.colorScheme});

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
