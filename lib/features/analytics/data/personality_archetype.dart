import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';

class PersonalityArchetype {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String svgAsset;
  final IconData icon;
  final Color color;
  final String trait;
  final List<String> traits;
  final String guidance;

  const PersonalityArchetype({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.svgAsset,
    required this.icon,
    required this.color,
    required this.trait,
    required this.traits,
    required this.guidance,
  });

  static const _mindfulPlanner = PersonalityArchetype(
    id: 'mindful_planner',
    name: 'Mindful Planner',
    tagline: 'Awareness is your superpower',
    description: 'You spend with awareness and control',
    svgAsset: 'assets/logo/personality/shield.svg',
    icon: LucideIcons.brain,
    color: Color(0xFF6366F1),
    trait: 'Awareness-driven',
    traits: [
      'Tracks expenses regularly',
      'Keeps spending balanced',
      'Avoids overspending',
    ],
    guidance: 'You\'re doing great — consider increasing savings by 5%',
  );

  static const _goalChaser = PersonalityArchetype(
    id: 'goal_chaser',
    name: 'Goal Chaser',
    tagline: 'Future over impulse',
    description: 'You prioritize future over impulse',
    svgAsset: 'assets/logo/personality/saver.svg',
    icon: LucideIcons.target,
    color: Color(0xFF10B981),
    trait: 'Goal-driven',
    traits: [
      'Saves actively towards goals',
      'High savings rate',
      'Focused and disciplined',
    ],
    guidance: 'Keep the momentum — you\'re building something great',
  );

  static const _freeSpirit = PersonalityArchetype(
    id: 'free_spirit',
    name: 'Free Spirit',
    tagline: 'Life is for living',
    description: 'You enjoy life and spend freely',
    svgAsset: 'assets/logo/personality/luxury.svg',
    icon: LucideIcons.sparkles,
    color: Color(0xFFF59E0B),
    trait: 'Experience-driven',
    traits: [
      'High discretionary spending',
      'Enjoys experiences',
      'Spontaneous with money',
    ],
    guidance: 'Small adjustments can boost your savings without losing the fun',
  );

  static const _impulseSpender = PersonalityArchetype(
    id: 'impulse_spender',
    name: 'Impulse Spender',
    tagline: 'Quick decisions, quick spends',
    description: 'You spend quickly without much planning',
    svgAsset: 'assets/logo/personality/food.svg',
    icon: LucideIcons.zap,
    color: Color(0xFFEF4444),
    trait: 'Impulse-driven',
    traits: [
      'Many small transactions',
      'Frequent spending bursts',
      'Low planning tendency',
    ],
    guidance: 'Try setting a weekly budget to stay in control',
  );

  static const _cautiousSaver = PersonalityArchetype(
    id: 'cautious_saver',
    name: 'Cautious Saver',
    tagline: 'Safety first, always',
    description: 'You prefer safety over risk',
    svgAsset: 'assets/logo/personality/shield.svg',
    icon: LucideIcons.shield,
    color: Color(0xFF0EA5E9),
    trait: 'Security-driven',
    traits: [
      'Low spending habits',
      'High savings rate',
      'Risk-averse approach',
    ],
    guidance: 'You\'re secure — consider investing a small portion for growth',
  );

  static const _balancedExplorer = PersonalityArchetype(
    id: 'balanced_explorer',
    name: 'Balanced Explorer',
    tagline: 'The best of both worlds',
    description: 'You maintain a flexible balance',
    svgAsset: 'assets/logo/personality/plane.svg',
    icon: LucideIcons.scale,
    color: Color(0xFF8B5CF6),
    trait: 'Balance-driven',
    traits: [
      'Mix of spending and saving',
      'Adapts to situations',
      'Moderate in all areas',
    ],
    guidance: 'You\'re well-balanced — pick one area to optimize further',
  );

  static PersonalityArchetype fromSpendingPersonality(
    SpendingPersonality data,
  ) {
    // Score each personality type
    final scores = <String, double>{};

    // ── Mindful Planner: tracks regularly + balanced + budgets ──
    scores['mindful'] = 0;
    if (data.budgetAdherence > 50) scores['mindful'] = scores['mindful']! + 3;
    if (data.essentialRatio > 0.4 && data.essentialRatio < 0.7) {
      scores['mindful'] = scores['mindful']! + 2;
    }
    if (data.txnCount > 15) scores['mindful'] = scores['mindful']! + 1;
    if (!data.behaviorType.contains('Impulse')) {
      scores['mindful'] = scores['mindful']! + 2;
    }

    // ── Goal Chaser: high savings + active goals ──
    scores['goal'] = 0;
    if (data.savingsRate > 30) scores['goal'] = scores['goal']! + 3;
    if (data.savingsRate > 15) scores['goal'] = scores['goal']! + 1;
    if (data.activeGoals >= 2) scores['goal'] = scores['goal']! + 3;
    if (data.activeGoals >= 1) scores['goal'] = scores['goal']! + 1;
    if (data.spendingTrend.contains('decreasing')) {
      scores['goal'] = scores['goal']! + 1;
    }

    // ── Free Spirit: high discretionary + weekend heavy ──
    scores['free'] = 0;
    if (data.essentialRatio < 0.3) scores['free'] = scores['free']! + 3;
    if (data.weekendRatio > 0.4) scores['free'] = scores['free']! + 2;
    if (data.savingsRate < 10) scores['free'] = scores['free']! + 2;
    if (data.spendingTrend.contains('increasing')) {
      scores['free'] = scores['free']! + 1;
    }

    // ── Impulse Spender: high frequency + many burst days ──
    scores['impulse'] = 0;
    if (data.highActivityDays >= 3) scores['impulse'] = scores['impulse']! + 3;
    if (data.highActivityDays >= 1) scores['impulse'] = scores['impulse']! + 1;
    if (data.behaviorType.contains('Impulse')) {
      scores['impulse'] = scores['impulse']! + 3;
    }
    if (data.budgetAdherence < 30) scores['impulse'] = scores['impulse']! + 1;

    // ── Cautious Saver: high savings + low spending ──
    scores['cautious'] = 0;
    if (data.savingsRate > 40) scores['cautious'] = scores['cautious']! + 3;
    if (data.savingsRate > 25) scores['cautious'] = scores['cautious']! + 1;
    if (data.txnCount < 20) scores['cautious'] = scores['cautious']! + 2;
    if (data.essentialRatio > 0.6) scores['cautious'] = scores['cautious']! + 2;

    // ── Balanced Explorer: moderate everything ──
    scores['balanced'] = 0;
    if (data.savingsRate > 10 && data.savingsRate < 30) {
      scores['balanced'] = scores['balanced']! + 2;
    }
    if (data.essentialRatio > 0.3 && data.essentialRatio < 0.6) {
      scores['balanced'] = scores['balanced']! + 2;
    }
    if (data.weekendRatio > 0.2 && data.weekendRatio < 0.4) {
      scores['balanced'] = scores['balanced']! + 1;
    }
    if (data.spendingTrend.contains('Steady')) {
      scores['balanced'] = scores['balanced']! + 2;
    }

    // Pick highest score
    final winner =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return switch (winner) {
      'mindful' => _mindfulPlanner,
      'goal' => _goalChaser,
      'free' => _freeSpirit,
      'impulse' => _impulseSpender,
      'cautious' => _cautiousSaver,
      _ => _balancedExplorer,
    };
  }

  /// Tone-aware description for the personality.
  String get tonedDescription {
    return description;
  }
}
