import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';

class ModernCashFlowCard extends ConsumerWidget {
  const ModernCashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final rawIncome = ref.watch(dashboardIncomeProvider);
    final rawExpense = ref.watch(dashboardExpenseProvider);
    final income = GuestModeUtil.applyGuestMode(rawIncome, isGuestMode);
    final expense = GuestModeUtil.applyGuestMode(rawExpense, isGuestMode);
    final elapsedDays = DateTime.now().day;
    final dailySpendingPace = elapsedDays == 0 ? 0.0 : expense / elapsedDays;
    final brightness = Theme.of(context).brightness;
    final spendingColor = FinanceColors.expenseColor(brightness);
    final amountDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : spacing.animHero;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Semantics(
        container: true,
        label: 'Your Money summary',
        child: Container(
          padding: EdgeInsets.all(spacing.cardHorizontal),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(spacing.radiusLarge),
              topRight: Radius.circular(spacing.radiusLarge),
            ),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Money',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'About Your Money',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showMoneyInfo(context, spacing);
                    },
                    icon: Icon(
                      LucideIcons.info,
                      size: spacing.iconSM,
                      color: color.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(
                      minWidth: spacing.touchTarget,
                      minHeight: spacing.touchTarget,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.netWorth);
                    },
                    icon: const Icon(LucideIcons.arrowUpRight, size: 16),
                    label: Text(ctxt.common_viewDetails),
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, spacing.touchTarget),
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                      ),
                      foregroundColor: color.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.all(spacing.cardInner * 0.75),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: spendingColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.receipt,
                                size: spacing.iconSM,
                                color: spendingColor,
                              ),
                              SizedBox(width: spacing.elementGapMin),
                              Text(
                                ctxt.stats_dailySpendingPace,
                                style: textTheme.labelLarge?.copyWith(
                                  color: color.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          AmountGlow(
                            color: spendingColor,
                            child: AnimatedBalance(
                              value: dailySpendingPace,
                              duration: amountDuration,
                              style: textTheme.headlineMedium?.copyWith(
                                color: color.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              fixedStringLength: 0,
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            'Average expense per day this month',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: spendingColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.receiptText,
                        size: spacing.iconMD,
                        color: spendingColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.elementGap),
              _buildMetricRow(
                label: ctxt.dashboard_incomeLabel,
                amount: income,
                isExpense: false,
                context: context,
                spacing: spacing,
                amountDuration: amountDuration,
              ),
              Divider(
                height: spacing.elementGap,
                color: color.outlineVariant.withValues(alpha: 0.35),
              ),
              _buildMetricRow(
                label: ctxt.transaction_type_expense,
                amount: expense,
                isExpense: true,
                context: context,
                spacing: spacing,
                amountDuration: amountDuration,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoneyInfo(BuildContext context, AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: color.surface,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            spacing.elementGapMin,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Money summary information',
                image: true,
                child: Icon(
                  LucideIcons.walletCards,
                  size: 64,
                  color: color.primary,
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                'How Your Money works',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                'This card shows income and expenses recorded during the '
                'current month. The main figure is your average expense per '
                'day so far this month. Transfers between your own accounts '
                'are excluded, and the chart shows net movement over the '
                'last 7 days.',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(ctxt.common_ok),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow({
    required String label,
    required double amount,
    required bool isExpense,
    required BuildContext context,
    required AppSpacing spacing,
    required Duration amountDuration,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final accent = isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Semantics(
      container: true,
      label: '$label total',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.elementGapMin),
        child: Row(
          children: [
            Container(
              width: spacing.touchTargetSmall,
              height: spacing.touchTargetSmall,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(
                isExpense ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                size: spacing.iconSM,
                color: accent,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedBalance(
              value: amount,
              duration: amountDuration,
              style: textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w500,
              ),
              fixedStringLength: 0,
            ),
          ],
        ),
      ),
    );
  }
}
