import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/trip.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/service/trip_service.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TripService(isarService);
});

final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final service = ref.watch(tripServiceProvider);
  return await service.getAllTrips();
});

final activeTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final service = ref.watch(tripServiceProvider);
  return await service.getActiveTrips();
});

final tripByIdProvider = FutureProvider.family<Trip?, int>((ref, id) async {
  final service = ref.watch(tripServiceProvider);
  return await service.getTripById(id);
});
