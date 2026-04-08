import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';

void main() {
  group('PersonalityArchetype.fromSpendingPersonality', () {
    test('high savings + active goals → Goal Chaser', () {
      final data = SpendingPersonality(
        topCategory: 'Food',
        topCategoryEmoji: 'utensils',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Spending decreasing',
        savingsRate: 40,
        budgetAdherence: 50,
        activeGoals: 3,
        txnCount: 20,
        avgTxnAmount: 500,
        weekendRatio: 0.2,
        highActivityDays: 0,
        essentialRatio: 0.5,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'goal_chaser');
    });

    test('high impulse + many burst days → Impulse Spender', () {
      final data = SpendingPersonality(
        topCategory: 'Shopping',
        topCategoryEmoji: 'shopping-bag',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Impulse buyer',
        spendingTrend: 'Spending increasing',
        savingsRate: 5,
        budgetAdherence: 10,
        activeGoals: 0,
        txnCount: 50,
        avgTxnAmount: 200,
        weekendRatio: 0.25,
        highActivityDays: 6,
        essentialRatio: 0.4,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'impulse_spender');
    });

    test('very high savings + low txn count → Cautious Saver', () {
      final data = SpendingPersonality(
        topCategory: 'Grocery',
        topCategoryEmoji: 'shopping-cart',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Steady spender',
        savingsRate: 50,
        budgetAdherence: 80,
        activeGoals: 0,
        txnCount: 10,
        avgTxnAmount: 300,
        weekendRatio: 0.1,
        highActivityDays: 0,
        essentialRatio: 0.7,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'cautious_saver');
    });

    test('low essentials + weekend heavy → Free Spirit', () {
      final data = SpendingPersonality(
        topCategory: 'Entertainment',
        topCategoryEmoji: 'film',
        spendingPattern: 'Weekend spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Spending increasing',
        savingsRate: 5,
        budgetAdherence: 30,
        activeGoals: 0,
        txnCount: 25,
        avgTxnAmount: 800,
        weekendRatio: 0.5,
        highActivityDays: 1,
        essentialRatio: 0.15,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'free_spirit');
    });

    test('budget adherence + balanced categories → Mindful Planner', () {
      final data = SpendingPersonality(
        topCategory: 'Food',
        topCategoryEmoji: 'utensils',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Steady spender',
        savingsRate: 15,
        budgetAdherence: 80,
        activeGoals: 1,
        txnCount: 30,
        avgTxnAmount: 400,
        weekendRatio: 0.3,
        highActivityDays: 0,
        essentialRatio: 0.55,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'mindful_planner');
    });

    test('moderate everything → Balanced Explorer', () {
      final data = SpendingPersonality(
        topCategory: 'Food',
        topCategoryEmoji: 'utensils',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Steady spender',
        savingsRate: 20,
        budgetAdherence: 40,
        activeGoals: 0,
        txnCount: 20,
        avgTxnAmount: 500,
        weekendRatio: 0.3,
        highActivityDays: 0,
        essentialRatio: 0.45,
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);
      expect(archetype.id, 'balanced_explorer');
    });
  });

  group('PersonalityArchetype properties', () {
    test('all archetypes have required fields', () {
      final data = SpendingPersonality(
        topCategory: 'Food',
        topCategoryEmoji: 'utensils',
        spendingPattern: 'Weekday spender',
        behaviorType: 'Planned spender',
        spendingTrend: 'Steady spender',
      );
      final archetype = PersonalityArchetype.fromSpendingPersonality(data);

      expect(archetype.id, isNotEmpty);
      expect(archetype.name, isNotEmpty);
      expect(archetype.tagline, isNotEmpty);
      expect(archetype.description, isNotEmpty);
      expect(archetype.traits, isNotEmpty);
      expect(archetype.traits.length, 3);
      expect(archetype.guidance, isNotEmpty);
    });
  });
}
