import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trip_detail_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/split_detail_screen.dart';

/// Thin dispatcher that loads the trip and routes to the correct detail screen.
class GroupDetailDispatcher extends ConsumerWidget {
  final int tripId;

  const GroupDetailDispatcher({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripByIdProvider(tripId));

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Group not found')),
          );
        }
        return trip.isTrip
            ? TripDetailScreen(tripId: tripId)
            : SplitDetailScreen(tripId: tripId);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(BuddyMessages.genericError)),
        body: Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }
}
