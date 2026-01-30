import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/goal/goal_circular_card.dart';

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
              Text(
                "Goals",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {
                  context.push('/goal-screen');
                },
                icon: const Icon(Icons.open_in_new, size: 20),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: globalPadding),
                child: NoDataFound(
                  message: "No goals found. Add one!",
                  iconData: Icons.emoji_flags_outlined,
                  action: ElevatedButton(
                    onPressed: () {
                      context.push('/add-goal');
                    },
                    child: const Text("Add Goal"),
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
