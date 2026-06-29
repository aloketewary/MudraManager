import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/filter_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class ModernCashFlowCard extends ConsumerStatefulWidget {
  const ModernCashFlowCard({super.key});

  @override
  ConsumerState<ModernCashFlowCard> createState() => _ModernCashFlowCardState();
}

class _ModernCashFlowCardState extends ConsumerState<ModernCashFlowCard> {
  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.transactions);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Text(
                    ctxt.dashboard_cash_flow_text,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: spacing.elementGapMin),
                  Text(
                    '${DateFormat('dd', ctxt.localeName).format(startDate)} - ${DateFormat('dd MMM', ctxt.localeName).format(endDate)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),

              SizedBox(height: spacing.sectionGap),

              // ── Income / Expense row ──
              Consumer(
                builder: (context, ref, child) {
                  final rawIncome = ref.watch(dashboardIncomeProvider);
                  final rawExpense = ref.watch(dashboardExpenseProvider);
                  final income =
                      GuestModeUtil.applyGuestMode(rawIncome, isGuestMode);
                  final expense =
                      GuestModeUtil.applyGuestMode(rawExpense, isGuestMode);
                  final prevSummary = ref.watch(
                    previousPeriodTransactionsProvider('month'),
                  );
                  final rawPrevIncome = prevSummary.value?['income'] ?? 0.0;
                  final rawPrevExpense = prevSummary.value?['expense'] ?? 0.0;
                  final prevIncome =
                      GuestModeUtil.applyGuestMode(rawPrevIncome, isGuestMode);
                  final prevExpense =
                      GuestModeUtil.applyGuestMode(rawPrevExpense, isGuestMode);

                  return Row(
                    children: [
                      Expanded(
                        child: _buildSection(
                          isExpense: false,
                          amount: income,
                          previousValue: prevIncome,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: _buildSection(
                          isExpense: true,
                          amount: expense,
                          previousValue: prevExpense,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isExpense,
    required double amount,
    required double previousValue,
  }) {
    final spacing = ref.read(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final accent = isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpense ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                size: 14,
                color: accent,
              ),
              SizedBox(width: spacing.elementGapMin),
              Text(
                (isExpense
                        ? ctxt.transaction_type_expense
                        : ctxt.transaction_type_income)
                    .toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          AnimatedBalance(
            value: amount,
            style: textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
            fixedStringLength: 0,
            overflow: TextOverflow.fade,
          ),
          if (previousValue > 0) ...[
            SizedBox(height: spacing.elementGapMin),
            TrendIndicator(
              current: amount,
              previous: previousValue,
              isIncome: !isExpense,
            ),
          ],
        ],
      ),
    );
  }
}
