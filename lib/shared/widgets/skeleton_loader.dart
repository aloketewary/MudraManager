import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Base skeleton loader widget with shimmer animation.
///
/// Features:
/// - Reusable shimmer effect
/// - Accessibility with reduced motion support
/// - Theming via AppSpacing
class SkeletonLoader extends ConsumerWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.margin,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(spacing.radiusSmall);

    final content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: effectiveBorderRadius,
      ),
      child: child,
    );

    if (isReducedMotion) {
      return content;
    }

    return content
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

/// Wraps any widget with skeleton shimmer effect.
class SkeletonWrapper extends ConsumerWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonWrapper({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(spacing.radiusSmall);

    final wrapper = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: effectiveBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: child,
      ),
    );

    if (isReducedMotion) {
      return wrapper;
    }

    return wrapper
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── TRANSACTION CARD SKELETON ─────────────────────────────────────────────

/// Skeleton loader for transaction card.
class TransactionCardSkeleton extends ConsumerWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final cardContent = Card(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGap,
      ),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            SkeletonLoader(
              width: spacing.iconXL * 1.5,
              height: spacing.iconXL * 1.5,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            SizedBox(width: spacing.elementGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: spacing.iconSM,
                    margin: EdgeInsets.only(bottom: spacing.elementGap),
                  ),
                  SkeletonLoader(
                    width: spacing.sectionGap,
                    height: spacing.iconXS,
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.elementGap * 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonLoader(
                  width: spacing.sectionGap,
                  height: spacing.iconMD,
                  margin: EdgeInsets.only(bottom: spacing.elementGapMin),
                ),
                SkeletonLoader(
                  width: spacing.cardHorizontalMax,
                  height: spacing.iconXS,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isReducedMotion) return cardContent;

    return cardContent
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── ACCOUNT CARD SKELETON ─────────────────────────────────────────────────

/// Skeleton loader for dashboard account card.
class AccountCardSkeleton extends ConsumerWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final cardContent = Container(
      height: spacing.radiusLarge * 15.6,
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGap,
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonLoader(width: spacing.sectionGap, height: spacing.iconLG),
          SkeletonLoader(
            width: spacing.sectionGap * 1.25,
            height: spacing.iconXL + 4,
          ),
          SkeletonLoader(width: spacing.sectionGap * 1.1, height: spacing.iconSM),
        ],
      ),
    );

    if (isReducedMotion) return cardContent;

    return cardContent
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── BUDGET CARD SKELETON ──────────────────────────────────────────────────

/// Skeleton loader for budget card.
class BudgetCardSkeleton extends ConsumerWidget {
  const BudgetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final cardContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGap,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: spacing.iconXL * 1.5,
              height: spacing.iconXL * 1.5,
              borderRadius: BorderRadius.circular(spacing.iconXL * 1.5 / 2),
            ),
            SizedBox(width: spacing.elementGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: spacing.sectionGap,
                    height: spacing.iconSM,
                    margin: EdgeInsets.only(bottom: spacing.elementGap + 4),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: spacing.strokeThick,
                    margin: EdgeInsets.only(bottom: spacing.elementGap),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonLoader(
                          width: spacing.cardHorizontalMax,
                          height: spacing.iconXS,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: SkeletonLoader(
                          width: spacing.cardHorizontalMax,
                          height: spacing.iconXS,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isReducedMotion) return cardContent;

    return cardContent
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── DASHBOARD CARD SKELETON ───────────────────────────────────────────────

/// Skeleton loader for goal/net worth cards.
class DashboardCardSkeleton extends ConsumerWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final cardContent = Padding(
      padding: EdgeInsets.only(top: spacing.cardVertical),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: spacing.elementGap),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: spacing.iconXL * 1.5,
              height: spacing.iconXL * 1.5,
              borderRadius: BorderRadius.circular(spacing.iconXL * 1.5 / 2),
            ),
            SizedBox(width: spacing.elementGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: spacing.cardHorizontalMax * 1.75,
                    height: spacing.iconSM,
                    margin: EdgeInsets.only(bottom: spacing.elementGap + 4),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: spacing.strokeThick,
                    margin: EdgeInsets.only(bottom: spacing.elementGap),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonLoader(
                          width: spacing.cardHorizontal,
                          height: spacing.iconXS,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: SkeletonLoader(
                          width: spacing.cardHorizontal,
                          height: spacing.iconXS,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isReducedMotion) return cardContent;

    return cardContent
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── PERSONALITY CARD SKELETON ─────────────────────────────────────────────

/// Skeleton loader for spending personality card.
class PersonalityCardSkeleton extends ConsumerWidget {
  const PersonalityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final cardContent = Padding(
      padding: EdgeInsets.only(top: spacing.cardVertical),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: spacing.elementGap),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: spacing.iconXL * 1.6,
              height: spacing.iconXL * 1.6,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            SizedBox(width: spacing.elementGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: spacing.sectionGap + 20,
                    height: spacing.iconSM,
                    margin: EdgeInsets.only(bottom: spacing.elementGap),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: spacing.iconXS,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isReducedMotion) return cardContent;

    return cardContent
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}

// ── LIST TILE SKELETON ─────────────────────────────────────────────────────

/// Skeleton loader for list tile items.
class ListTileSkeleton extends ConsumerWidget {
  final bool withLeading;
  final bool withTrailing;

  const ListTileSkeleton({
    super.key,
    this.withLeading = true,
    this.withTrailing = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGap,
      ),
      child: Row(
        children: [
          if (withLeading) ...[
            SkeletonLoader(
              width: spacing.iconXL,
              height: spacing.iconXL,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            SizedBox(width: spacing.elementGap * 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: spacing.iconSM,
                  margin: EdgeInsets.only(bottom: spacing.elementGapMin),
                ),
                SkeletonLoader(
                  width: spacing.cardHorizontalMax,
                  height: spacing.iconXS,
                ),
              ],
            ),
          ),
          if (withTrailing) ...[
            SizedBox(width: spacing.elementGap * 2),
            SkeletonLoader(
              width: spacing.sectionGap,
              height: spacing.iconSM,
            ),
          ],
        ],
      ),
    );

    if (isReducedMotion) return content;

    return content
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: spacing.animSlow,
          color: colorScheme.surface.withValues(alpha: 0.4),
        );
  }
}