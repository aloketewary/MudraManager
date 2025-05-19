import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/account.dart' show Account, AccountType;

class AccountBackup implements BackupAdapter<Account> {
  late final int id;
  final String name;
  final AccountType accountType;
  final double initialBalance;
  final int? colorValue;
  final String? accountNumber;
  final bool isActive;

  AccountBackup.fromAccount(Account account)
    : id = account.id,
      name = account.name,
      accountType = account.accountType,
      initialBalance = account.initialBalance,
      colorValue = account.colorValue,
      accountNumber = account.accountNumber,
      isActive = account.isActive;

  // Default constructor
  AccountBackup()
    : id = 0,
      // Provide default values for all final fields
      name = '',
      accountType = AccountType.cash,
      // Or any appropriate default
      initialBalance = 0.0,
      colorValue = null,
      accountNumber = null,
      isActive = true;

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'name': name,
    'accountType': accountType.index, // Store enum as index
    'initialBalance': initialBalance,
    'colorValue': colorValue,
    'accountNumber': accountNumber,
    'isActive': isActive,
  };

  @override
  Account fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final account =
        Account()
          ..id = json['id']
          ..name = json['name']
          ..accountType = AccountType.values[json['accountType'] as int]
          ..initialBalance = json['initialBalance']
          ..colorValue = json['colorValue'] as int?
          ..accountNumber = json['accountNumber'] as String?
          ..isActive = json['isActive'] as bool? ?? true; // Provide a default value

    return account;
  }
}
