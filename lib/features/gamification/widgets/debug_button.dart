import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class GamificationDebugButton extends ConsumerWidget {
  const GamificationDebugButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          final service = await ref.read(gamificationServiceInitProvider.future);
          // await initTestGamificationData(service);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Gamification data created!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.sports_esports),
      label: const Text('Init Gamification'),
    );
  }
}
