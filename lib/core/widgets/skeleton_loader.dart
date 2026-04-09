import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Base skeleton bone — no shimmer on individual bones
class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const _Bone({this.width, this.height = 14, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.onSurface.withValues(alpha: 0.06),
        borderRadius: borderRadius ?? BorderRadius.circular(6),
      ),
    );
  }
}

/// Wraps children with a single shimmer pass
class _ShimmerWrap extends StatelessWidget {
  final Widget child;
  const _ShimmerWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return child.animate(onComplete: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: color.onSurface.withValues(alpha: 0.04),
        );
  }
}

/// Generic skeleton loader (for use outside dashboard)
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
        color: color.onSurface.withValues(alpha: 0.06),
        borderRadius: borderRadius ?? BorderRadius.circular(6),
      ),
    ).animate(onComplete: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: color.onSurface.withValues(alpha: 0.04),
        );
  }
}

/// Matches AccountsWidgetPlugin — horizontal scroll of account chips
class AccountCardSkeleton extends ConsumerWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            const _Bone(width: 100, height: 12),
            SizedBox(height: spacing.elementGap),
            // Horizontal account chips
            SizedBox(
              height: 80,
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i < 2 ? spacing.elementGap : 0,
                      ),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: EdgeInsets.all(spacing.elementGap + 4),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Bone(width: 60, height: 10),
                          _Bone(width: 80, height: 18),
                          _Bone(width: 50, height: 10),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches QuickActionsWidgetPlugin — row of action buttons
class QuickActionsSkeleton extends ConsumerWidget {
  const QuickActionsSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < 3 ? spacing.elementGap : 0,
                ),
                child: Column(
                  children: [
                    _Bone(
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 6),
                    const _Bone(width: 40, height: 10),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Matches CashFlowWidgetPlugin — chart area with labels
class CashFlowSkeleton extends ConsumerWidget {
  const CashFlowSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Bone(width: 100, height: 14),
                  _Bone(width: 70, height: 12),
                ],
              ),
              SizedBox(height: spacing.sectionGap),
              // Income / Expense row
              Row(
                children: [
                  const Expanded(child: _Bone(height: 36)),
                  SizedBox(width: spacing.elementGap),
                  const Expanded(child: _Bone(height: 36)),
                ],
              ),
              SizedBox(height: spacing.sectionGap),
              // Chart placeholder
              _Bone(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches BudgetOverviewWidgetPlugin — progress bar with label
class BudgetCardSkeleton extends ConsumerWidget {
  const BudgetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Bone(width: 80, height: 14),
                  _Bone(width: 60, height: 12),
                ],
              ),
              SizedBox(height: spacing.elementGap + 4),
              // Progress bar
              _Bone(
                width: double.infinity,
                height: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: spacing.elementGap),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Bone(width: 70, height: 12),
                  _Bone(width: 70, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic card skeleton for remaining widgets (goals, recurring, recent)
class DashboardCardSkeleton extends ConsumerWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _Bone(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              SizedBox(width: spacing.elementGap + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Bone(width: 120, height: 14),
                    SizedBox(height: spacing.elementGap),
                    const _Bone(width: double.infinity, height: 10),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              const _Bone(width: 50, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transaction card skeleton
class TransactionCardSkeleton extends ConsumerWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        elevation: 0,
        color: color.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              _Bone(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(14),
              ),
              SizedBox(width: spacing.cardInner),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Bone(width: double.infinity, height: 14),
                    SizedBox(height: spacing.elementGap),
                    const _Bone(width: 120, height: 10),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _Bone(width: 70, height: 16),
                  SizedBox(height: spacing.elementGap),
                  const _Bone(width: 50, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spending personality skeleton
class PersonalityCardSkeleton extends ConsumerWidget {
  const PersonalityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return _ShimmerWrap(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _Bone(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              SizedBox(width: spacing.cardInner),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Bone(width: 130, height: 14),
                    SizedBox(height: spacing.elementGap),
                    const _Bone(width: double.infinity, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
