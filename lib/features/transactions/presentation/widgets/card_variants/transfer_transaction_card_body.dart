import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class TransferTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TransferTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final related = data.related;

    return Column(
      children: [
        Row(
          children: [
            // FROM Account
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      related?.account.value?.accountType.icon,
                      size: 16,
                      color: FinanceColors.transferColor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctxt.common_fromLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        AdaptiveText(
                          related?.account.value?.name ?? '',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Transfer Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                LucideIcons.arrowRight,
                color: color.tertiary,
                size: 20,
              ),
            ),

            // TO Account
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ctxt.common_toLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        AdaptiveText(
                          data.account?.name ?? '',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.account?.accountType.icon,
                      size: 16,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CurrencyText(
              currencyCode: data.currencyCode,
              amount: data.displayAmount,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
          ],
        ),
        Text(
          DateFormat('MMM dd, yyyy', ctxt.localeName).format(data.date),
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }
}
