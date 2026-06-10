import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';

class FirstTransactionNudge extends ConsumerWidget {
  final bool isNewUser;
  final VoidCallback onDismiss;

  const FirstTransactionNudge({
    super.key,
    required this.isNewUser,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QuickAddTransactionSheet(),
              );
            },
            child: Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    accent.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(LucideIcons.plus, color: accent, size: 22),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctxt.dashboard_addFirstExpense,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapUltraMin),
                        Text(
                          ctxt.dashboard_addFirstExpenseDesc,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: color.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.elementGap),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: color.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isNewUser) ...[
            SizedBox(height: spacing.elementGap),
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                color: color.surfaceContainerLow,
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.dashboard_meanwhile,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: LucideIcons.plus,
                        label: ctxt.dashboard_addExpense,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const QuickAddTransactionSheet(),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.target,
                        label: ctxt.dashboard_setBudget,
                        onTap: () => context.push(AppRoutes.addBudget),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: LucideIcons.piggyBank,
                        label: ctxt.dashboard_createGoal,
                        onTap: () => context.push(AppRoutes.addGoal),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.landmark,
                        label: ctxt.dashboard_addAccount,
                        onTap: () => context.push(AppRoutes.addAccount),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Text(
                    ctxt.dashboard_testTip,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.625),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(Tone.current.borderRadius * 0.625),
            color: color.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
