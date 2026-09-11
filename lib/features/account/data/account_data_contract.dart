import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';

/// Redacted failure raised when account consumers cannot use the crypto key.
///
/// Account IDs, stored values, and plugin exception text never cross this
/// boundary. Providers surface this as an actionable async error.
class AccountReadinessException implements Exception {
  final String category;

  const AccountReadinessException(this.category);

  @override
  String toString() => 'Account data unavailable: '
      '${AccountDataContract.redactedCategory(category)}';
}

/// Safe account result shared by active, all, primary, and direct readers.
///
/// [account] is a detached presentation-safe copy. Its accountNumber contains
/// only the masked display value; it never contains storage ciphertext or the
/// resolved full account number. Matching code must use [resolution] or
/// accountSuffixHash inside its own boundary.
class AccountReadResult {
  final Account account;
  final AccountNumberResolution resolution;

  const AccountReadResult({required this.account, required this.resolution});

  bool get isAvailable =>
      resolution.isResolved ||
      resolution.status == AccountNumberResolutionStatus.nullOrEmpty;
}

/// Field-free account projection for link/count/balance-only paths.
///
/// It deliberately omits [Account.accountNumber] and suffix metadata. L-role
/// services can use this value for aggregation without carrying a storage
/// model into UI, matching, or account persistence code.
class AccountLinkProjection {
  final int id;
  final AccountType accountType;
  final double initialBalance;
  final String? currencyCode;
  final bool isActive;
  final bool isPrimary;

  const AccountLinkProjection({
    required this.id,
    required this.accountType,
    required this.initialBalance,
    required this.currencyCode,
    required this.isActive,
    required this.isPrimary,
  });

  factory AccountLinkProjection.fromStored(Account account) {
    return AccountLinkProjection(
      id: account.id,
      accountType: account.accountType,
      initialBalance: account.initialBalance,
      currencyCode: account.currencyCode,
      isActive: account.isActive,
      isPrimary: account.isPrimary,
    );
  }
}

enum AccountWriteStatus {
  success,
  duplicateName,
  duplicateNumber,
  duplicateResolutionFailed,
  readinessFailed,
  encryptionFailed,
  persistenceFailed,
}

class AccountWriteResult {
  final AccountWriteStatus status;
  final String? errorCategory;

  const AccountWriteResult._(this.status, [this.errorCategory]);

  const AccountWriteResult.success() : this._(AccountWriteStatus.success);

  bool get succeeded => status == AccountWriteStatus.success;
}

/// Prepared account for restore. [account] is safe to persist locally; it
/// never contains plaintext account-number data after successful preparation.
class AccountRestoreResult {
  final Account? account;
  final String? errorCategory;

  const AccountRestoreResult.success(this.account) : errorCategory = null;

  const AccountRestoreResult.failure(this.errorCategory) : account = null;

  bool get succeeded => account != null;
}

/// Presentation-only account projection. It owns account-number formatting for
/// every account UI and output surface. [account] is detached and safe even
/// when caller accidentally supplies a storage-shaped value.
class SafeAccountPresentation {
  final Account account;
  final String accountNumber;

  const SafeAccountPresentation({
    required this.account,
    required this.accountNumber,
  });

  factory SafeAccountPresentation.fromAccount(Account source) {
    final safe = AccountDataContract.copyAccount(source);
    final display = formatAccountNumber(source.accountNumber);
    safe.accountNumber = display;
    return SafeAccountPresentation(account: safe, accountNumber: display);
  }

  /// Mask valid values to suffix; reject ciphertext, short values, and
  /// already-unsafe placeholders. Safe provider values pass through unchanged.
  static String formatAccountNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.startsWith('ENC:')) return '••••';
    if (trimmed == '••••' || trimmed == '****') return '••••';
    if (trimmed.startsWith('•••• ')) {
      final suffix = trimmed.substring(5).trim();
      return suffix.length == 4 ? '•••• $suffix' : '••••';
    }
    if (trimmed.startsWith('****')) {
      final suffix = trimmed.substring(4).trim();
      return suffix.length == 4 ? '•••• $suffix' : '••••';
    }
    if (trimmed.length < 4) return '••••';
    return '•••• ${trimmed.substring(trimmed.length - 4)}';
  }
}

