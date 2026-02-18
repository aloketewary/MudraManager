import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mudra_manager/core/theme/design_tokens.dart';

/// Skeleton loading component for displaying placeholder content
/// while data is being loaded
class SkeletonLoader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: borderRadius ?? DesignTokens.borderRadiusSmall,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: color.surface.withValues(alpha: 0.5),
        );
  }
}

/// Skeleton loader for transaction card
class TransactionCardSkeleton extends StatelessWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Row(
          children: [
            // Icon placeholder
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: DesignTokens.borderRadiusMedium,
            ),
            const SizedBox(width: DesignTokens.spacing16),
            // Text content placeholders
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 16,
                    margin: EdgeInsets.only(bottom: DesignTokens.spacing8),
                  ),
                  SkeletonLoader(width: 120, height: 14),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            // Amount placeholder
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 20,
                  margin: EdgeInsets.only(bottom: DesignTokens.spacing8),
                ),
                SkeletonLoader(width: 100, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for dashboard account card
class AccountCardSkeleton extends StatelessWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
          height: 250,
          margin: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
            vertical: DesignTokens.spacing8,
          ),
          padding: const EdgeInsets.all(DesignTokens.spacing24),
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: DesignTokens.borderRadiusLarge,
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
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: color.surface.withValues(alpha: 0.5),
        );
  }
}

/// Skeleton loader for budget card
class BudgetCardSkeleton extends StatelessWidget {
  const BudgetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing8,
      ),
      child: Container(
        height: 210,
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusMedium,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SkeletonLoader(width: 120, height: 16),
                  SkeletonLoader(width: 100, height: 24),
                  SkeletonLoader(width: 140, height: 14),
                  SkeletonLoader(width: 90, height: 24),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            SkeletonLoader(
              width: 90,
              height: 90,
              borderRadius: BorderRadius.circular(45),
            ),
          ],
        ),
      ),
    );
  }
}
