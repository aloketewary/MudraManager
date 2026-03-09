import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'dart:math' as math;

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Buckets'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-goal');
            },
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const NoDataFound(
              message: 'No goals yet',
              iconData: Icons.emoji_flags_outlined,
            );
          }

          final activeGoals = goals.where((g) => g.isActive).toList();
          final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
          final totalSaved = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
          final overallProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

          return CustomScrollView(
            slivers: [
              // Hero Dual-Ring Gauge
              SliverToBoxAdapter(
                child: _buildHeroGauge(totalSaved, totalTarget, overallProgress, color, textTheme),
              ),

              // AI Boost Cards
              if (activeGoals.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildBoostCard(activeGoals.first, color, textTheme, context),
                ),

              // Goals List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildGoalCard(activeGoals[index], color, textTheme, context),
                    childCount: activeGoals.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(24)),
              const SizedBox(height: 16),
              SkeletonLoader(width: double.infinity, height: 150, borderRadius: BorderRadius.circular(20)),
              const SizedBox(height: 16),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(16)),
              )),
            ],
          ),
        ),
        error: (_, __) => const Center(child: Text('Error loading goals')),
      ),
    );
  }

  Widget _buildHeroGauge(double saved, double target, double progress, ColorScheme color, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Progress',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${saved.toStringAsFixed(0)}',
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'of ₹${target.toStringAsFixed(0)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: progress),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: _ModernRingPainter(
                            progress: value,
                            color: color.primary,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(value * 100).toStringAsFixed(0)}%',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color.primary,
                                height: 1,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onPrimaryContainer.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: progress),
                builder: (context, value, child) {
                  return Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.primary,
                                color.tertiary,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '₹${saved.toStringAsFixed(0)} saved',
                          style: textTheme.titleSmall?.copyWith(
                            color: value > 0.3 ? Colors.white : color.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, ColorScheme color, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBoostCard(Goal goal, ColorScheme color, TextTheme textTheme, BuildContext context) {
    final remaining = goal.remainingAmount;
    final monthsAhead = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays ~/ 30
        : 0;
    final suggestedBoost = monthsAhead > 0 ? remaining / monthsAhead : remaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.tertiaryContainer,
            color.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.tertiary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.zap, color: color.tertiary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boost Your Goal',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re only ₹${remaining.toStringAsFixed(0)} away from ${goal.name}!',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add ₹${suggestedBoost.toStringAsFixed(0)}/month to reach your goal on time',
            style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-goal', extra: {'goal': goal});
            },
            icon: const Icon(LucideIcons.arrowUp, size: 18),
            label: const Text('Adjust Now'),
            style: FilledButton.styleFrom(
              backgroundColor: color.tertiary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, ColorScheme color, TextTheme textTheme, BuildContext context) {
    final goalColor = goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final progress = goal.progressPercent;
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/goal-details', extra: goal);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconHelper.getIconData(goal.iconName),
                      color: goalColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (goal.targetDate != null)
                          Text(
                            'By ${DateFormat('MMM d, y').format(goal.targetDate!)}',
                            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${goal.currentAmount.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: goalColor,
                        ),
                      ),
                      Text(
                        'of ₹${goal.targetAmount.toStringAsFixed(0)}',
                        style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(goalColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.trendingUp, size: 14, color: goalColor),
                      const SizedBox(width: 4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% Complete',
                        style: textTheme.bodySmall?.copyWith(
                          color: goalColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (daysLeft > 0)
                    Text(
                      '$daysLeft days left',
                      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ModernRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [
        color,
        color.withValues(alpha: 0.6),
        color,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ModernRingPainter oldDelegate) => 
    oldDelegate.progress != progress || oldDelegate.color != color;
}
