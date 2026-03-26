import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/responseive_layout_builder.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class QuickActionButton extends ConsumerWidget {
  const QuickActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
      child: ResponsiveLayoutBuilder(
        columnWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _DashboardActionButton(
                label: 'Add Expense',
                icon: LucideIcons.trendingDown,
                onTap: () => context
                    .push(AppRoutes.addTransaction, extra: {'isIncome': false}),
                color: color.error,
                isLeft: true,
                isRight: true,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _DashboardActionButton(
                label: 'Add Income',
                icon: LucideIcons.trendingUp,
                onTap: () => context
                    .push(AppRoutes.addTransaction, extra: {'isIncome': true}),
                color: color.primary,
                isLeft: false,
                isRight: false,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _DashboardActionButton(
                label: ctxt.dashboard_add_transfer_text,
                icon: LucideIcons.arrowLeftRight,
                onTap: () => context.push(AppRoutes.transfer),
                color: color.tertiary,
                isRight: true,
                isLeft: true,
              ),
            ),
          ],
        ),
        rowWidget: Row(
          children: [
            Expanded(
              child: _DashboardActionButton(
                label: 'Add Expense',
                icon: LucideIcons.trendingDown,
                onTap: () => context
                    .push(AppRoutes.addTransaction, extra: {'isIncome': false}),
                color: color.error,
                isLeft: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _DashboardActionButton(
                label: 'Add Income',
                icon: LucideIcons.trendingUp,
                onTap: () => context
                    .push(AppRoutes.addTransaction, extra: {'isIncome': true}),
                color: color.primary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _DashboardActionButton(
                label: ctxt.dashboard_add_transfer_text,
                icon: LucideIcons.arrowLeftRight,
                onTap: () => context.push(AppRoutes.transfer),
                color: color.tertiary,
                isRight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isRight;
  final bool isLeft;

  const _DashboardActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isRight = false,
    this.isLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: _getBorderRadius(isLeft, isRight),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: _getBorderRadius(isLeft, isRight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius? _getBorderRadius(bool isLeft, bool isRight) {
    if (isLeft && isRight) {
      return BorderRadius.circular(16);
    } else if (isLeft) {
      return const BorderRadius.horizontal(left: Radius.circular(16));
    } else if (isRight) {
      return const BorderRadius.horizontal(right: Radius.circular(16));
    }
    return null;
  }
}
