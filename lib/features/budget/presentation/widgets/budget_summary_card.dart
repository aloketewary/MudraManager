import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class BudgetSummaryCard extends ConsumerWidget {
  final BudgetWithProgress data;

  const BudgetSummaryCard(this.data, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final b = data.budget;
    final spent = data.spent;
    final total = b.amount;
    final isGuestMode = ref.watch(guestModeProvider);
    final displaySpent = GuestModeUtil.applyGuestMode(spent, isGuestMode);
    final displayTotal = GuestModeUtil.applyGuestMode(total, isGuestMode);
    final pct = displayTotal > 0 ? (displaySpent / displayTotal) : 0;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('dd MMM yy', ctxt.localeName);

    final statusColor = pct >= 1.0
        ? color.error
        : pct >= 0.8
        ? Colors.orange
        : color.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.budgetDetails, extra: data);
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        elevation: 0,
        color: color.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pct >= 1.0 ? Icons.warning_rounded : Icons.pie_chart_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(data.startDate)} - ${formatter.format(data.endDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spent',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              CurrencyText(
                                amount: displaySpent,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ctxt.formatPercentNumber(pct),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
