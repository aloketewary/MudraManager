import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

class DebugCleanupScreen extends ConsumerWidget {
  const DebugCleanupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Cleanup')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final service = ref.read(gamificationServiceProvider);
            await service?.forceCleanup();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleanup completed!')),
              );
            }
          },
          child: const Text('Force Cleanup Duplicates'),
        ),
      ),
    );
  }
}
