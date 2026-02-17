import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/goal/goal_circular_card.dart';
import 'package:mudra_manager/components/adaptive_text.dart';

class GoalMiniCard extends ConsumerWidget {
  final double globalPadding;

  const GoalMiniCard({super.key, this.globalPadding = 16.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdaptiveText(
                "Goals",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ),
                maxLines: 1,
              ),
              Hero(
                tag: 'goalExpandHero',
                child: TextButton(
                  onPressed: () => context.push('/goal-screen'),
                  child: const Text('View All'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: globalPadding),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/add-goal');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_flags_outlined, size: 48, color: color.primary.withValues(alpha: 0.5)),
                          SizedBox(height: 12),
                          Text(
                            "No goals found. Add one!",
                            style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.push('/add-goal');
                            },
                            icon: Icon(Icons.add),
                            label: Text("Add Goal"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            // Horizontal scrolling circular cards
            return SizedBox(
              height: 220,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: globalPadding),
                scrollDirection: Axis.horizontal,
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  return GoalCircularCard(goal: goals[index]);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error: $e")),
        ),
      ],
    );
  }
}
