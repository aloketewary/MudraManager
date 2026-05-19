import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Service for managing active trip mode and auto-association
class ActiveTripService {
  final Isar isar;

  ActiveTripService(this.isar);

  /// Get currently active trip (only one can be active)
  Future<Trip?> getActiveTrip() async {
    return await isar.trips.filter().isActiveEqualTo(true).findFirst().withDecryption();
  }

  /// Set a trip as active (deactivates others)
  Future<void> setActiveTrip(int tripId) async {
    await isar.writeTxn(() async {
      // Deactivate all trips
      final allTrips = await isar.trips.where().findAll().withDecryption();
      for (final trip in allTrips) {
        trip.isActive = false;
        trip.encryptFields();
        await isar.trips.put(trip);
      }

      // Activate selected trip
      final trip = await isar.trips.get(tripId).withDecryption();
      if (trip != null) {
        trip.isActive = true;
        trip.encryptFields();
        await isar.trips.put(trip);
      }
    });
  }

  /// Deactivate trip mode
  Future<void> deactivateTripMode() async {
    await isar.writeTxn(() async {
      final allTrips = await isar.trips.where().findAll().withDecryption();
      for (final trip in allTrips) {
        trip.isActive = false;
        trip.encryptFields();
        await isar.trips.put(trip);
      }
    });
  }

  /// Check if transaction should be suggested for active trip
  Future<Trip?> shouldSuggestForTrip(Transaction txn) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip == null) return null;

    // Check if transaction date is within trip dates
    if (txn.date.isAfter(activeTrip.startDate) &&
        txn.date.isBefore(activeTrip.endDate.add(const Duration(days: 1)))) {
      return activeTrip;
    }

    return null;
  }

  /// Get pending transactions for a trip (within date range, not yet added)
  Future<List<Transaction>> getPendingTransactions(int tripId) async {
    final trip = await isar.trips.get(tripId).withDecryption();
    if (trip == null) return [];

    // Get all trip transactions
    await trip.transactions.load();
    final addedTxnIds = trip.transactions.map((tt) => tt.transaction.value?.id).toSet();

    // Get all transactions in date range
    final allTxns = await isar.transactions
        .filter()
        .dateBetween(trip.startDate, trip.endDate.add(const Duration(days: 1)))
        .findAll()
        .withDecryption();

    // Return only those not yet added to trip
    return allTxns.where((txn) => !addedTxnIds.contains(txn.id)).toList();
  }
}
