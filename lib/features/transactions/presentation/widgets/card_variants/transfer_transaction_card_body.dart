import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Transfer transaction card body showing from/to accounts and amount.
///
/// Layout matches the visual pattern of other card variants:
/// - Category icon on left
/// - Account info in middle
/// - Amount on right
class TransferTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TransferTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final related = data.related;
    final brightness = Theme.of(context).brightness;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Transfer icon indicator
        Container(
          width: spacing.iconXL * 2,
          height: spacing.iconXL * 2,
          decoration: BoxDecoration(
            color: FinanceColors.transferColor(brightness).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          child: Icon(
            LucideIcons.arrowLeftRight,
            color: FinanceColors.transferColor(brightness),
            size: spacing.iconLG,
          ),
        ),
        SizedBox(width: spacing.elementGap * 1.75),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // From → To on single line
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: related?.account.value?.name ?? '',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' → ',
                      style: TextStyle(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: data.account?.name ?? '',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.elementGapUltraMin),
              // Account types
              Text(
                '${(related?.account.value?.accountType ?? AccountType.other).label} → ${(data.account?.accountType ?? AccountType.other).label}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          ),
        ),
        SizedBox(width: spacing.elementGap),
        _buildAmountColumn(
          data: data,
          spacing: spacing,
          colorScheme: colorScheme,
          textTheme: textTheme,
          ctxt: ctxt,
        ),
      ],
    );
  }

  Widget _buildAmountColumn({
    required TransactionCardData data,
    required AppSpacing spacing,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required AppLocalizations ctxt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyText(
          currencyCode: data.currencyCode,
          amount: data.displayAmount,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
          maxLines: 1,
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