import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';

part 'recurring_bill.g.dart';

@collection
class RecurringBill {
  Id id = Isar.autoIncrement;

  late String name;
  late double amount;
  late DateTime dueDate;

  @enumerated
  late BillFrequency frequency;

  String? description;
  late bool isActive;
  DateTime? lastPaidDate;
  DateTime? nextDueDate;

  final category = IsarLink<Category>();
  final account = IsarLink<Account>();

  RecurringBill();

  RecurringBill.create({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.frequency,
    this.description,
    this.isActive = true,
  }) {
    nextDueDate = dueDate;
  }
}

enum BillFrequency { monthly, quarterly, yearly }
