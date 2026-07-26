import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Income breakdown card showing income categories with percentages.
class IncomeBreakdownCard extends ConsumerWidget {
  final String title;
  final Map<String, double> categories;
  final IconData icon;
  final Color iconColor;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const IncomeBreakdownCard({
    super.key,
    required this.title,
    required this.categories,
    required this.icon,
    required this.iconColor,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final isGuestMode = ref.watch(guestModeProvider);

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5);
    final total = categories.values.fold<double>(0, (s, v) => s + v);

    return Semantics(
      label: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...top.map((e) {
              final pct = total > 0 ? (e.value / total * 100) : 0.0;
              return IncomeCategoryRow(
                label: e.key,
                percentage: pct,
                amount: e.value,
                isGuestMode: isGuestMode,
                spacing: spacing,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class IncomeCategoryRow extends StatelessWidget {
  final String label;
  final double percentage;
  final double amount;
  final bool isGuestMode;
  final AppSpacing spacing;

  const IncomeCategoryRow({
    super.key,
    required this.label,
    required this.percentage,
    required this.amount,
    required this.isGuestMode,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textTheme.bodyMedium),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(amount, isGuestMode),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}