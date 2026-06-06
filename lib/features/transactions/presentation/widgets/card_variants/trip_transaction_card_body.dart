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

class TripTransactionCardBody extends ConsumerWidget {
  final TransactionCardData data;

  const TripTransactionCardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final categoryColor = Color(data.category?.colorValue ?? 0xFF000000);
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
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
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.surfaceContainerLow,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  LucideIcons.planeTakeoff,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.planeTakeoff,
                          size: 10,
                          color: color.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          data.tripName!,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AdaptiveText(
                      data.account?.name ?? '',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
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
                    ? FinanceColors.expenseColor(brightness)
                    : FinanceColors.incomeColor(brightness),
              ),
              maxLines: 1,
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
