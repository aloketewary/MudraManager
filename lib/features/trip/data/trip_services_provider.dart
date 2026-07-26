import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/active_trip_service.dart';
import 'package:mudra_manager/core/db/models/trip.dart';

final activeTripServiceProvider = FutureProvider<ActiveTripService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return ActiveTripService(isar);
});

final activeTripProvider = StreamProvider<Trip?>((ref) async* {
  final service = await ref.watch(activeTripServiceProvider.future);
  yield* Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => service.getActiveTrip());
});
