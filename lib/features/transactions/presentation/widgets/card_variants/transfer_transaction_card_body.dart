import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_row.dart';

/// Transfer transaction card body showing from/to accounts and amount.
class TransferTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TransferTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final related = data.related;
    final brightness = Theme.of(context).brightness;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final transferColor = FinanceColors.transferColor(brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TransactionCardIconTile(
          color: transferColor,
          icon: LucideIcons.arrowLeftRight,
          spacing: spacing,
          colorScheme: colorScheme,
        ),
        SizedBox(width: spacing.elementGap + spacing.elementGapMin),
        Expanded(
          child: TransactionCardInfoColumn(
            title: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: related?.account.value?.name ?? '',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  TextSpan(
                    text: ' → ',
                    style: TextStyle(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: data.account?.name ?? '',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            metadata: Text(
              '${(related?.account.value?.accountType ?? AccountType.other).label} → ${(data.account?.accountType ?? AccountType.other).label}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          amountColor: colorScheme.primary,
          datePattern: 'hh:mm a',
        ),
      ],
    );
  }
}