/// Single account read/write boundary for provider/UI-facing account data.
class AccountDataContract {
  AccountDataContract._();

  /// Strictly prepare, validate, and persist one account. No caller-owned
  /// model is mutated; crypto and duplicate checks finish before one atomic put.
  static Future<AccountWriteResult> writeAccount(
    Isar isar,
    Account draft, {
    required String accountNumber,
  }) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) {
      return AccountWriteResult._(
        AccountWriteStatus.readinessFailed,
        readiness.errorCategory ?? 'encryption_unavailable',
      );
    }

    final normalizedNumber = accountNumber.trim();
    final current = draft.id == Isar.autoIncrement
        ? null
        : await isar.accounts.get(draft.id);

    final existingName =
        await isar.accounts.filter().nameEqualTo(draft.name).findFirst();
    if (existingName != null && existingName.id != draft.id) {
      return const AccountWriteResult._(AccountWriteStatus.duplicateName);
    }

    String? numberForWrite = normalizedNumber.isEmpty ? null : normalizedNumber;
    if (current != null && normalizedNumber.isNotEmpty) {
      final currentResolution = await current.resolveAccountNumberStrict();
      if (normalizedNumber == currentResolution.display) {
        numberForWrite = current.accountNumber;
      }
    }

    final candidatePlaintext = await _plainAccountNumber(numberForWrite);
    if (numberForWrite != null && candidatePlaintext == null) {
      return const AccountWriteResult._(
        AccountWriteStatus.duplicateResolutionFailed,
        'account_number_unavailable',
      );
    }

    if (candidatePlaintext != null && candidatePlaintext.isNotEmpty) {
      final allAccounts = await isar.accounts.where().findAll();
      for (final stored in allAccounts) {
        if (stored.id == draft.id) continue;
        final storedResolution = await stored.resolveAccountNumberStrict();
        if (storedResolution.isUnavailable) {
          final suffixMatches = stored.accountSuffixHash != null &&
              stored.matchesSuffix(_lastFour(candidatePlaintext));
          if (suffixMatches) {
            return const AccountWriteResult._(
              AccountWriteStatus.duplicateResolutionFailed,
              'duplicate_resolution_failed',
            );
          }
          continue;
        }
        if (storedResolution.resolvedValue == candidatePlaintext) {
          return const AccountWriteResult._(AccountWriteStatus.duplicateNumber);
        }
      }
    }

    final prepared = _copyAccount(draft)..accountNumber = numberForWrite;
    final preparation = await prepared.prepareStrictWrite();
    if (!preparation.succeeded) {
      return AccountWriteResult._(
        AccountWriteStatus.encryptionFailed,
        preparation.errorCategory ?? 'encryption_failed',
      );
    }
    prepared.applyStrictWrite(preparation);

    try {
      await isar.writeTxn(() async {
        await isar.accounts.put(prepared);
      });
      return const AccountWriteResult.success();
    } catch (_) {
      return const AccountWriteResult._(
        AccountWriteStatus.persistenceFailed,
        'persistence_failed',
      );
    }
  }

  static Future<String?> _plainAccountNumber(String? value) async {
    if (value == null || value.isEmpty) return null;
    if (!FieldEncryptionService.isEncrypted(value)) return value;
    final result = await FieldEncryptionService.decryptStrict(value);
    return result.isResolved ? result.plaintext : null;
  }

  static String _lastFour(String value) =>
      value.length >= 4 ? value.substring(value.length - 4) : value;

  /// Detached draft copy for forms. Safe provider models never get mutated on
  /// failed saves, preserving input and retry behavior.
  static Account copyAccount(Account? source) {
    if (source == null) return Account();
    return _copyAccount(source);
  }

  static Account _copyAccount(Account source) {
    return Account()
      ..id = source.id
      ..name = source.name
      ..accountType = source.accountType
      ..initialBalance = source.initialBalance
      ..colorValue = source.colorValue
      ..accountNumber = source.accountNumber
      ..accountSuffixHash = source.accountSuffixHash
      ..currencyCode = source.currencyCode
      ..statementDay = source.statementDay
      ..dueDay = source.dueDay
      ..creditLimit = source.creditLimit
      ..isActive = source.isActive
      ..isPrimary = source.isPrimary;
  }

  /// Read only non-sensitive account fields for L-role services.
  static Future<List<AccountLinkProjection>> linkProjections(
    Isar isar, {
    bool activeOnly = false,
  }) async {
    final stored = activeOnly
        ? await isar.accounts.filter().isActiveEqualTo(true).findAll()
        : await isar.accounts.where().findAll();
    return stored.map(AccountLinkProjection.fromStored).toList(growable: false);
  }

  /// Fetch relation identity for a link-only writer. Returned account must not
  /// be inspected or persisted through the accounts collection by caller.
  static Future<Account?> relationById(Isar isar, int accountId) {
    return isar.accounts.get(accountId);
  }

  /// Resolve account relation identity for a link-only primary-account writer.
  static Future<Account?> primaryRelation(Isar isar) async {
    final primary = await isar.accounts
        .filter()
        .isPrimaryEqualTo(true)
        .isActiveEqualTo(true)
        .findFirst();
    return primary ?? isar.accounts.filter().isActiveEqualTo(true).findFirst();
  }

  /// Redact failure categories to a fixed allow-list. Callers may safely use
  /// this for logs, errors, notification text, and restore diagnostics.
  static String redactedCategory(String? category) {
    const allowed = <String>{
      'account_number_unavailable',
      'account_write_failed',
      'backup_creation_failed',
      'duplicate_resolution_failed',
      'encryption_failed',
      'encryption_unavailable',
      'initialization_failed',
      'key_mismatch',
      'malformed_ciphertext',
      'malformed_plaintext',
      'migration_failed',
      'persistence_failed',
      'restore_failed',
    };
    return category != null && allowed.contains(category)
        ? category
        : 'account_data_unavailable';
  }

  /// Stable account diagnostic. Includes only permitted account identity and a
  /// fixed category; never interpolates exception, value, or key material.
  static String redactedFailure({
    required int accountId,
    required String? category,
  }) {
    return 'accountId=$accountId category=${redactedCategory(category)}';
  }

  /// Redact account-unsafe text before it reaches notification/widget output.
  /// Account names and business labels remain unchanged; opaque ciphertext is
  /// never allowed to cross an output boundary.
  static String safeOutputText(String value) {
    if (!value.contains('ENC:')) return value;
    return value.replaceAll(RegExp(r'ENC:[^\s,;})"\]]+'), '••••');
  }

  /// Safe output payload for account-linked notification/widget boundaries.
  static Map<String, dynamic> safeOutputPayload(Map<String, dynamic> payload) {
    dynamic sanitize(dynamic value) {
      if (value is String) return safeOutputText(value);
      if (value is Map) {
        return value.map(
          (key, nested) => MapEntry(key, sanitize(nested)),
        );
      }
      if (value is Iterable) return value.map(sanitize).toList(growable: false);
      return value;
    }

    return Map<String, dynamic>.from(sanitize(payload) as Map);
  }

  /// Resolve one stored account after shared readiness.
  static Future<AccountReadResult> resolveAccount(Account stored) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) {
      throw AccountReadinessException(
        readiness.errorCategory ?? 'encryption_unavailable',
      );
    }

    final resolution = await stored.resolveAccountNumberStrict();
    return AccountReadResult(
      account: _safeCopy(stored, resolution),
      resolution: resolution,
    );
  }

  /// Resolve collection while preserving Isar query order and every
  /// non-sensitive field. Per-record crypto failures become safe unavailable
  /// results; global readiness failure remains an async error.
  static Future<List<AccountReadResult>> resolveAccounts(
    Iterable<Account> stored,
  ) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) {
      throw AccountReadinessException(
        readiness.errorCategory ?? 'encryption_unavailable',
      );
    }
    return Future.wait(stored.map(_resolveReadyAccount));
  }

  static Future<AccountReadResult> _resolveReadyAccount(Account stored) async {
    final resolution = await stored.resolveAccountNumberStrict();
    return AccountReadResult(
      account: _safeCopy(stored, resolution),
      resolution: resolution,
    );
  }

  /// Return detached safe accounts for legacy provider signatures.
  static Future<List<Account>> safeAccounts(Iterable<Account> stored) async {
    final results = await resolveAccounts(stored);
    return results.map((result) => result.account).toList(growable: true);
  }

  /// Resolve a direct account lookup without allowing a raw Isar model to
  /// escape to UI, matching, or mutation callers.
  static Future<Account?> safeAccount(Account? stored) async {
    if (stored == null) return null;
    return (await resolveAccount(stored)).account;
  }

  /// Prepare restored account data for this device's current field key.
  /// Legacy plaintext and ciphertext decryptable by the current key are
  /// resolved inside this boundary, then encrypted afresh before local put.
  /// Foreign or malformed ciphertext returns a redacted failure and leaves
  /// the source/storage record untouched.
  static Future<AccountRestoreResult> prepareRestoredAccount(
    Account source,
  ) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) {
      return AccountRestoreResult.failure(
        readiness.errorCategory ?? 'encryption_unavailable',
      );
    }

    final resolution = await source.resolveAccountNumberStrict();
    if (resolution.status == AccountNumberResolutionStatus.nullOrEmpty) {
      final prepared = _copyAccount(source)
        ..accountNumber = null
        ..accountSuffixHash = null;
      return AccountRestoreResult.success(prepared);
    }
    if (!resolution.isResolved || resolution.resolvedValue == null) {
      return AccountRestoreResult.failure(
        resolution.errorCategory ?? 'account_number_unavailable',
      );
    }

    final prepared = _copyAccount(source)
      ..accountNumber = resolution.resolvedValue;
    final encryption = await prepared.prepareStrictWrite();
    if (!encryption.succeeded) {
      return AccountRestoreResult.failure(
        encryption.errorCategory ?? 'encryption_failed',
      );
    }
    prepared.applyStrictWrite(encryption);
    return AccountRestoreResult.success(prepared);
  }

  /// Update primary flags without materializing a presentation account. Raw
  /// account-number storage remains opaque throughout transaction.
  static Future<void> setPrimaryMetadata(Isar isar, int accountId) async {
    await isar.writeTxn(() async {
      final current =
          await isar.accounts.filter().isPrimaryEqualTo(true).findAll();
      for (final account in current) {
        account.isPrimary = false;
      }
      await isar.accounts.putAll(current);
      final selected = await isar.accounts.get(accountId);
      if (selected != null) {
        selected.isPrimary = true;
        await isar.accounts.put(selected);
      }
    });
  }

  /// Preserve startup primary normalization as a contract-owned metadata
  /// operation. No account-number content is inspected or replaced.
  static Future<void> normalizePrimaryMetadata(Isar isar) async {
    final accounts = await isar.accounts.where().findAll();
    if (accounts.isEmpty || accounts.any((account) => account.isPrimary)) {
      return;
    }
    final first = accounts.where((account) => account.isActive).firstOrNull;
    if (first == null) return;
    await isar.writeTxn(() async {
      final stored = await isar.accounts.get(first.id);
      if (stored == null) return;
      stored.isPrimary = true;
      await isar.accounts.put(stored);
    });
  }

  /// Mutate only a raw stored record inside one transaction. This helper is
  /// deliberately field-agnostic: callers can patch IDs/flags/metadata while
  /// preserving the opaque encrypted account-number field.
  static Future<bool> patchStoredMetadata(
    Isar isar,
    int accountId,
    void Function(Account account) patch,
  ) async {
    var changed = false;
    await isar.writeTxn(() async {
      final stored = await isar.accounts.get(accountId);
      if (stored == null) return;
      patch(stored);
      await isar.accounts.put(stored);
      changed = true;
    });
    return changed;
  }

  static Account _safeCopy(
    Account stored,
    AccountNumberResolution resolution,
  ) {
    return Account()
      ..id = stored.id
      ..name = stored.name
      ..accountType = stored.accountType
      ..initialBalance = stored.initialBalance
      ..colorValue = stored.colorValue
      ..accountNumber = resolution.display
      ..accountSuffixHash = stored.accountSuffixHash
      ..currencyCode = stored.currencyCode
      ..statementDay = stored.statementDay
      ..dueDay = stored.dueDay
      ..creditLimit = stored.creditLimit
      ..isActive = stored.isActive
      ..isPrimary = stored.isPrimary;
  }
}
