import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/active_trip_service.dart';
import 'package:mudra_manager/core/services/settlement_service.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/services/settlement_service.dart' show ParticipantBalance;

final activeTripServiceProvider = FutureProvider<ActiveTripService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return ActiveTripService(isar);
});

final settlementServiceProvider = FutureProvider<SettlementService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return SettlementService(isar);
});

final activeTripProvider = StreamProvider<Trip?>((ref) async* {
  final service = await ref.watch(activeTripServiceProvider.future);
  yield* Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) => service.getActiveTrip());
});

final liveBalancesProvider =
    FutureProvider.family<List<ParticipantBalance>, int>((ref, tripId) async {
  final service = await ref.watch(settlementServiceProvider.future);
  return service.getLiveBalances(tripId);
});

final pendingTransactionsProvider =
    FutureProvider.family<List<Transaction>, int>((ref, tripId) async {
  final service = await ref.watch(activeTripServiceProvider.future);
  return service.getPendingTransactions(tripId);
});
