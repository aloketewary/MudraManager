import 'package:mudra_manager/core/currency/currency_meta.dart';
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
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(startDate, endDate),
          Consumer(
            // Only this rebuilds
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
                    child: _buildIncomeExpenseSection(
                      false,
                      income,
                      prevIncome,
                    ),
                  ),
                  Container(width: 1, height: 170, color: color.outlineVariant),
                  Expanded(
                    child: _buildIncomeExpenseSection(
                      true,
                      expense,
                      prevExpense,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    DateTime startDate,
    DateTime endDate,
  ) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Row(
        children: [
          Icon(
            LucideIcons.wallet,
            color: color.primary,
            size: 20,
          ),
          SizedBox(width: spacing.cardVertical),
          AdaptiveText(
            ctxt.dashboard_cash_flow_text,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.primary,
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          AdaptiveText(
            '(${DateFormat(
              'dd',
              ctxt.localeName,
            ).format(startDate)} - ${DateFormat(
              'dd MMM yy',
              ctxt.localeName,
            ).format(endDate)})',
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.transactions);
            },
            child: Icon(
              LucideIcons.chevronRight,
              color: color.onSurface,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseSection(
    bool isExpense,
    double amount,
    double previousValue,
  ) {
    final spacing = ref.read(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final labelText = isExpense ? 'Expense' : 'Income';
    final accent = isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return SizedBox(
      height: 170,
      child: Semantics(
        label: '$labelText: ${formatCurrency(amount, decimals: 0)}',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
          },
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: accent.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: isExpense ? Radius.zero : Radius.circular(spacing.radiusMedium),
                right: isExpense ? Radius.circular(spacing.radiusMedium) : Radius.zero,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: accent.withValues(alpha: 0.15),
                        child: Icon(
                          isExpense
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 16,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      AdaptiveText(
                        (isExpense
                                ? ctxt.transaction_type_expense
                                : ctxt.transaction_type_income)
                            .toUpperCase(),
                        textAlign: TextAlign.left,
                        style: textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const Spacer(),
                    ],
                  ),
                  Flexible(
                    child: Container(
                      height: 80,
                      alignment: Alignment.centerLeft,
                      child: AnimatedBalance(
                        value: amount,
                        style: textTheme.headlineLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                        fixedStringLength: 0,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                  if (previousValue > 0) ...[
                    TrendIndicator(
                      current: amount,
                      previous: previousValue,
                      isIncome: !isExpense,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}
