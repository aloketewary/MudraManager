import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';

class SpendingPersonalityScreen extends ConsumerWidget {
  const SpendingPersonalityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personality = ref.watch(spendingPersonalityProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Spending Personality'),
        elevation: 0,
      ),
      body: personality.when(
        data: (data) {
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.brain,
                      size: 64, color: color.onSurfaceVariant,),
                  const SizedBox(height: 16),
                  Text(
                    'Not enough data yet',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add more transactions to discover your personality',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: color.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final archetype = PersonalityArchetype.fromSpendingPersonality(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildArchetypeCard(archetype, color, textTheme),
                const SizedBox(height: 20),
                _buildBehaviorMap(data, color, textTheme),
                const SizedBox(height: 20),
                _buildVibeCloud(data, color, textTheme),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Unable to load personality data')),
      ),
    );
  }

  Widget _buildArchetypeCard(
      PersonalityArchetype archetype, ColorScheme color, TextTheme textTheme,) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset(
                  archetype.svgAsset,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                archetype.name,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  archetype.trait,
                  style: textTheme.titleMedium?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                archetype.description,
                style: textTheme.bodyLarge?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBehaviorMap(
      SpendingPersonality data, ColorScheme color, TextTheme textTheme,) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.map, color: color.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Behavior Map',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBehaviorRow('Pattern', data.spendingPattern,
                  LucideIcons.calendar, color, textTheme,),
              const SizedBox(height: 12),
              _buildBehaviorRow('Style', data.behaviorType, LucideIcons.zap,
                  color, textTheme,),
              const SizedBox(height: 12),
              _buildBehaviorRow('Trend', data.spendingTrend,
                  LucideIcons.trendingUp, color, textTheme,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBehaviorRow(String label, String value, IconData icon,
      ColorScheme color, TextTheme textTheme,) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeCloud(
      SpendingPersonality data, ColorScheme color, TextTheme textTheme,) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, color: color.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Your Vibe',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildVibeBubble(data.topCategory, color, textTheme,
                      isPrimary: true,),
                  _buildVibeBubble(
                      data.spendingPattern.split(' ')[0], color, textTheme,),
                  _buildVibeBubble(
                      data.behaviorType.split(' ')[0], color, textTheme,),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeBubble(String text, ColorScheme color, TextTheme textTheme,
      {bool isPrimary = false,}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? color.primaryContainer : color.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color:
              isPrimary ? color.onPrimaryContainer : color.onSecondaryContainer,
        ),
      ),
    );
  }
}
