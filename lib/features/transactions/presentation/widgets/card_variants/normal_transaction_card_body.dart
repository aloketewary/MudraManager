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

/// Normal transaction card body displaying category, account, and amount.
///
/// Features:
/// - Dynamic sizing based on AppSpacing
/// - Animated chevron for expandable cards
/// - Reduced motion support
/// - Currency conversion display
class NormalTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const NormalTransactionCardBody({super.key, required this.data});

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
        _buildCategoryIcon(categoryColor, spacing, colorScheme),
        SizedBox(width: spacing.elementGap * 1.75),
        Expanded(
          child: _buildInfoColumn(textTheme, colorScheme, spacing, ctxt, isReducedMotion,),
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

  Widget _buildCategoryIcon(
    Color categoryColor,
    AppSpacing spacing,
    ColorScheme colorScheme,
  ) {
    return Container(
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
        Flexible(
          child: AdaptiveText(
            '${data.account?.name} • ${data.account?.accountType.name}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
          ),
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
        if (data.currencyCode != null && data.convertedAmount != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
            child: CurrencyText(
              amount: data.convertedAmount!,
              compact: true,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              prefixText: '≈',
            ),
          ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          DateFormat('hh:mm a', ctxt.localeName).format(data.date),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}