import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/transaction_card_data.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Shared compact row primitives used by every transaction-card variant.
///
/// Keeping these pieces shared makes normal, recurring, trip, and transfer
/// rows feel like one list while allowing each variant to retain its badge or
/// account-specific metadata.
class TransactionCardIconTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final Widget? badge;

  const TransactionCardIconTile({
    super.key,
    required this.color,
    required this.icon,
    required this.spacing,
    required this.colorScheme,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = spacing.iconXL * 1.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
          ),
          child: Icon(icon, color: color, size: spacing.iconMD + 2),
        ),
        if (badge != null) badge!,
      ],
    );
  }
}

class TransactionCardInfoColumn extends StatelessWidget {
  final Widget title;
  final Widget metadata;
  final bool hasDetails;
  final bool expanded;
  final bool isReducedMotion;
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const TransactionCardInfoColumn({
    super.key,
    required this.title,
    required this.metadata,
    required this.hasDetails,
    required this.expanded,
    required this.isReducedMotion,
    required this.spacing,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        SizedBox(height: spacing.elementGapMin),
        metadata,
        if (hasDetails)
          Padding(
            padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: isReducedMotion ? Duration.zero : spacing.animFast,
              child: Icon(
                LucideIcons.chevronDown,
                size: spacing.iconSM - 2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
      ],
    );
  }
}

class TransactionCardTitle extends StatelessWidget {
  final TransactionCardData data;
  final TextTheme textTheme;

  const TransactionCardTitle({
    super.key,
    required this.data,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final description = data.description?.trim();
    final label = description?.isNotEmpty == true
        ? description!
        : data.category?.name ?? 'Uncategorized';

    return AdaptiveText(
      label,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      maxLines: 1,
    );
  }
}

class TransactionCardMetadata extends StatelessWidget {
  final TransactionCardData data;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const TransactionCardMetadata({
    super.key,
    required this.data,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (data.account?.name != null) {
      parts.add(data.account!.name);
    } else if (data.account != null) {
      parts.add(data.account!.accountType.name);
    }

    return AdaptiveText(
      parts.isEmpty ? 'No account' : parts.join(' • '),
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
    );
  }
}

class TransactionCardAmountColumn extends StatelessWidget {
  final TransactionCardData data;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final AppSpacing spacing;
  final Color amountColor;
  final String datePattern;
  final bool showConvertedAmount;

  const TransactionCardAmountColumn({
    super.key,
    required this.data,
    required this.textTheme,
    required this.colorScheme,
    required this.spacing,
    required this.amountColor,
    required this.datePattern,
    this.showConvertedAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyText(
          currencyCode: data.currencyCode,
          amount: data.displayAmount,
          showSign: !data.isTransfer,
          isExpense: data.isExpense,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: amountColor,
          ),
          maxLines: 1,
        ),
        if (showConvertedAmount &&
            data.currencyCode != null &&
            data.convertedAmount != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
            child: CurrencyText(
              amount: data.convertedAmount!,
              compact: true,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              prefixText: '≈',
            ),
          ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          DateFormat(datePattern, ctxt.localeName).format(data.date),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
