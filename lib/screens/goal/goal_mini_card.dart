import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/goal/add_edit_goal_screen.dart';
import 'package:mudra_manager/screens/goal/goal_card.dart';

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
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
              IconButton.filled(
                onPressed: () {
                  // This will be navigated via the Home page tab switching
                  // but for now, we can just open the goal list or handled by the parent
                },
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return NoDataFound(
                message: "No goals found. Add one!",
                iconData: Icons.emoji_flags_outlined,
                action: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditGoalScreen(),
                      ),
                    );
                  },
                  child: const Text("Add Goal"),
                ),
              );
            }
            // Just show the first goal for the mini card, or a horizontal list
            // BudgetMiniCard shows all budgets in a column, let's do the same for consistency
            return Column(
              children:
                  goals.map((goal) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: globalPadding,
                        vertical: 4,
                      ),
                      child: GoalCard(goal: goal),
                    );
                  }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error: $e")),
        ),
      ],
    );
  }
}
