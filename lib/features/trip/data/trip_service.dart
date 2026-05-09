import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/category_seeder.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

class TripService {
  final IsarService isarService;
  final GamificationService? gamificationService;

  TripService(this.isarService, this.gamificationService);

  Future<void> createTrip(Trip trip, List<TripParticipant> participants) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.tripParticipants.putAll(participants);
      trip.participants.addAll(participants);
      await isar.trips.put(trip);
      await trip.participants.save();
    });
    await gamificationService?.track(GamificationEvent.tripCreated);
  }

  Future<List<Trip>> getAllTrips() async {
    final isar = await isarService.getInstance();
    return await isar.trips.where().sortByCreatedAtDesc().findAll();
  }

  /// Loads summary data for a trip (participants, total spent, owner share).
  Future<TripSummary> getTripSummary(Trip trip) async {
    await trip.participants.load();
    await trip.transactions.load();

    final participants = trip.participants.toList();
    final txns = trip.transactions.toList();

    double totalSpent = 0;
    double ownerPaid = 0;
    double ownerOwes = 0;

    // Find owner participant
    final owner = participants.where((p) => p.isOwner).firstOrNull;
    final ownerId = owner?.id;

    for (final tripTxn in txns) {
      await tripTxn.transaction.load();
      await tripTxn.splitExpense.load();
      await tripTxn.paidBy.load();

      final amount = tripTxn.resolvedAmountIn(trip.currencyCode) ?? 0;
      totalSpent += amount;

      if (ownerId != null) {
        // Owner paid this expense
        if (tripTxn.paidBy.value?.id == ownerId) {
          ownerPaid += amount;
        }
        // Owner's share of this expense
        final idx = tripTxn.participantIds.indexOf(ownerId);
        if (idx >= 0 && idx < tripTxn.splitAmounts.length) {
          ownerOwes += tripTxn.splitAmounts[idx];
        }
      }
    }

    // Net: positive = others owe you, negative = you owe others
    final netBalance = ownerPaid - ownerOwes;

    return TripSummary(
      participantCount: participants.length,
      totalSpent: totalSpent,
      ownerShare: ownerOwes,
      ownerPaid: ownerPaid,
      netBalance: netBalance,
    );
  }

  Future<List<Trip>> getActiveTrips() async {
    final isar = await isarService.getInstance();
    return await isar.trips
        .filter()
        .isActiveEqualTo(true)
        .sortByStartDateDesc()
        .findAll();
  }

  Future<Trip?> getTripById(int id) async {
    final isar = await isarService.getInstance();
    final trip = await isar.trips.get(id);
    await trip?.participants.load();
    await trip?.transactions.load();
    for (final tripTxn in trip?.transactions ?? <TripTransaction>[]) {
      await tripTxn.transaction.load();
      await tripTxn.splitExpense.load();
      await tripTxn.paidBy.load();
      await tripTxn.transaction.value?.category.load();
    }
    return trip;
  }

  Future<void> addTransactionToTrip(
    int tripId,
    Transaction transaction,
    int paidById,
    SplitType splitType,
    List<int> participantIds,
    List<double> splitAmounts,
  ) async {
    final isar = await isarService.getInstance();

    // Set shared expense metadata — find the owner's share
    if (participantIds.length > 1) {
      transaction.isSharedExpense = true;
      for (int i = 0; i < participantIds.length; i++) {
        final p = await isar.tripParticipants.get(participantIds[i]);
        if (p != null && p.isOwner) {
          transaction.myShare = splitAmounts[i];
          break;
        }
      }
    }

    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);

      final tripTxn = TripTransaction.create(
        splitType: splitType,
        participantIds: participantIds,
        splitAmounts: splitAmounts,
      );
      tripTxn.transaction.value = transaction;
      final paidBy = await isar.tripParticipants.get(paidById);
      if (paidBy != null) {
        tripTxn.paidBy.value = paidBy;
      }
      await isar.tripTransactions.put(tripTxn);
      await tripTxn.transaction.save();
      await tripTxn.paidBy.save();

      final trip = await isar.trips.get(tripId);
      trip?.transactions.add(tripTxn);
      await trip?.transactions.save();
    });
  }

  Future<void> addSplitExpenseToTrip(
    int tripId,
    SplitExpense expense,
    int paidById,
    SplitType splitType,
    List<int> participantIds,
    List<double> splitAmounts,
  ) async {
    final isar = await isarService.getInstance();

    // Find the owner participant to calculate myShare
    final paidBy = await isar.tripParticipants.get(paidById);
    final allParticipants = await Future.wait(
      participantIds.map((id) => isar.tripParticipants.get(id)),
    );
    final owner = allParticipants
        .where((p) => p != null && p.isOwner)
        .firstOrNull;
    final ownerId = owner?.id;

    // Calculate owner's share. Fallback: if no owner flag (old trips),
    // assume first participant is the user and use equal share.
    double ownerShare;
    if (ownerId != null) {
      final idx = participantIds.indexOf(ownerId);
      ownerShare = (idx >= 0 && idx < splitAmounts.length)
          ? splitAmounts[idx]
          : expense.amount / participantIds.length;
    } else {
      // No owner marked — fallback to equal share
      ownerShare = splitAmounts.isNotEmpty
          ? splitAmounts.first
          : expense.amount / participantIds.length;
    }
    final isOwnerPayer = ownerId != null
        ? paidBy?.isOwner == true
        : paidById == participantIds.first; // fallback: first participant

    // Look up primary account for ledger transactions
    final primaryAccount = await isar.accounts
        .filter()
        .isPrimaryEqualTo(true)
        .isActiveEqualTo(true)
        .findFirst() ??
        await isar.accounts.filter().isActiveEqualTo(true).findFirst();

    // Always create a main ledger transaction so it appears in
    // dashboard/analytics. Uses myShare for the user's portion.
    final trip = await isar.trips.get(tripId);
    final categoryName = trip?.isTrip == true ? 'Trip Expense' : 'Shared Expense';
    final systemCategory = await CategorySeeder.getSystemCategory(isar, categoryName);

    final ledgerTxn = Transaction.create(
      date: expense.date,
      amount: isOwnerPayer ? expense.amount : 0,
      isExpense: true,
      description: expense.description,
      isTransfer: false,
    )
      ..myShare = ownerShare
      ..isSharedExpense = participantIds.length > 1;

    if (systemCategory != null) ledgerTxn.category.value = systemCategory;
    if (primaryAccount != null) ledgerTxn.account.value = primaryAccount;

    if (expense.currencyCode != null) {
      ledgerTxn.currencyCode = expense.currencyCode;
      ledgerTxn.convertedAmount = isOwnerPayer
          ? (expense.convertedAmount ?? expense.amount)
          : 0;
    }

    await isar.writeTxn(() async {
      await isar.splitExpenses.put(expense);
      await isar.transactions.put(ledgerTxn);
      await ledgerTxn.category.save();
      await ledgerTxn.account.save();

      final tripTxn = TripTransaction.create(
        splitType: splitType,
        participantIds: participantIds,
        splitAmounts: splitAmounts,
      );
      tripTxn.splitExpense.value = expense;
      tripTxn.transaction.value = ledgerTxn;
      if (paidBy != null) {
        tripTxn.paidBy.value = paidBy;
      }
      await isar.tripTransactions.put(tripTxn);
      await tripTxn.splitExpense.save();
      await tripTxn.paidBy.save();
      await tripTxn.transaction.save();

      final trip = await isar.trips.get(tripId);
      trip?.transactions.add(tripTxn);
      await trip?.transactions.save();
    });
  }

  Future<Map<String, Map<String, double>>> calculateSettlements(
    int tripId,
  ) async {
    final isar = await isarService.getInstance();
    final trip = await isar.trips.get(tripId);
    if (trip == null) return {};

    await trip.transactions.load();
    await trip.participants.load();

    final balances = <int, double>{};
    final participantMap = {for (var p in trip.participants) p.id: p.name};

    for (var tripTxn in trip.transactions.toList()) {
      await tripTxn.transaction.load();
      await tripTxn.splitExpense.load();
      await tripTxn.paidBy.load();

      final amount = tripTxn.resolvedAmountIn(trip.currencyCode);
      final paidBy = tripTxn.paidBy.value;

      if (amount == null || paidBy == null) continue;

      final paidById = paidBy.id;

      balances[paidById] = (balances[paidById] ?? 0) + amount;

      final participantIds = tripTxn.participantIds;
      final splitAmounts = tripTxn.splitAmounts;

      for (var i = 0; i < participantIds.length; i++) {
        final participantId = participantIds[i];
        final share = splitAmounts[i];
        balances[participantId] = (balances[participantId] ?? 0) - share;
      }
    }

    final settlements = <String, Map<String, double>>{};

    balances.forEach((id, balance) {
      if (balance > 0.01) {
        balances.forEach((otherId, otherBalance) {
          if (otherId != id && otherBalance < -0.01) {
            final settleAmount = balance < -otherBalance
                ? balance
                : -otherBalance;
            final fromName = participantMap[otherId] ?? 'Unknown';
            final toName = participantMap[id] ?? 'Unknown';
            settlements.putIfAbsent(fromName, () => {});
            settlements[fromName]![toName] =
                (settlements[fromName]![toName] ?? 0) + settleAmount;
          }
        });
      }
    });

    return settlements;
  }

  /// Records a settlement payment between two participants.
  /// Creates a SplitExpense where [fromId] pays [toId] the given [amount].
  /// This adjusts balances so calculateSettlements reflects the payment.
  Future<void> recordSettlement({
    required int tripId,
    required int fromId,
    required int toId,
    required double amount,
    String? currencyCode,
  }) async {
    final isar = await isarService.getInstance();

    final fromP = await isar.tripParticipants.get(fromId);
    final toP = await isar.tripParticipants.get(toId);

    final expense = SplitExpense.create(
      amount: amount,
      description: 'Settlement',
      date: DateTime.now(),
    );
    if (currencyCode != null) {
      expense.currencyCode = currencyCode;
    }

    // Look up primary account
    final primaryAccount = await isar.accounts
        .filter()
        .isPrimaryEqualTo(true)
        .isActiveEqualTo(true)
        .findFirst() ??
        await isar.accounts.filter().isActiveEqualTo(true).findFirst();

    // Create main ledger settlement transaction.
    // If owner pays someone → expense. If owner receives → income.
    // Fallback: if no isOwner flag (old trips), treat "from" as expense.
    final fromIsOwner = fromP?.isOwner == true;
    final toIsOwner = toP?.isOwner == true;
    final hasOwner = fromIsOwner || toIsOwner;

    // Determine direction: expense (paying out) or income (receiving)
    final isExpense = fromIsOwner || !hasOwner; // default to expense for old trips
    final catName = isExpense ? 'Settlement' : 'Settlement Received';
    final desc = isExpense
        ? 'Settlement to ${toP?.name ?? "Unknown"}'
        : 'Settlement from ${fromP?.name ?? "Unknown"}';

    final systemCat = await CategorySeeder.getSystemCategory(isar, catName);
    final ledgerTxn = Transaction.create(
      date: DateTime.now(),
      amount: amount,
      isExpense: isExpense,
      description: desc,
    )
      ..isSettlement = true
      ..isSharedExpense = true;
    if (systemCat != null) ledgerTxn.category.value = systemCat;
    if (primaryAccount != null) ledgerTxn.account.value = primaryAccount;
    if (currencyCode != null) ledgerTxn.currencyCode = currencyCode;

    final tripTxn = TripTransaction.create(
      splitType: SplitType.equal,
      participantIds: [toId],
      splitAmounts: [amount],
    );

    await isar.writeTxn(() async {
      await isar.splitExpenses.put(expense);
      await isar.transactions.put(ledgerTxn);
      await ledgerTxn.category.save();
      await ledgerTxn.account.save();

      tripTxn.splitExpense.value = expense;
      tripTxn.transaction.value = ledgerTxn;
      if (fromP != null) tripTxn.paidBy.value = fromP;

      await isar.tripTransactions.put(tripTxn);
      await tripTxn.splitExpense.save();
      await tripTxn.paidBy.save();
      await tripTxn.transaction.save();

      final trip = await isar.trips.get(tripId);
      trip?.transactions.add(tripTxn);
      await trip?.transactions.save();
    });
  }

  Future<void> archiveTrip(int tripId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final trip = await isar.trips.get(tripId);
      if (trip != null) {
        trip.isActive = false;
        await isar.trips.put(trip);
      }
    });
  }

  Future<void> removeTripTransaction(int tripId, int tripTransactionId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final trip = await isar.trips.get(tripId);
      if (trip == null) return;

      await trip.transactions.load();
      final tripTxn = trip.transactions
          .where((t) => t.id == tripTransactionId)
          .firstOrNull;

      if (tripTxn != null) {
        await tripTxn.splitExpense.load();
        await tripTxn.transaction.load();
        if (tripTxn.splitExpense.value != null) {
          await isar.splitExpenses.delete(tripTxn.splitExpense.value!.id);
        }
        // Delete linked main ledger transaction
        if (tripTxn.transaction.value != null) {
          await isar.transactions.delete(tripTxn.transaction.value!.id);
        }
      }

      trip.transactions.removeWhere((t) => t.id == tripTransactionId);
      await trip.transactions.save();

      await isar.tripTransactions.delete(tripTransactionId);
    });
  }

  Future<String?> getTripNameByTransactionId(int transactionId) async {
    final isar = await isarService.getInstance();
    final tripTxn = await isar.tripTransactions
        .filter()
        .transaction((q) => q.idEqualTo(transactionId))
        .findFirst();

    if (tripTxn == null) return null;

    final trip = await isar.trips
        .filter()
        .transactions((q) => q.idEqualTo(tripTxn.id))
        .findFirst();

    return trip?.name;
  }

  Future<Map<int, String>> getTripNamesByTransactionIds(List<int> transactionIds) async {
    if (transactionIds.isEmpty) return {};
    
    final isar = await isarService.getInstance();
    final tripTxns = await isar.tripTransactions
        .filter()
        .anyOf(transactionIds, (q, id) => q.transaction((tq) => tq.idEqualTo(id)))
        .findAll();

    // Map: TripTransaction ID -> Transaction ID
    final tripTxnToTxnIdMap = <int, int>{};
    for (var tripTxn in tripTxns) {
      await tripTxn.transaction.load();
      final txnId = tripTxn.transaction.value?.id;
      if (txnId != null) {
        tripTxnToTxnIdMap[tripTxn.id] = txnId;
      }
    }

    final tripTxnIds = tripTxnToTxnIdMap.keys.toList();
    final trips = await isar.trips
        .filter()
        .anyOf(tripTxnIds, (q, id) => q.transactions((tq) => tq.idEqualTo(id)))
        .findAll();

    final tripMap = <int, String>{};
    for (var trip in trips) {
      await trip.transactions.load();
      // OPTIMIZATION: Avoid loading 'transaction' link for every tripTxn in the trip.
      // We already have the mapping for the transactions we care about.
      for (var tripTxn in trip.transactions) {
        final txnId = tripTxnToTxnIdMap[tripTxn.id];
        if (txnId != null) {
          tripMap[txnId] = trip.name;
        }
      }
    }

    return tripMap;
  }

  Future<void> removeTransactionFromTrip(int transactionId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final tripTxn = await isar.tripTransactions
          .filter()
          .transaction((q) => q.idEqualTo(transactionId))
          .findFirst();

      if (tripTxn == null) return;

      // Reset shared expense fields on the main transaction
      final txn = await isar.transactions.get(transactionId);
      if (txn != null) {
        txn.myShare = null;
        txn.isSharedExpense = false;
        await isar.transactions.put(txn);
      }

      final trip = await isar.trips
          .filter()
          .transactions((q) => q.idEqualTo(tripTxn.id))
          .findFirst();

      if (trip != null) {
        await trip.transactions.load();
        trip.transactions.removeWhere((t) => t.id == tripTxn.id);
        await trip.transactions.save();
      }

      await isar.tripTransactions.delete(tripTxn.id);
    });
  }

  Future<void> updateTrip(
    Trip trip, {
    required List<TripParticipant> newParticipants,
    required bool clearTransactions,
  }) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      // 1. Update Trip Details
      await isar.trips.put(trip);

      // 2. Update Participants
      // Save all participants (updates existing ones, creates new ones)
      await isar.tripParticipants.putAll(newParticipants);

      // Update the links: Load current, clear, and add new list
      await trip.participants.load();
      trip.participants.clear();
      trip.participants.addAll(newParticipants);
      await trip.participants.save();

      // 3. Clear Transactions if requested (Date change logic)
      if (clearTransactions) {
        await trip.transactions.load();
        final txnsToDelete = trip.transactions.toList();

        // Delete the TripTransaction objects to prevent orphans
        if (txnsToDelete.isNotEmpty) {
          await isar.tripTransactions.deleteAll(
            txnsToDelete.map((e) => e.id).toList(),
          );
        }

        // Clear the links
        trip.transactions.clear();
        await trip.transactions.save();
      }
    });
  }
}

class TripSummary {
  final int participantCount;
  final double totalSpent;
  final double ownerShare;
  final double ownerPaid;
  final double netBalance;

  const TripSummary({
    required this.participantCount,
    required this.totalSpent,
    required this.ownerShare,
    required this.ownerPaid,
    required this.netBalance,
  });

  bool get youOwe => netBalance < -0.01;
  bool get youGet => netBalance > 0.01;
  bool get settled => netBalance.abs() < 0.01 && totalSpent > 0;
}
