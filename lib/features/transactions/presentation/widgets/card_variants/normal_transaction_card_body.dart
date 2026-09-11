import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_row.dart';

/// Normal transaction card body displaying category, account, and amount.
class NormalTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const NormalTransactionCardBody({super.key, required this.data});

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
        ),
        SizedBox(width: spacing.elementGap + spacing.elementGapMin),
        Expanded(
          child: TransactionCardInfoColumn(
            title: TransactionCardTitle(data: data, textTheme: textTheme),
            metadata: TransactionCardMetadata(
              data: data,
              textTheme: textTheme,
              colorScheme: colorScheme,
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
          datePattern: 'hh:mm a',
          showConvertedAmount: true,
        ),
      ],
    );
  }
}
