import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Subscription transaction card body with recurring indicator.
///
/// Features:
/// - Animated recurring badge
/// - Tap-to-unlink subscription
/// - Reduced motion support
/// - Consistent spacing via AppSpacing
class SubscriptionTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const SubscriptionTransactionCardBody({super.key, required this.data});

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
          child: _buildInfoColumn(textTheme, colorScheme, spacing, ctxt, isReducedMotion),
        ),
        SizedBox(width: spacing.elementGap),
        _buildAmountColumn(textTheme, colorScheme, spacing, ctxt, amountColor),
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
          child: _RecurringBadge(spacing: spacing, colorScheme: colorScheme),
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
            _SubscriptionTag(
              spacing: spacing,
              colorScheme: colorScheme,
              textTheme: textTheme,
              onUnlink: data.onUnlinkRecurring,
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

/// Animated recurring badge indicator.
class _RecurringBadge extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const _RecurringBadge({
    required this.spacing,
    required this.colorScheme,
  });

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

/// Subscription tag with optional unlink action.
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