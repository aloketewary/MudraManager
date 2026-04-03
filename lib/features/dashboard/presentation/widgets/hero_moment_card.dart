import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';

class HeroMoment {
  final IconData icon;
  final String message;
  final Color? accentColor;

  const HeroMoment({
    required this.icon,
    required this.message,
    this.accentColor,
  });
}

final heroMomentProvider = Provider<HeroMoment?>((ref) {
  final data = ref.watch(dashboardDataProvider).valueOrNull;
  if (data == null) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isGuestMode = ref.watch(guestModeProvider);

  final txns = data.transactions.where((t) => !t.isTransfer).toList();

  // 1. Today's spend
  final todayExpense = txns
      .where(
        (t) =>
            t.isExpense &&
            DateTime(t.date.year, t.date.month, t.date.day) == today,
      )
      .fold<double>(0, (s, t) => s + t.amount);

  // 2. This week's savings (income - expense for last 7 days)
  final weekAgo = today.subtract(const Duration(days: 7));
  final weekTxns = txns.where((t) => t.date.isAfter(weekAgo));
  final weekIncome = weekTxns
      .where((t) => !t.isExpense)
      .fold<double>(0, (s, t) => s + t.amount);
  final weekExpense = weekTxns
      .where((t) => t.isExpense)
      .fold<double>(0, (s, t) => s + t.amount);
  final weekSavings = weekIncome - weekExpense;

  // Month-over-month improvement
  if (now.day >= 7) {
    // need enough data into the month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthSameDay = DateTime(now.year, now.month - 1, now.day);
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final lastMonthExpenseToDate = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date
                  .isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
              t.date.isBefore(lastMonthSameDay.add(const Duration(days: 1))),
        )
        .fold<double>(0, (s, t) => s + t.amount);

    final thisMonthExpense = txns
        .where(
          (t) =>
              t.isExpense &&
              t.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))),
        )
        .fold<double>(0, (s, t) => s + t.amount);

    if (lastMonthExpenseToDate > 0 &&
        thisMonthExpense < lastMonthExpenseToDate) {
      final improvement = ((lastMonthExpenseToDate - thisMonthExpense) /
          lastMonthExpenseToDate *
          100);
      if (improvement >= 5) {
        return HeroMoment(
          icon: LucideIcons.trendingDown,
          message:
              'You\'re spending ${improvement.toStringAsFixed(0)}% less than last month — that\'s real progress 💪',
          accentColor: const Color(0xFF4CAF50),
        );
      }
    }
  }

  // 3. Monthly savings
  final monthlySavings = data.totalIncome - data.totalExpense;
  final savingsRate =
      data.totalIncome > 0 ? (monthlySavings / data.totalIncome * 100) : 0.0;

  // 6. Top category today
  final todayTxns = txns.where(
    (t) =>
        t.isExpense && DateTime(t.date.year, t.date.month, t.date.day) == today,
  );
  final catMap = <String, double>{};
  for (final t in todayTxns) {
    t.category.loadSync();
    final name = t.category.value?.name ?? 'Other';
    catMap[name] = (catMap[name] ?? 0) + t.amount;
  }
  if (catMap.isNotEmpty) {
    catMap.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  // Pick the best hero moment (priority order)
  double applyGM(double v) => GuestModeUtil.applyGuestMode(v, isGuestMode);

  // Week savings positive
  if (weekSavings > 0 && weekIncome > 0) {
    return HeroMoment(
      icon: LucideIcons.piggyBank,
      message:
          '₹${applyGM(weekSavings).toStringAsFixed(0)} saved this week — not bad at all!',
      accentColor: const Color(0xFF4CAF50),
    );
  }

  // Monthly savings positive
  if (monthlySavings > 0 && savingsRate >= 10) {
    return HeroMoment(
      icon: LucideIcons.target,
      message:
          '${savingsRate.toStringAsFixed(0)}% of your income is staying with you this month 🙌',
      accentColor: const Color(0xFF4CAF50),
    );
  }

// Goals almost done
  if (data.goals.isNotEmpty) {
    final nearDone =
        data.goals.where((g) => g.isActive && g.progressPercent >= 0.8).length;
    if (nearDone > 0) {
      return HeroMoment(
        icon: LucideIcons.target,
        message:
            'So close! $nearDone goal${nearDone > 1 ? 's' : ''} almost at the finish line 🏁',
        accentColor: const Color(0xFF4CAF50),
      );
    }
  }

  // Zero spend day — celebrate
  if (todayExpense == 0 && data.transactions.isNotEmpty) {
    return const HeroMoment(
      icon: LucideIcons.sparkles,
      message: 'Zero spent today — your wallet thanks you ✨',
      accentColor: Color(0xFF2196F3),
    );
  }

  // Fallback: today's spend WITH context
  if (todayExpense > 0) {
    final avgDaily = data.totalExpense / (now.day > 1 ? now.day - 1 : 1);
    final isUnder = todayExpense <= avgDaily;
    return HeroMoment(
      icon: isUnder ? LucideIcons.circleCheck : LucideIcons.receiptText,
      message: isUnder
          ? '₹${applyGM(todayExpense).toStringAsFixed(0)} today — under your ₹${applyGM(avgDaily).toStringAsFixed(0)} daily average 👍'
          : '₹${applyGM(todayExpense).toStringAsFixed(0)} today vs ₹${applyGM(avgDaily).toStringAsFixed(0)} daily average',
      accentColor: isUnder ? const Color(0xFF4CAF50) : null,
    );
  }

  if (DateTime.now().day % 3 == 0) {
    return const HeroMoment(
      icon: LucideIcons.shieldCheck,
      message: 'Your data never leaves this device — 100% offline, 100% yours',
      accentColor: Color(0xFF009688),
    );
  }

  // All caught up — nothing needs attention
  if (data.transactions.isNotEmpty) {
    return HeroMoment(
      icon: LucideIcons.circleCheck,
      message: Tone.current.dashboardAllCaughtUp,
      accentColor: const Color(0xFF4CAF50),
    );
  }

  return null;
});

class HeroMomentCard extends ConsumerStatefulWidget {
  const HeroMomentCard({super.key});

  @override
  ConsumerState<HeroMomentCard> createState() => _HeroMomentCardState();
}

class _HeroMomentCardState extends ConsumerState<HeroMomentCard>
    with SingleTickerProviderStateMixin {
  static bool _dismissedThisSession = false;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _sizeFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..value = 1.0; // start fully visible

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _sizeFactor = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (!_dismissedThisSession) {
      Future.delayed(const Duration(seconds: 10), _dismiss);
    }
  }

  void _dismiss() {
    if (!mounted || _dismissedThisSession) return;
    _controller.reverse().then((_) {
      if (mounted) setState(() => _dismissedThisSession = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissedThisSession) return const SizedBox.shrink();

    final hero = ref.watch(heroMomentProvider);
    final spacing = ref.watch(spacingProvider);
    if (hero == null) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = hero.accentColor ?? color.primary;

    return SizeTransition(
      sizeFactor: _sizeFactor,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _opacity,
        child: GestureDetector(
          onTap: _dismiss,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(),
              color: color.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                      alignment: Alignment.center,
                      child: Icon(hero.icon, color: accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        hero.message,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.close,
                      color: color.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
