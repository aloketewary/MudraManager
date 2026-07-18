import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class QuickActionButton extends ConsumerWidget {
  final bool isWide;

  const QuickActionButton({super.key, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    final actions = [
      _ActionData(
        label: ctxt.transaction_addExpenseTitle,
        icon: LucideIcons.trendingDown,
        color: color.error,
        onTap: () => context.push(
          AppRoutes.addTransaction,
          extra: {'isIncome': false},
        ),
      ),
      _ActionData(
        label: ctxt.transaction_addIncomeTitle,
        icon: LucideIcons.trendingUp,
        color: color.primary,
        onTap: () => context.push(
          AppRoutes.addTransaction,
          extra: {'isIncome': true},
        ),
      ),
      _ActionData(
        label: ctxt.dashboard_add_transfer_text,
        icon: LucideIcons.arrowLeftRight,
        color: color.tertiary,
        onTap: () => context.push(AppRoutes.transfer),
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 350;
          final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;

          if (isLargeText || isNarrow || !isWide) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) SizedBox(height: spacing.elementGap),
                  _DashboardActionButton(
                    data: actions[i],
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    isRow: true,
                    spacing: spacing,
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: spacing.elementGapMin),
                Expanded(
                  child: _DashboardActionButton(
                    data: actions[i],
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(i == 0 ? spacing.radiusMedium : 0),
                      right: Radius.circular(
                        i == actions.length - 1 ? spacing.radiusMedium : 0,
                      ),
                    ),
                    spacing: spacing,
                    isTight: !isWide,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashboardActionButton extends StatelessWidget {
  final _ActionData data;
  final BorderRadius borderRadius;
  final bool isRow;
  final bool isTight;
  final AppSpacing spacing;

  const _DashboardActionButton({
    required this.data,
    required this.borderRadius,
    this.isRow = false,
    this.isTight = false,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: data.color.withValues(alpha: 0.1),
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          data.onTap();
        },
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isRow ? spacing.elementGap + 4 : spacing.elementGap + 8,
            horizontal: isTight ? spacing.cardHorizontal : spacing.cardInner,
          ),
          child: isRow
              ? Row(
                  children: [
                    Icon(data.icon, color: data.color, size: 22),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      data.label,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, color: data.color, size: 24),
                    SizedBox(height: spacing.elementGapMin),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
