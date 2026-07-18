import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Insight/banner container with optional action buttons.
/// Use for filter hints, empty states, and contextual tips.
///
/// Features:
/// - Glassmorphism container with subtle border
/// - Smooth entry animations
/// - Accessible touch targets
/// - Budget-aware variant with spending vs budget display
class InsightBanner extends ConsumerWidget {
  final String title;
  final String subtitle;
  final List<InsightAction> actions;
  final IconData? icon;

  /// Budget-specific data for spending vs budget display
  final BudgetInfo? budgetInfo;

  const InsightBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.icon,
    this.budgetInfo,
  });

  const InsightBanner.budget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.budgetInfo,
    this.actions = const [],
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      duration: isReducedMotion ? Duration.zero : spacing.animNormal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.95, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: spacing.strokeThin,
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (icon != null)
              Positioned(
                right: -spacing.elementGap,
                top: -spacing.elementGap,
                child: Icon(
                  icon,
                  size: spacing.iconXL * 1.75,
                  color: colorScheme.primary.withValues(alpha: 0.06),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                if (budgetInfo != null) ...[
                  SizedBox(height: spacing.elementGap),
                  _BudgetProgress(
                    budgetInfo: budgetInfo!,
                    spacing: spacing,
                    colorScheme: colorScheme,
                    isReducedMotion: isReducedMotion,
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  SizedBox(height: spacing.cardVertical),
                  _ActionRow(
                    actions: actions,
                    spacing: spacing,
                    colorScheme: colorScheme,
                    isReducedMotion: isReducedMotion,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Budget spending data for the banner.
class BudgetInfo {
  final double spent;
  final double budgetAmount;
  final String categoryName;

  const BudgetInfo({
    required this.spent,
    required this.budgetAmount,
    required this.categoryName,
  });

  double get percentage => budgetAmount > 0 ? (spent / budgetAmount).clamp(0.0, 1.5) : 0.0;
  bool get isOverBudget => spent > budgetAmount;
  bool get hasBudget => budgetAmount > 0;
}

/// Budget progress indicator with spending bar.
class _BudgetProgress extends StatelessWidget {
  final BudgetInfo budgetInfo;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;

  const _BudgetProgress({
    required this.budgetInfo,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budgetInfo.percentage;
    final isOverBudget = budgetInfo.isOverBudget;
    final progressColor = isOverBudget
        ? colorScheme.error
        : progress >= 0.8
            ? colorScheme.tertiary
            : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        AnimatedContainer(
          duration: isReducedMotion ? Duration.zero : spacing.animNormal,
          curve: Curves.easeOutCubic,
          height: spacing.progressThin,
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            child: AnimatedFractionallySizedBox(
              duration: isReducedMotion ? Duration.zero : spacing.animNormal,
              curve: Curves.easeOutCubic,
              widthFactor: (progress / 1.5).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).round()}% used',
              style: TextStyle(
                color: progressColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${budgetInfo.spent.toStringAsFixed(0)} / ${budgetInfo.budgetAmount.toStringAsFixed(0)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<InsightAction> actions;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;

  const _ActionRow({
    required this.actions,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.asMap().entries.map((entry) {
        final action = entry.value;
        final isLast = entry.key == actions.length - 1;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : spacing.elementGap),
          child: _InsightButton(
            action: action,
            spacing: spacing,
            colorScheme: colorScheme,
            isReducedMotion: isReducedMotion,
          ),
        );
      }).toList(),
    );
  }
}

/// Action button for InsightBanner.
class InsightAction {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const InsightAction({
    required this.label,
    required this.onTap,
    this.isPrimary = true,
  });
}

class _InsightButton extends StatelessWidget {
  final InsightAction action;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;

  const _InsightButton({
    required this.action,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.isPrimary
          ? colorScheme.primary
          : Colors.transparent,
      borderRadius: BorderRadius.circular(spacing.radiusSmall + 2),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(spacing.radiusSmall + 2),
        splashFactory: isReducedMotion ? NoSplash.splashFactory : null,
        child: AnimatedContainer(
          duration: isReducedMotion ? Duration.zero : spacing.animFast,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontalMin + 6,
            vertical: spacing.elementGapMin + 2,
          ),
          decoration: action.isPrimary
              ? null
              : BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: spacing.strokeThin,
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall + 2),
                ),
          child: Text(
            action.label,
            style: TextStyle(
              color: action.isPrimary
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}