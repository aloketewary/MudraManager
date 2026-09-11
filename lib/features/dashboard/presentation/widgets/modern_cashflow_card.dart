import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class ModernCashFlowCard extends ConsumerWidget {
  const ModernCashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardInner * 0.8,
          vertical: spacing.cardInner * 0.65,
        ),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusLarge),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Money',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: spacing.elementGapMin),
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: color.onSurfaceVariant,
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.transactions);
                  },
                  borderRadius: BorderRadius.circular(spacing.radiusLarge),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.elementGap,
                      vertical: spacing.elementGapMin,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.55),
                      ),
                      borderRadius: BorderRadius.circular(spacing.radiusLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: textTheme.labelMedium?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Consumer(
              builder: (context, ref, child) {
                final rawIncome = ref.watch(dashboardIncomeProvider);
                final rawExpense = ref.watch(dashboardExpenseProvider);
                final income =
                    GuestModeUtil.applyGuestMode(rawIncome, isGuestMode);
                final expense =
                    GuestModeUtil.applyGuestMode(rawExpense, isGuestMode);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        isExpense: false,
                        amount: income,
                        context: context,
                        spacing: spacing,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildMetricTile(
                        isExpense: true,
                        amount: expense,
                        context: context,
                        spacing: spacing,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isExpense,
    required double amount,
    required BuildContext context,
    required AppSpacing spacing,
  }) {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final accent = isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    return Semantics(
      button: true,
      label: isExpense
          ? ctxt.transaction_type_expense
          : ctxt.transaction_type_income,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.transactions);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 148),
          padding: EdgeInsets.all(spacing.cardInner * 0.7),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  isExpense
                      ? LucideIcons.walletCards
                      : LucideIcons.walletMinimal,
                  size: 18,
                  color: accent,
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isExpense
                          ? ctxt.transaction_type_expense
                          : ctxt.transaction_type_income,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGapMin),
              AnimatedBalance(
                value: amount,
                style: textTheme.titleLarge?.copyWith(
                  color: color.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                fixedStringLength: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
