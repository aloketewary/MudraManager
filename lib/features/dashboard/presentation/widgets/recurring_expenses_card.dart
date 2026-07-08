import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

class RecurringExpensesCard extends ConsumerWidget {
  const RecurringExpensesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final expenses = ref.watch(dashboardRecurringExpensesProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (expenses.isEmpty) return const SizedBox.shrink();

    final monthlyTotal = expenses
        .where((e) => e.frequency == Frequency.monthly)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.recurringTransactions);
          },
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.errorContainer,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(LucideIcons.repeat, color: color.error, size: 28),
                ),
                SizedBox(width: spacing.sectionGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.title_billControlCenter,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        '${formatCurrency(monthlyTotal, decimals: 0)}/${AppLocalizations.of(context)!.label_monthly.toLowerCase()} • ${expenses.length} ${AppLocalizations.of(context)!.title_bills.toLowerCase()}',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: color.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
