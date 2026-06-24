import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

part 'trip.g.dart';

@collection
class Trip {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;

  @Index()
  late DateTime startDate;

  @Index()
  late DateTime endDate;

  @Index()
  late bool isActive;

  double? budget;

  /// Currency code for trip budget/expenses. Null = base currency.
  String? currencyCode;

  /// true = travel trip, false = split-only group
  late bool isTrip;

  late DateTime createdAt;

  final participants = IsarLinks<TripParticipant>();
  final transactions = IsarLinks<TripTransaction>();

  Trip();

  Trip.create({
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.budget,
    this.isTrip = true,
  }) : createdAt = DateTime.now();
}

@collection
class TripParticipant {
  Id id = Isar.autoIncrement;

  late String name;
  String? phone;
  String? email;

  /// True if this participant is the app owner (the user).
  /// Used to identify the user's share for analytics.
  bool isOwner = false;

  TripParticipant();

  TripParticipant.create({required this.name, this.phone, this.email, this.isOwner = false});
}

@collection
class SplitExpense {
  Id id = Isar.autoIncrement;

  late double amount;

  /// Currency code for this expense. Null = base currency.
  String? currencyCode;

  /// Amount converted to base currency at time of entry.
  double? convertedAmount;

  /// Exchange rate snapshot used.
  double? rateUsed;

  String? description;
  late DateTime date;

  SplitExpense();

  SplitExpense.create({
    required this.amount,
    this.description,
    required this.date,
  });
}

@collection
class TripTransaction {
  Id id = Isar.autoIncrement;

  /// Link to a main ledger transaction (used for trips).
  final transaction = IsarLink<Transaction>();

  /// Link to a group-only split expense (used for split groups).
  final splitExpense = IsarLink<SplitExpense>();

  final paidBy = IsarLink<TripParticipant>();

  @enumerated
  late SplitType splitType;

  late List<int> participantIds;
  late List<double> splitAmounts;

  /// Whether this transaction is a settlement payment (not a regular expense).
  bool isSettlement = false;

  late DateTime addedAt;

  TripTransaction();

  TripTransaction.create({
    required this.splitType,
    required this.participantIds,
    required this.splitAmounts,
  }) : addedAt = DateTime.now();

  /// Returns the amount from whichever source is linked.
  double? get resolvedAmount =>
      transaction.value?.amount ?? splitExpense.value?.amount;

  /// Returns the amount converted to a target currency.
  /// For trip display: if the transaction is in a different currency,
  /// falls back to convertedAmount (base) as best approximation.
  double? resolvedAmountIn(String? targetCurrency) {
    final txn = transaction.value;
    if (txn != null) {
      // Same currency or both null (base) → use raw amount
      if (txn.currencyCode == targetCurrency) return txn.amount;
      // Different currency → use base amount as approximation
      return txn.baseAmount;
    }
    final split = splitExpense.value;
    if (split != null) {
      if (split.currencyCode == targetCurrency) return split.amount;
      return split.convertedAmount ?? split.amount;
    }
    return null;
  }

  /// Returns the description from whichever source is linked.
  String? get resolvedDescription =>
      transaction.value?.description ?? splitExpense.value?.description;

  /// Returns the date from whichever source is linked.
  DateTime? get resolvedDate =>
      transaction.value?.date ?? splitExpense.value?.date;
}

enum SplitType { equal, percentage, custom, unequal }

@collection
class Settlement {
  Id id = Isar.autoIncrement;

  final trip = IsarLink<Trip>();
  final from = IsarLink<TripParticipant>();
  final to = IsarLink<TripParticipant>();

  late double amount;

  @Index()
  late bool isSettled;

  DateTime? settledAt;
  late DateTime createdAt;

  Settlement();

  Settlement.create({required this.amount, this.isSettled = false})
      : createdAt = DateTime.now();
}
