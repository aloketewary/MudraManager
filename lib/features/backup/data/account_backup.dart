import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:mudra_manager/features/backup/data/backable_model.dart';

/// Redacted account backup preparation failure. Never carries account data or
/// plugin exception text across the backup boundary.
class AccountBackupException implements Exception {
  final String category;

  const AccountBackupException(this.category);

  @override
  String toString() => 'Account backup unavailable: '
      '${AccountDataContract.redactedCategory(category)}';
}

/// Account backup adapter. The account number is marked as either portable
/// legacy/plaintext or opaque local ciphertext; restore always resolves it
/// through the local account contract before persistence.
class AccountBackup implements BackupAdapter<Account> {
  late final int id;
  final String name;
  final AccountType accountType;
  final double initialBalance;
  final int? colorValue;
  final String? accountNumber;
  final String? accountSuffixHash;
  final String? currencyCode;
  final int? statementDay;
  final int? dueDay;
  final double? creditLimit;
  final bool isActive;
  final bool isPrimary;
  final String accountNumberEncoding;

  AccountBackup.fromAccount(
    Account account, {
    String? accountNumberOverride,
    this.accountNumberEncoding = 'opaque',
  })  : id = account.id,
        name = account.name,
        accountType = account.accountType,
        initialBalance = account.initialBalance,
        colorValue = account.colorValue,
        accountNumber = accountNumberOverride ?? account.accountNumber,
        accountSuffixHash = account.accountSuffixHash,
        currencyCode = account.currencyCode,
        statementDay = account.statementDay,
        dueDay = account.dueDay,
        creditLimit = account.creditLimit,
        isActive = account.isActive,
        isPrimary = account.isPrimary;

  /// Export a local account as portable legacy data. Outer backup encryption
  /// protects this field; restore re-encrypts it with current local key.
  static Future<AccountBackup> reEncrypt(Account account) async {
    final resolution = await account.resolveAccountNumberStrict();
    if (resolution.isUnavailable) {
      throw AccountBackupException(
        resolution.errorCategory ?? 'account_number_unavailable',
      );
    }

    final resolved = AccountDataContract.copyAccount(account)
      ..accountNumber = resolution.resolvedValue
      ..accountSuffixHash = resolution.resolvedValue == null
          ? null
          : accountSuffixHashFor(resolution.resolvedValue!);
    return AccountBackup.fromAccount(
      resolved,
      accountNumberOverride: resolved.accountNumber,
      accountNumberEncoding: 'portable-plaintext',
    );
  }

  /// Preserve opaque ciphertext when export cannot resolve a local record.
  /// A different device/key will reject it safely during restore.
  static AccountBackup fromOpaqueAccount(Account account) =>
      AccountBackup.fromAccount(account, accountNumberEncoding: 'opaque');

  AccountBackup()
      : id = 0,
        name = '',
        accountType = AccountType.cash,
        initialBalance = 0.0,
        colorValue = null,
        accountNumber = null,
        accountSuffixHash = null,
        currencyCode = null,
        statementDay = null,
        dueDay = null,
        creditLimit = null,
        isActive = true,
        isPrimary = false,
        accountNumberEncoding = 'portable-plaintext';

  @override
  Map<String, dynamic> toBackupJson() => {
        'id': id,
        'name': name,
        'accountType': accountType.index,
        'initialBalance': initialBalance,
        'colorValue': colorValue,
        'accountNumber': accountNumber,
        'accountNumberEncoding': accountNumberEncoding,
        'accountSuffixHash': accountSuffixHash,
        'currencyCode': currencyCode,
        'statementDay': statementDay,
        'dueDay': dueDay,
        'creditLimit': creditLimit,
        'isActive': isActive,
        'isPrimary': isPrimary,
      };

  @override
  Account fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    final account = Account()
      ..id = json['id'] as int
      ..name = json['name'] as String? ?? ''
      ..accountType = AccountType.values[json['accountType'] as int]
      ..initialBalance = (json['initialBalance'] as num?)?.toDouble() ?? 0.0
      ..colorValue = json['colorValue'] as int?
      ..accountNumber = json['accountNumber'] as String?
      ..accountSuffixHash = json['accountSuffixHash'] as String?
      ..currencyCode = json['currencyCode'] as String?
      ..statementDay = json['statementDay'] as int?
      ..dueDay = json['dueDay'] as int?
      ..creditLimit = (json['creditLimit'] as num?)?.toDouble()
      ..isActive = json['isActive'] as bool? ?? true
      ..isPrimary = json['isPrimary'] as bool? ?? false;

    return account;
  }
}
