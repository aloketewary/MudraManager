import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
// We will link Transactions back TO Accounts, but Account doesn't need a direct link *list*
// of transactions typically, as queries handle that.

part 'account.g.dart';

@collection
@JsonSerializable()
class Account {
  Id id = Isar.autoIncrement; // Auto-incrementing primary key

  @Index(type: IndexType.value, unique: true, caseSensitive: false) // Ensure unique names (case-insensitive)
  late String name; // e.g., "Bank ABC", "Wallet", "Credit Card XYZ"

  // Consider adding an 'Account Type' enum (e.g., Bank, Cash, Credit, EWallet)
  @enumerated
  late AccountType accountType;

  late double initialBalance; // Starting balance when the account was added

  int? colorValue;

  String? accountNumber;

  // A field to mark if the account is active or closed/hidden
  @Index() // Index for easily filtering active accounts
  bool isActive = true;

  // Maybe add: currency code/symbol if supporting multiple currencies

  // Isar requires a default constructor
  Account();

  // Optional: Convenience constructor
  Account.create({
    required this.name,
    this.initialBalance = 0.0,
    this.isActive = true,
  });

// Note: We don't store the 'currentBalance' here.
// Current balance is typically CALCULATED dynamically by summing:
// initialBalance + all related income transactions - all related expense transactions.
  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

// You might define an enum for AccountType outside the class:
enum AccountType { bank, cash, creditCard, eWallet, investment, other }