import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/goal/presentation/widgets/goal_card.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';


class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Goals', style: textTheme.titleLarge),
      ),
      body: Hero(
        tag: 'goalExpandHero',
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return const NoDataFound(
                  message: 'No goals found. Add one!',
                  iconData: Icons.emoji_flags_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                itemCount: goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return GoalCard(
                    goal: goal,
                    onTap: () {
                      context.push('/goal-details', extra: goal);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-goal');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}
