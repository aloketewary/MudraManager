import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

class DebugGamificationButton extends ConsumerWidget {
  const DebugGamificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final service = ref.read(gamificationServiceProvider);

        // Add some XP
        await service?.track(GamificationEvent.transactionAdded);
        await service?.track(GamificationEvent.transactionAdded);
        await service?.track(GamificationEvent.transactionAdded);

        // Trigger budget and goal achievements
        await service?.track(GamificationEvent.budgetCreated);
        await service?.track(GamificationEvent.goalCompleted);

        SnackbarService.success('✅ Dummy data created!');
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Test Gamification'),
    );
  }
}
