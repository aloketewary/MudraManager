import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


/// Skeleton loading component for displaying placeholder content
/// while data is being loaded
class SkeletonLoader extends ConsumerWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(spacing.radiusSmall),
      ),
    )
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: color.surface.withValues(alpha: 0.5),
        );
  }
}

/// Skeleton loader for transaction card
class TransactionCardSkeleton extends ConsumerWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            const SizedBox(width: 16.0),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 8.0),
                  ),
                  SkeletonLoader(width: 120, height: 14),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 20,
                  margin: EdgeInsets.only(bottom: 4.0),
                ),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: color.surface.withValues(alpha: 0.5),
        );
  }
}

/// Skeleton loader for dashboard account card
class AccountCardSkeleton extends ConsumerWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
          height: 250,
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 150, height: 24),
              SkeletonLoader(width: 200, height: 40),
              SkeletonLoader(width: 180, height: 16),
            ],
          ),
        )
        .animate(onComplete: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: color.surface.withValues(alpha: 0.5),
        );
  }
}

/// Skeleton loader for budget card
class BudgetCardSkeleton extends ConsumerWidget {
  const BudgetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(width: 16.0),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 120,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 12.0),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 10,
                    margin: EdgeInsets.only(bottom: 8.0),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonLoader(width: 80, height: 14),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SkeletonLoader(width: 80, height: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onComplete: (controller) => controller.repeat())
          .shimmer(
            duration: 1500.ms,
            color: color.surface.withValues(alpha: 0.5),
          ),
    );
  }
}

/// Skeleton loader for goal/net worth cards
class DashboardCardSkeleton extends ConsumerWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 100,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 12),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 10,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonLoader(width: 70, height: 14),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SkeletonLoader(width: 70, height: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onComplete: (controller) => controller.repeat())
          .shimmer(
            duration: 1500.ms,
            color: color.surface.withValues(alpha: 0.5),
          ),
    );
  }
}

/// Skeleton loader for spending personality card
class PersonalityCardSkeleton extends ConsumerWidget {
  const PersonalityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 140,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onComplete: (controller) => controller.repeat())
          .shimmer(
            duration: 1500.ms,
            color: color.surface.withValues(alpha: 0.5),
          ),
    );
  }
}
