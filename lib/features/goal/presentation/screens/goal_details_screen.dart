import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class GoalDetailsScreen extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends ConsumerState<GoalDetailsScreen> {
  double _boostAmount = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.goal.progressPercent >= 1.0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final progress = widget.goal.progressPercent;
    final remaining = widget.goal.remainingAmount;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final goalColor = widget.goal.colorValue != null ? Color(widget.goal.colorValue!) : color.primary;

    final daysLeft = widget.goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final monthsLeft = daysLeft / 30;
    final currentMonthlyRate = monthsLeft > 0 ? remaining / monthsLeft : 0;
    final boostedMonthlyRate = currentMonthlyRate + _boostAmount;
    final boostedMonths = boostedMonthlyRate > 0 ? remaining / boostedMonthlyRate : monthsLeft;
    final monthsSaved = monthsLeft - boostedMonths;
    final newTargetDate = DateTime.now().add(Duration(days: (boostedMonths * 30).toInt()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/add-goal', extra: {'goal': widget.goal}),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // Hero Progress Ring
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    goalColor.withValues(alpha: 0.15),
                    goalColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: progress),
                    builder: (context, value, child) {
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(180, 180),
                              painter: _HeroRingPainter(progress: value, color: goalColor),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(value * 100).toStringAsFixed(0)}%',
                                  style: textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: goalColor,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CurrencyText(
                                  amount: GuestModeUtil.applyGuestMode(widget.goal.currentAmount, isGuestMode),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color.onSurface,
                                  ),
                                ),
                                Text(
                                  'of ₹${widget.goal.targetAmount.toStringAsFixed(0)}',
                                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
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
            ),
          ),

          // Time-to-Goal Card
          if (widget.goal.targetDate != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, color: color.onPrimaryContainer, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Date',
                            style: textTheme.labelMedium?.copyWith(color: color.onPrimaryContainer),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM d, y').format(_boostAmount > 0 ? newTargetDate : widget.goal.targetDate!),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onPrimaryContainer,
                            ),
                          ),
                          if (daysLeft > 0)
                            Text(
                              '$daysLeft days remaining',
                              style: textTheme.bodySmall?.copyWith(color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // What-If Simulator
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.tertiary.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.zap, color: color.tertiary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Boost Your Progress',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add ₹${_boostAmount.toStringAsFixed(0)}/month',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.tertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_boostAmount > 0 && monthsLeft > 0 && monthsSaved > 0)
                    Text(
                      'Reach goal ${monthsSaved.abs().toStringAsFixed(1)} months earlier',
                      style: textTheme.bodyMedium?.copyWith(color: color.onTertiaryContainer),
                    )
                  else if (_boostAmount > 0)
                    Text(
                      'Boost your monthly contribution',
                      style: textTheme.bodyMedium?.copyWith(color: color.onTertiaryContainer),
                    ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color.tertiary,
                      inactiveTrackColor: color.tertiary.withValues(alpha: 0.2),
                      thumbColor: color.tertiary,
                      overlayColor: color.tertiary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _boostAmount,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _boostAmount = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Deposit Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showQuickDepositSheet(context, goalColor);
                },
                icon: const Icon(LucideIcons.plus, size: 20),
                label: const Text('Quick Deposit'),
                style: FilledButton.styleFrom(
                  backgroundColor: goalColor,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
          ),

          // Milestones
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestones',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMilestone('Started', widget.goal.currentAmount >= 0, goalColor, textTheme, color),
                  _buildMilestone('25% Complete', progress >= 0.25, goalColor, textTheme, color),
                  _buildMilestone('50% Complete', progress >= 0.50, goalColor, textTheme, color),
                  _buildMilestone('75% Complete', progress >= 0.75, goalColor, textTheme, color),
                  _buildMilestone('Goal Reached!', progress >= 1.0, goalColor, textTheme, color),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: math.pi / 2,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.3,
          colors: [goalColor, Colors.amber, Colors.green, Colors.pink, Colors.blue],
        ),
      ),
    ],
      ),
    );
  }

  Widget _buildMilestone(String label, bool achieved, Color goalColor, TextTheme textTheme, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: achieved ? goalColor : color.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: achieved
                ? Icon(LucideIcons.check, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
              color: achieved ? color.onSurface : color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickDepositSheet(BuildContext context, Color goalColor) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.piggyBank, color: goalColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Quick Deposit',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  HapticFeedback.mediumImpact();
                  final wasComplete = widget.goal.progressPercent >= 1.0;
                  widget.goal.currentAmount += amount;
                  final isNowComplete = widget.goal.progressPercent >= 1.0;
                  
                  await ref.read(goalServiceProvider).updateGoal(widget.goal);
                  ref.invalidate(goalsProvider);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                    
                    if (!wasComplete && isNowComplete) {
                      _confettiController.play();
                    }
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: goalColor,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Add to Goal'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HeroRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 16.0;

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
  bool shouldRepaint(_HeroRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
