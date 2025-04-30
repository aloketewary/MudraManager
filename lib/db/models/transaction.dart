import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/db/models/category.dart'; // Import for linking
import 'package:mudra_manager/db/models/account.dart';  // Import for linking
import 'package:mudra_manager/db/models/tag.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Index() // Index for efficient querying/sorting by date
  late DateTime date; // Date and time of the transaction

  @Index() // Index amounts if you frequently query by them
  late double amount; // The transaction amount (always positive)

  @Index() // Index for easily filtering expenses vs income
  late bool isExpense; // true = Expense, false = Income

  String? description; // Optional user notes

  @Index() // Index for easily filtering expenses vs income
  late bool isTransfer; // true = Expense, false = Income

  // --- Links ---
  // Link to the Category this transaction belongs to
  @Index() // Indexing the link helps find transactions for a specific category
  final category = IsarLink<Category>();

  // Link to the Account this transaction affects
  @Index() // Indexing the link helps find transactions for a specific account
  final account = IsarLink<Account>();

  // --- Optional Additions ---
  // If implementing tags:
  @Index() // Index tags for finding transactions by tag
  final tags = IsarLinks<Tag>();

  // If implementing recurring transactions, maybe a link back to the template?
  final recurringTransactionSource = IsarLink<RecurringTransaction>();

  // Location data (optional)
  // double? latitude;
  // double? longitude;
  // ← Self‐link to the paired transaction
  final related = IsarLink<Transaction>();

  // Isar requires a default constructor
  Transaction();

  // Optional: Convenience constructor
  Transaction.create({
    required this.date,
    required this.amount,
    required this.isExpense,
    this.description,
    this.isTransfer = false
  });
}