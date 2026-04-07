import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';

part 'transaction.g.dart';

/// Represents a financial transaction in the application.
///
/// This class is used to store details about individual financial events,
/// such as expenses, income, or transfers between accounts.
@collection
@JsonSerializable()
class Transaction {
  /// The unique identifier for this transaction.
  ///
  /// This is an auto-incrementing ID managed by Isar.
  Id id = Isar.autoIncrement;

  /// The date and time when the transaction occurred.
  ///
  /// Indexed for efficient querying and sorting by date.
  @Index()
  late DateTime date;

  /// The monetary value of the transaction.
  ///
  /// This amount is always stored as a positive value.
  /// The `isExpense` flag determines if it's an outgoing or incoming amount.
  /// Indexed for efficient querying by amount.
  @Index()
  late double amount;

  /// Indicates whether this transaction is an expense or income.
  ///
  /// - `true`: The transaction is an expense (money spent).
  /// - `false`: The transaction is an income (money received).
  /// Indexed for easy filtering of expenses versus income.
  @Index()
  late bool isExpense;

  String? description; // Optional user notes

  /// Indicates if this transaction was created from SMS auto-import
  bool? isFromSms;

  /// Link to SMS activity if created from SMS
  int? smsActivityId;

  /// Original currency code (e.g. "USD"). Null = base currency.
  String? currencyCode;

  /// Amount converted to base currency at transaction time.
  /// Null = same as [amount] (base currency transaction).
  double? convertedAmount;

  /// Exchange rate snapshot used at transaction time.
  /// e.g. 83.5 means 1 USD = 83.5 INR.
  double? rateUsed;

  /// The user's personal share of this transaction.
  /// Null = full amount belongs to the user (default for non-shared expenses).
  /// Set when the transaction is part of a split/shared expense.
  double? myShare;

  /// Whether this transaction is a shared/split expense.
  /// Used for UI tagging ("Shared", "You paid • Split").
  bool isSharedExpense = false;

  /// Whether this transaction is a settlement payment between people.
  /// Settlements affect account balance but NOT spending stats.
  @Index()
  bool isSettlement = false;

  /// Indicates whether this transaction is part of a transfer between accounts.
  ///
  /// - `true`: This transaction is part of an account transfer.
  /// - `false`: This is a regular expense or income transaction.
  @Index()
  late bool isTransfer;

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
    this.isTransfer = false,
    this.currencyCode,
    this.convertedAmount,
    this.rateUsed,
  });

  /// Returns amount in base currency (uses convertedAmount if available).
  double get baseAmount => convertedAmount ?? amount;

  /// Whether this transaction should be included in spending/income stats.
  /// False for settlements and transfers — they only affect balance.
  bool get affectsStats => !isSettlement && !isTransfer;

  /// Returns the user's effective share in base currency.
  /// Settlements return 0 (don't affect stats).
  /// Shared expenses return myShare.
  /// Regular expenses return full baseAmount.
  double get effectiveAmount {
    if (!affectsStats) return 0;
    return myShare ?? baseAmount;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
