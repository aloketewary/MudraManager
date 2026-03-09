import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'dart:math' as math;

class BudgetDetailsScreen extends ConsumerWidget {
  final BudgetWithProgress data;

  const BudgetDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final isGuestMode = ref.watch(guestModeProvider);
    final b = data.budget;
    final spent = data.spent;
    final total = b.amount;
    final displaySpent = GuestModeUtil.applyGuestMode(spent, isGuestMode);
    final displayTotal = GuestModeUtil.applyGuestMode(total, isGuestMode);
    final remaining = displayTotal - displaySpent;
    final pct = displayTotal > 0 ? (displaySpent / displayTotal) : 0;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Calculate days and daily allowance
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final dailyAllowance = daysLeft > 0 ? remaining / daysLeft : 0;

    // Status color based on health
    final statusColor = pct >= 1.0
        ? color.error
        : pct >= 0.8
            ? Colors.orange
            : const Color(0xFF00BFA5); // Teal

    // Sort categories: over 80% first
    final sortedCategories = List.from(data.categorySpendings)
      ..sort((a, b) {
        final aPct = a.allocated > 0 ? a.spent / a.allocated : 0;
        final bPct = b.allocated > 0 ? b.spent / b.allocated : 0;
        if (aPct >= 0.8 && bPct < 0.8) return -1;
        if (aPct < 0.8 && bPct >= 0.8) return 1;
        return bPct.compareTo(aPct);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('MMMM').format(now)} Budget'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/add-budget', extra: {'budget': b}),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Spending Velocity Gauge (Hero Section)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: pct < 0.8
                    ? [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: pct.toDouble()),
                    builder: (context, value, child) {
                      return SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: _VelocityGaugePainter(
                                progress: value,
                                color: statusColor,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Remaining',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: color.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CurrencyText(
                                  amount: remaining > 0 ? remaining : 0,
                                  style: textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'to spend',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, color: statusColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Allowance',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dailyAllowance > 0
                                  ? '₹${dailyAllowance.toStringAsFixed(0)}/day for $daysLeft days'
                                  : 'Budget exceeded',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
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
          ),

          // Spending Projection Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: color.error, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Projection',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pct >= 0.8
                              ? 'At this rate, you may exceed budget by ₹${((displaySpent / now.day) * daysInMonth - displayTotal).toStringAsFixed(0)}'
                              : 'You\'re on track to stay within budget',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Breakdown Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category Breakdown',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // TODO: Implement move funds
                    },
                    icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
                    label: const Text('Move Funds'),
                  ),
                ],
              ),
            ),
          ),

          // Smart Sorted Categories
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = sortedCategories[index];
                final catPct = cat.allocated > 0 ? cat.spent / cat.allocated : 0;
                final catColor = catPct >= 1.0
                    ? color.error
                    : catPct >= 0.8
                        ? Colors.orange
                        : color.primary;
                final isOverBudget = catPct >= 0.8;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isOverBudget
                        ? Border.all(color: catColor.withValues(alpha: 0.5), width: 2)
                        : null,
                    boxShadow: isOverBudget
                        ? [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cat.category.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '₹${GuestModeUtil.applyGuestMode(cat.spent, isGuestMode).toStringAsFixed(0)} / ₹${GuestModeUtil.applyGuestMode(cat.allocated, isGuestMode).toStringAsFixed(0)}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: catPct.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: catColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(catColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(catPct * 100).toStringAsFixed(0)}% used',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: sortedCategories.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _VelocityGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _VelocityGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [color, color.withValues(alpha: 0.6), color],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_VelocityGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
