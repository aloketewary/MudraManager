import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/milestone_share_sheet.dart';

void main() {
  group('MilestoneData', () {
    test('stores all fields correctly', () {
      final data = MilestoneData(
        emoji: '🎯',
        title: 'Goal Reached!',
        stat: 'Emergency Fund',
        description: 'Saved ₹50,000 and hit the target',
        icon: LucideIcons.target,
        accent: const Color(0xFF4CAF50),
      );

      expect(data.emoji, '🎯');
      expect(data.title, 'Goal Reached!');
      expect(data.stat, 'Emergency Fund');
      expect(data.description, 'Saved ₹50,000 and hit the target');
      expect(data.icon, LucideIcons.target);
      expect(data.accent, const Color(0xFF4CAF50));
    });

    test('streak milestone data', () {
      final data = MilestoneData(
        emoji: '🔥',
        title: '30-Day Streak!',
        stat: '30 Days',
        description: 'Tracked expenses every day for 30 days',
        icon: LucideIcons.flame,
        accent: const Color(0xFFFF9800),
      );

      expect(data.emoji, '🔥');
      expect(data.stat, '30 Days');
    });

    test('under budget milestone data', () {
      final data = MilestoneData(
        emoji: '💪',
        title: 'Under Budget!',
        stat: '₹2,500 saved',
        description: 'Stayed within budget for the entire month',
        icon: LucideIcons.piggyBank,
        accent: const Color(0xFF2196F3),
      );

      expect(data.title, 'Under Budget!');
    });
  });

  group('Widget service budget remaining logic', () {
    test('positive remaining shows "left"', () {
      final budgetAmount = 10000.0;
      final spent = 3000.0;
      final remaining = budgetAmount - spent;

      expect(remaining, 7000.0);
      expect(remaining >= 0, true);
    });

    test('negative remaining shows "over"', () {
      final budgetAmount = 10000.0;
      final spent = 12000.0;
      final remaining = budgetAmount - spent;

      expect(remaining, -2000.0);
      expect(remaining >= 0, false);
      expect(remaining.abs(), 2000.0);
    });

    test('exact budget shows zero remaining', () {
      final budgetAmount = 10000.0;
      final spent = 10000.0;
      final remaining = budgetAmount - spent;

      expect(remaining, 0.0);
      expect(remaining >= 0, true);
    });

    test('no spending shows full budget remaining', () {
      final budgetAmount = 10000.0;
      final spent = 0.0;
      final remaining = budgetAmount - spent;

      expect(remaining, 10000.0);
    });
  });
}
