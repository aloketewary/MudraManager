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
  }) : createdAt = DateTime.now();
}

@collection
class TripParticipant {
  Id id = Isar.autoIncrement;

  late String name;
  String? phone;
  String? email;

  TripParticipant();

  TripParticipant.create({required this.name, this.phone, this.email});
}

@collection
class TripTransaction {
  Id id = Isar.autoIncrement;

  final transaction = IsarLink<Transaction>();
  final paidBy = IsarLink<TripParticipant>();

  @enumerated
  late SplitType splitType;

  late List<int> participantIds;
  late List<double> splitAmounts;

  late DateTime addedAt;

  TripTransaction();

  TripTransaction.create({
    required this.splitType,
    required this.participantIds,
    required this.splitAmounts,
  }) : addedAt = DateTime.now();
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
