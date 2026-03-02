import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';

final spendingPersonalityProvider = FutureProvider<SpendingPersonality?>((ref) async {
  return await SpendingAnalyzer.analyzePersonality();
});

class SpendingPersonalityCard extends ConsumerWidget {
  final double globalPadding;

  const SpendingPersonalityCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personality = ref.watch(spendingPersonalityProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return personality.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding, vertical: 16),
          child: Card(
            elevation: 0,
            color: color.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.brain, color: color.onPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your Spending Personality',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsight(
                    context,
                    'You spend most on ${data.topCategory}',
                    data.topCategoryEmoji,
                  ),
                  const SizedBox(height: 8),
                  _buildInsight(context, data.spendingPattern, 'calendar'),
                  const SizedBox(height: 8),
                  _buildInsight(context, data.behaviorType, 'shopping-bag'),
                  const SizedBox(height: 8),
                  _buildInsight(context, data.spendingTrend, 'trending-up'),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsight(BuildContext context, String text, String iconName) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final iconMap = {
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'shopping-bag': LucideIcons.shoppingBag,
      'film': LucideIcons.film,
      'heart-pulse': LucideIcons.heartPulse,
      'book-open': LucideIcons.bookOpen,
      'zap': LucideIcons.zap,
      'shopping-cart': LucideIcons.shoppingCart,
      'wallet': LucideIcons.wallet,
      'calendar': LucideIcons.calendar,
      'trending-up': LucideIcons.trendingUp,
    };

    return Row(
      children: [
        Icon(iconMap[iconName] ?? LucideIcons.wallet, size: 16, color: color.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
