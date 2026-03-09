import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/trip.dart';

/// Balance info for a participant
class ParticipantBalance {
  final TripParticipant participant;
  final double balance; // Positive = owed to them, Negative = they owe

  ParticipantBalance(this.participant, this.balance);

  bool get owes => balance < 0;
  bool get isOwed => balance > 0;
  double get amount => balance.abs();
}

/// Service for calculating live settlement balances
class SettlementService {
  final Isar isar;

  SettlementService(this.isar);

  /// Calculate real-time balances for all participants in a trip
  Future<List<ParticipantBalance>> getLiveBalances(int tripId) async {
    final trip = await isar.trips.get(tripId);
    if (trip == null) return [];

    await trip.participants.load();
    await trip.transactions.load();

    // Initialize balances
    final balances = <int, double>{};
    for (final p in trip.participants) {
      balances[p.id] = 0.0;
    }

    // Calculate from trip transactions
    for (final tt in trip.transactions) {
      await tt.transaction.load();
      await tt.paidBy.load();

      final txn = tt.transaction.value;
      final payer = tt.paidBy.value;
      if (txn == null || payer == null) continue;

      final totalAmount = txn.amount;

      // Payer gets credited
      balances[payer.id] = (balances[payer.id] ?? 0) + totalAmount;

      // Split among participants
      for (int i = 0; i < tt.participantIds.length; i++) {
        final participantId = tt.participantIds[i];
        final splitAmount = tt.splitAmounts[i];
        balances[participantId] = (balances[participantId] ?? 0) - splitAmount;
      }
    }

    // Convert to list
    return trip.participants
        .map((p) => ParticipantBalance(p, balances[p.id] ?? 0.0))
        .where((pb) => pb.balance.abs() > 0.01) // Ignore tiny amounts
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // Owed first
  }

  /// Calculate simplified settlements (minimize transactions)
  Future<List<Settlement>> calculateOptimalSettlements(int tripId) async {
    final balances = await getLiveBalances(tripId);
    final settlements = <Settlement>[];

    final creditors = balances.where((b) => b.isOwed).toList();
    final debtors = balances.where((b) => b.owes).toList();

    int i = 0, j = 0;
    while (i < creditors.length && j < debtors.length) {
      final creditor = creditors[i];
      final debtor = debtors[j];

      final amount = [creditor.amount, debtor.amount].reduce((a, b) => a < b ? a : b);

      final settlement = Settlement.create(amount: amount)
        ..from.value = debtor.participant
        ..to.value = creditor.participant;

      settlements.add(settlement);

      creditors[i] = ParticipantBalance(creditor.participant, creditor.balance - amount);
      debtors[j] = ParticipantBalance(debtor.participant, debtor.balance + amount);

      if (creditors[i].amount < 0.01) i++;
      if (debtors[j].amount < 0.01) j++;
    }

    return settlements;
  }
}
