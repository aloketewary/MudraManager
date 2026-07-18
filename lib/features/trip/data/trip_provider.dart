import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/trip/data/trip_service.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);
  return TripService(isarService, gamificationService);
});

final allTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  ref.watch(tripChangeProvider);
  final service = ref.watch(tripServiceProvider);
  return await service.getAllTrips();
});

final activeTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  ref.watch(tripChangeProvider);
  final service = ref.watch(tripServiceProvider);
  return await service.getActiveTrips();
});

final tripByIdProvider =
    FutureProvider.autoDispose.family<Trip?, int>((ref, id) async {
  final service = ref.watch(tripServiceProvider);
  return await service.getTripById(id);
});

final tripSettlementsProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, double>>, int>((ref, tripId) async {
  final service = ref.watch(tripServiceProvider);
  return await service.calculateSettlements(tripId);
});

final tripSummaryProvider = FutureProvider.autoDispose
    .family<TripSummary, int>((ref, tripId) async {
  final service = ref.watch(tripServiceProvider);
  final trip = await service.getTripById(tripId);
  if (trip == null) {
    return const TripSummary(
      participantCount: 0,
      totalSpent: 0,
      ownerShare: 0,
      ownerPaid: 0,
      netBalance: 0,
    );
  }
  return await service.getTripSummary(trip);
});
/// Provider for fetching trip names by transaction IDs.
/// Caches results to avoid repeated queries during list rebuilds.
final tripNamesByTransactionIdsProvider =
    FutureProvider.family<Map<int, String>, List<int>>((ref, transactionIds) async {
  if (transactionIds.isEmpty) return {};
  final service = ref.watch(tripServiceProvider);
  return await service.getTripNamesByTransactionIds(transactionIds);
});