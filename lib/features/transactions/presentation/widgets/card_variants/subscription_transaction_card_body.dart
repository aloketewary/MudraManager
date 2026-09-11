import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_row.dart';

/// Subscription transaction card body with recurring indicator.
class SubscriptionTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const SubscriptionTransactionCardBody({super.key, required this.data});

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
            child: _RecurringBadge(spacing: spacing, colorScheme: colorScheme),
          ),
        ),
        SizedBox(width: spacing.elementGap + spacing.elementGapMin),
        Expanded(
          child: TransactionCardInfoColumn(
            title: TransactionCardTitle(data: data, textTheme: textTheme),
            metadata: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubscriptionTag(
                  spacing: spacing,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  onUnlink: data.onUnlinkRecurring,
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

class _RecurringBadge extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const _RecurringBadge({required this.spacing, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.elementGapUltraMin + 1),
      decoration: BoxDecoration(
        color: colorScheme.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surfaceContainerLow,
          width: spacing.strokeThin,
        ),
      ),
      child: Icon(
        LucideIcons.repeat,
        size: spacing.iconXS,
        color: colorScheme.onError,
      ),
    );
  }
}

class _SubscriptionTag extends ConsumerWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onUnlink;

  const _SubscriptionTag({
    required this.spacing,
    required this.colorScheme,
    required this.textTheme,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onUnlink != null ? () => _showUnlinkDialog(context, ref) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGapMin + 2,
          vertical: spacing.elementGapUltraMin,
        ),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Subscription',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            if (onUnlink != null) ...[
              SizedBox(width: spacing.elementGapUltraMin),
              Icon(
                LucideIcons.x,
                size: spacing.iconXS - 2,
                color: colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showUnlinkDialog(BuildContext context, WidgetRef ref) async {
    final dialogSpacing = ref.read(spacingProvider);
    final confirmed = await DialogUtils.showConfirmation(
      context,
      dialogSpacing,
      title: 'Remove Subscription Tag?',
      message: 'This will unlink this transaction from the recurring bill.',
      icon: LucideIcons.repeat,
      confirmText: 'Remove',
    );
    if (confirmed == true) {
      onUnlink?.call();
    }
  }
}
