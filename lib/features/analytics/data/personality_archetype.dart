import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';

class PersonalityArchetype {
  final String name;
  final String tagline;
  final String description;
  final String svgAsset;
  final IconData icon;
  final Color color;
  final String trait;

  const PersonalityArchetype({
    required this.name,
    required this.tagline,
    required this.description,
    required this.svgAsset,
    required this.icon,
    required this.color,
    required this.trait,
  });

  static PersonalityArchetype fromSpendingPersonality(SpendingPersonality data) {
    final isHighValue = data.topCategory.toLowerCase().contains('luxury') ||
        data.topCategory.toLowerCase().contains('quality');
    final isTravel = data.topCategory.toLowerCase().contains('travel') ||
        data.topCategory.toLowerCase().contains('transport');
    final isFrequent = data.behaviorType.contains('Impulse');
    final isSaver = data.spendingTrend.contains('decreasing');

    if (isHighValue && !isFrequent) {
      return const PersonalityArchetype(
        name: 'The Curator',
        tagline: 'Quality over quantity',
        description: 'You invest in quality over quantity',
        svgAsset: 'assets/logo/personality/luxury.svg',
        icon: LucideIcons.gem,
        color: Colors.purple,
        trait: 'Value-driven',
      );
    } else if (isTravel) {
      return const PersonalityArchetype(
        name: 'The Nomad',
        tagline: 'Experiences over things',
        description: 'You prioritize experiences and memories',
        svgAsset: 'assets/logo/personality/plane.svg',
        icon: LucideIcons.plane,
        color: Colors.blue,
        trait: 'Memory-driven',
      );
    } else if (isFrequent) {
      return const PersonalityArchetype(
        name: 'The Daily Ritualist',
        tagline: 'Small treats, big joy',
        description: 'Small treats make your day brighter',
        svgAsset: 'assets/logo/personality/food.svg',
        icon: LucideIcons.coffee,
        color: Colors.orange,
        trait: 'Habit-driven',
      );
    } else if (isSaver) {
      return const PersonalityArchetype(
        name: 'The Fortress',
        tagline: 'Security first',
        description: 'Security and savings are your priority',
        svgAsset: 'assets/logo/personality/shield.svg',
        icon: LucideIcons.shield,
        color: Colors.green,
        trait: 'Security-driven',
      );
    } else {
      return const PersonalityArchetype(
        name: 'The Balanced',
        tagline: 'Balanced spending',
        description: 'You maintain a healthy spending balance',
        svgAsset: 'assets/logo/personality/saver.svg',
        icon: LucideIcons.scale,
        color: Colors.teal,
        trait: 'Balance-driven',
      );
    }
  }
}
