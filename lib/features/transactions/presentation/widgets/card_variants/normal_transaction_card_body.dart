import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class NormalTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const NormalTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final categoryColor = Color(data.category?.colorValue ?? 0xFF000000);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          child: Icon(
            IconHelper.getIconData(data.category?.iconName),
            color: categoryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
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
              const SizedBox(height: 4),
              Flexible(
                child: AdaptiveText(
                  '${data.account?.name} • ${data.account?.accountType.name.toTitleCase()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ),
              if (data.hasDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AnimatedRotation(
                    turns: data.expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 14,
                      color: color.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
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
                color: data.isExpense
                    ? FinanceColors.expenseColor(Theme.of(context).brightness)
                    : FinanceColors.incomeColor(Theme.of(context).brightness),
              ),
              maxLines: 1,
            ),
            if (data.currencyCode != null && data.convertedAmount != null)
              CurrencyText(
                amount: data.convertedAmount!,
                compact: true,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                prefixText: '≈',
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd', ctxt.localeName).format(data.date),
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
