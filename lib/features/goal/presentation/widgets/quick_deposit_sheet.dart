import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/milestone_share_sheet.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';

/// Shows a bottom sheet for quick goal deposit.
void showQuickDepositSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Goal goal,
  required Color goalColor,
  VoidCallback? onCompleted,
}) {
  final spacing = ref.read(spacingProvider);
  final ctxt = AppLocalizations.of(context)!;
  final textTheme = Theme.of(context).textTheme;
  final amountController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing.sectionGap,
        left: spacing.sectionGap,
        right: spacing.sectionGap,
        top: spacing.sectionGap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctxt.goal_quickDeposit,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing.sectionGap),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: ctxt.common_amount,
              prefixIcon: Icon(ref.read(baseCurrencyIconProvider)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          FilledButton.icon(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount != null && amount > 0) {
                HapticFeedback.mediumImpact();
                final wasComplete = goal.progressPercent >= 1.0;
                goal.currentAmount += amount;
                goal.contributions = [
                  ...goal.contributions,
                  GoalContribution.create(amount),
                ];
                final isNowComplete = goal.progressPercent >= 1.0;
                await ref.read(goalServiceProvider).updateGoal(goal);
                ref.invalidate(goalsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  SnackbarService.success(
                    Tone.current.goalContributionThisMonth(
                      formatCurrency(
                        amount,
                        code: goal.currencyCode,
                        decimals: 0,
                      ),
                    ),
                    spacing
                  );
                  if (!wasComplete && isNowComplete) {
                    onCompleted?.call();
                    SnackbarService.success(
                      Tone.current.goalMilestone100(goal.name.safe()),
                      spacing
                    );
                    if (context.mounted) {
                      final l10n = AppLocalizations.of(context)!;
                      Future.delayed(
                        const Duration(milliseconds: 1500),
                        () {
                          if (!context.mounted) return;
                          showMilestoneShareSheet(
                            context,
                            MilestoneData(
                              emoji: '🎯',
                              title: l10n.milestone_goalReachedTitle,
                              stat: goal.name.safe(),
                              description: l10n.milestone_goalReachedDesc(
                                formatCurrency(
                                  goal.targetAmount,
                                  code: goal.currencyCode,
                                  decimals: 0,
                                ),
                              ),
                              icon: LucideIcons.goal,
                              accent: const Color(0xFF4CAF50),
                            ),
                          );
                        },
                      );
                    }
                  }
                }
              }
            },
            icon: const Icon(LucideIcons.plus, size: 20),
            style: FilledButton.styleFrom(
              backgroundColor: goalColor,
              minimumSize: const Size(double.infinity, 56),
            ),
            label: Text(ctxt.goal_addToGoal),
          ),
        ],
      ),
    ),
  );
}
