import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/screens/goal/goal_card.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Goals", style: Theme.of(context).textTheme.titleLarge),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const NoDataFound(
              message: "No goals found. Add one!",
              iconData: Icons.emoji_flags_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return GoalCard(
                goal: goal,
                onTap: () {
                  context.push('/add-goal', extra: {'goal': goal});
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goalExpandHero',
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-goal');
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Goal"),
      ),
    );
  }
}
