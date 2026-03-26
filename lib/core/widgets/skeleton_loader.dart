import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mudra_manager/core/theme/design_tokens.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark
            ? color.surfaceContainerHighest
            : color.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: borderRadius ?? DesignTokens.borderRadiusSmall,
      ),
    ).animate(onComplete: (controller) => controller.repeat()).shimmer(
          duration: 1500.ms,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
        );
  }
}

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
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Row(
          children: [
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: DesignTokens.spacing16),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 20,
                  margin: EdgeInsets.only(bottom: DesignTokens.spacing4),
                ),
                SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    );
  }
}

class BudgetCardSkeleton extends StatelessWidget {
  const BudgetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing8,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: DesignTokens.borderRadiusLarge,
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 120,
                    height: 16,
                    margin: EdgeInsets.only(bottom: DesignTokens.spacing12),
                  ),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 10,
                    margin: EdgeInsets.only(bottom: DesignTokens.spacing8),
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
      ),
    );
  }
}

class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }
}

class PersonalityCardSkeleton extends StatelessWidget {
  const PersonalityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
