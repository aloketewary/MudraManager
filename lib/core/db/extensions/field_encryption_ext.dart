import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/archived_transaction.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';

/// Encrypt sensitive fields before writing to Isar.
///
/// NOTE: FieldEncryptionService internally checks if a string is already encrypted
/// (via 'ENC:' prefix), making it safe to call these methods on mixed data
/// during migration or double-save scenarios.
extension SmsActivityEncryption on SmsActivity {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.encrypt(body);
    sender = FieldEncryptionService.encrypt(sender);
    merchant = FieldEncryptionService.encryptNullable(merchant);
    account = FieldEncryptionService.encryptNullable(account);
    toAccount = FieldEncryptionService.encryptNullable(toAccount);
    transactionRef = FieldEncryptionService.encryptNullable(transactionRef);
    reviewNotes = FieldEncryptionService.encryptNullable(reviewNotes);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.decrypt(body);
    sender = FieldEncryptionService.decrypt(sender);
    merchant = FieldEncryptionService.decryptNullable(merchant);
    account = FieldEncryptionService.decryptNullable(account);
    toAccount = FieldEncryptionService.decryptNullable(toAccount);
    transactionRef = FieldEncryptionService.decryptNullable(transactionRef);
    reviewNotes = FieldEncryptionService.decryptNullable(reviewNotes);
  }
}

extension PendingTransactionEncryption on PendingTransaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.encrypt(body);
    sender = FieldEncryptionService.encrypt(sender);
    account = FieldEncryptionService.encryptNullable(account);
    toAccount = FieldEncryptionService.encryptNullable(toAccount);
    transactionRef = FieldEncryptionService.encryptNullable(transactionRef);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.decrypt(body);
    sender = FieldEncryptionService.decrypt(sender);
    account = FieldEncryptionService.decryptNullable(account);
    toAccount = FieldEncryptionService.decryptNullable(toAccount);
    transactionRef = FieldEncryptionService.decryptNullable(transactionRef);
  }
}

extension TransactionEncryption on Transaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension RecurringBillEncryption on RecurringBill {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension TripEncryption on Trip {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension TripParticipantEncryption on TripParticipant {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
    phone = FieldEncryptionService.encryptNullable(phone);
    email = FieldEncryptionService.encryptNullable(email);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
    phone = FieldEncryptionService.decryptNullable(phone);
    email = FieldEncryptionService.decryptNullable(email);
  }
}

extension SplitExpenseEncryption on SplitExpense {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension ArchivedTransactionEncryption on ArchivedTransaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
    accountName = FieldEncryptionService.encryptNullable(accountName);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
    accountName = FieldEncryptionService.decryptNullable(accountName);
  }
}

extension CategoryRuleEncryption on CategoryRule {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    recipientName = FieldEncryptionService.encryptNullable(recipientName);
    merchantName = FieldEncryptionService.encryptNullable(merchantName);
    accountNumber = FieldEncryptionService.encryptNullable(accountNumber);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    recipientName = FieldEncryptionService.decryptNullable(recipientName);
    merchantName = FieldEncryptionService.decryptNullable(merchantName);
    accountNumber = FieldEncryptionService.decryptNullable(accountNumber);
  }
}

extension RecurringTransactionEncryption on RecurringTransaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
  }
}

enum AccountNumberResolutionStatus {
  nullOrEmpty,
  legacyPlaintext,
  decrypted,
  malformed,
  keyMismatch,
  unavailable,
  shortValue,
}

/// Safe account-number result. [resolvedValue] exists only inside controlled
/// account/matching code; [display] is the only presentation representation.
class AccountNumberResolution {
  final AccountNumberResolutionStatus status;
  final String? resolvedValue;
  final String display;
  final String? errorCategory;

  const AccountNumberResolution({
    required this.status,
    required this.display,
    this.resolvedValue,
    this.errorCategory,
  });

  bool get isResolved =>
      status == AccountNumberResolutionStatus.legacyPlaintext ||
      status == AccountNumberResolutionStatus.decrypted ||
      status == AccountNumberResolutionStatus.shortValue;

  bool get isUnavailable =>
      !isResolved && status != AccountNumberResolutionStatus.nullOrEmpty;
}

/// Immutable account write preparation. Caller applies it only after all
/// validation succeeds, enabling atomic persistence with no partial mutation.
class AccountWritePreparation {
  final bool succeeded;
  final String? encryptedAccountNumber;
  final String? accountSuffixHash;
  final String? errorCategory;

  const AccountWritePreparation.success({
    required this.encryptedAccountNumber,
    required this.accountSuffixHash,
  })  : succeeded = true,
        errorCategory = null;

  const AccountWritePreparation.failure(this.errorCategory)
      : succeeded = false,
        encryptedAccountNumber = null,
        accountSuffixHash = null;
}

String accountSuffixHashFor(String value) {
  final suffix = value.length >= 4 ? value.substring(value.length - 4) : value;
  return sha256.convert(utf8.encode(suffix)).toString();
}

extension AccountEncryption on Account {
  /// Resolve account number without ever returning failed ciphertext.
  Future<AccountNumberResolution> resolveAccountNumberStrict() async {
    final result = await FieldEncryptionService.decryptStrict(accountNumber);
    switch (result.status) {
      case StrictDecryptStatus.nullOrEmpty:
        return const AccountNumberResolution(
          status: AccountNumberResolutionStatus.nullOrEmpty,
          display: '••••',
        );
      case StrictDecryptStatus.legacyPlaintext:
      case StrictDecryptStatus.decrypted:
        final value = result.plaintext!;
        if (value.length < 4) {
          return AccountNumberResolution(
            status: AccountNumberResolutionStatus.shortValue,
            resolvedValue: value,
            display: '••••',
          );
        }
        return AccountNumberResolution(
          status: result.status == StrictDecryptStatus.legacyPlaintext
              ? AccountNumberResolutionStatus.legacyPlaintext
              : AccountNumberResolutionStatus.decrypted,
          resolvedValue: value,
          display: '•••• ${value.substring(value.length - 4)}',
        );
      case StrictDecryptStatus.malformed:
        return AccountNumberResolution(
          status: AccountNumberResolutionStatus.malformed,
          display: '••••',
          errorCategory: result.errorCategory,
        );
      case StrictDecryptStatus.keyMismatch:
        return AccountNumberResolution(
          status: AccountNumberResolutionStatus.keyMismatch,
          display: '••••',
          errorCategory: result.errorCategory,
        );
      case StrictDecryptStatus.unavailable:
        return AccountNumberResolution(
          status: AccountNumberResolutionStatus.unavailable,
          display: '••••',
          errorCategory: result.errorCategory,
        );
    }
  }

  /// Prepare encrypted account number + suffix metadata without mutating this
  /// model. Existing encrypted values are validated, never double-encrypted.
  Future<AccountWritePreparation> prepareStrictWrite() async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) {
      return AccountWritePreparation.failure(
        readiness.errorCategory ?? 'encryption_unavailable',
      );
    }

    final value = accountNumber;
    if (value == null || value.isEmpty) {
      return const AccountWritePreparation.success(
        encryptedAccountNumber: null,
        accountSuffixHash: null,
      );
    }

    String plainValue;
    String encryptedValue;
    if (FieldEncryptionService.isEncrypted(value)) {
      final resolved = await FieldEncryptionService.decryptStrict(value);
      if (!resolved.isResolved || resolved.plaintext == null) {
        return AccountWritePreparation.failure(
          resolved.errorCategory ?? 'account_number_unavailable',
        );
      }
      plainValue = resolved.plaintext!;
      encryptedValue = value;
    } else {
      plainValue = value;
      try {
        encryptedValue = FieldEncryptionService.encryptStrict(plainValue);
      } on FieldEncryptionException catch (error) {
        return AccountWritePreparation.failure(error.category);
      } catch (_) {
        return const AccountWritePreparation.failure('encryption_failed');
      }
    }

    return AccountWritePreparation.success(
      encryptedAccountNumber: encryptedValue,
      accountSuffixHash: accountSuffixHashFor(plainValue),
    );
  }

  /// Apply prepared fields only after caller has chosen to commit.
  void applyStrictWrite(AccountWritePreparation preparation) {
    if (!preparation.succeeded) {
      throw FieldEncryptionException(
        preparation.errorCategory ?? 'account_write_failed',
      );
    }
    accountNumber = preparation.encryptedAccountNumber;
    accountSuffixHash = preparation.accountSuffixHash;
  }

  /// Legacy synchronous writer retained for existing callers, now strict.
  /// It never falls back to plaintext or silently accepts unavailable crypto.
  void encryptFields() {
    // Keep legacy synchronous extension behavior unchanged when readiness is
    // unavailable. Account writes must use prepareStrictWrite/writeAccount;
    // this compatibility method must not silently become their boundary.
    if (!FieldEncryptionService.isReady) return;

    final value = accountNumber;
    if (value == null || value.isEmpty) {
      accountNumber = value;
      accountSuffixHash = null;
      return;
    }
    if (FieldEncryptionService.isEncrypted(value)) {
      final resolved = FieldEncryptionService.decryptStrictReady(value);
      if (!resolved.isResolved || resolved.plaintext == null) {
        throw FieldEncryptionException(
          resolved.errorCategory ?? 'account_number_unavailable',
        );
      }
      accountSuffixHash = accountSuffixHashFor(resolved.plaintext!);
      return;
    }

    final encryptedValue = FieldEncryptionService.encryptStrict(value);
    // Assign only after encryption succeeds: failure leaves this model intact.
    accountNumber = encryptedValue;
    accountSuffixHash = accountSuffixHashFor(value);
  }

  /// Compatibility reader fails closed. New account paths should await
  /// [resolveAccountNumberStrict] to receive typed status.
  void decryptFields() {
    // Preserve legacy synchronous no-op semantics until readiness exists.
    // Strict account consumers use resolveAccountNumberStrict instead.
    if (!FieldEncryptionService.isReady) return;

    final value = accountNumber;
    if (value == null || value.isEmpty) return;
    final resolved = FieldEncryptionService.decryptStrictReady(value);
    if (!resolved.isResolved || resolved.plaintext == null) {
      accountNumber = null;
      throw FieldEncryptionException(
        resolved.errorCategory ?? 'account_number_unavailable',
      );
    }
    accountNumber = resolved.plaintext;
  }

  /// Check account suffix using full SHA-256 or legacy 16-char hash.
  ///
  /// Callers may provide a full SMS account token (for example `X1234`) or
  /// only its suffix. Only final four characters are hashed, so storage never
  /// needs plaintext account-number comparison.
  bool matchesSuffix(String accountToken) {
    final trimmed = accountToken.trim();
    if (trimmed.isEmpty || accountSuffixHash == null) return false;
    final suffix =
        trimmed.length <= 4 ? trimmed : trimmed.substring(trimmed.length - 4);
    final hash = sha256.convert(utf8.encode(suffix)).toString();
    if (accountSuffixHash!.length <= 16) {
      return hash.substring(0, 16) == accountSuffixHash;
    }
    return hash == accountSuffixHash;
  }
}

extension NotificationRecordEncryption on NotificationRecord {
  /// Encrypts sensitive notification fields before storage.
  /// Protects user's financial privacy in case of database exposure.
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    title = FieldEncryptionService.encrypt(title);
    body = FieldEncryptionService.encrypt(body);
    actionData = FieldEncryptionService.encryptNullable(actionData);
    primaryAction = FieldEncryptionService.encryptNullable(primaryAction);
    secondaryAction = FieldEncryptionService.encryptNullable(secondaryAction);
  }

  /// Decrypts notification fields for UI display.
  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    title = FieldEncryptionService.decrypt(title);
    body = FieldEncryptionService.decrypt(body);
    actionData = FieldEncryptionService.decryptNullable(actionData);
    primaryAction = FieldEncryptionService.decryptNullable(primaryAction);
    secondaryAction = FieldEncryptionService.decryptNullable(secondaryAction);
  }
}

extension UserProfileEncryption on UserProfile {
  /// Encrypts personal identifiable information (PII) before storage.
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encryptNullable(name);
    email = FieldEncryptionService.encryptNullable(email);
    phone = FieldEncryptionService.encryptNullable(phone);
  }

  /// Decrypts user PII for UI display.
  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decryptNullable(name);
    email = FieldEncryptionService.decryptNullable(email);
    phone = FieldEncryptionService.decryptNullable(phone);
  }
}

/// Decrypt a list of SmsActivity after Isar read.
extension SmsActivityListDecryption on Future<List<SmsActivity>> {
  Future<List<SmsActivity>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension RecurringBillListDecryption on Future<List<RecurringBill>> {
  Future<List<RecurringBill>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension RecurringBillStreamDecryption on Stream<List<RecurringBill>> {
  Stream<List<RecurringBill>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension TripListDecryption on Future<List<Trip>> {
  Future<List<Trip>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension TripStreamDecryption on Stream<List<Trip>> {
  Stream<List<Trip>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension TripParticipantListDecryption on Future<List<TripParticipant>> {
  Future<List<TripParticipant>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension SplitExpenseListDecryption on Future<List<SplitExpense>> {
  Future<List<SplitExpense>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension ArchivedTransactionListDecryption
    on Future<List<ArchivedTransaction>> {
  Future<List<ArchivedTransaction>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension PendingTransactionListDecryption
    on Future<List<PendingTransaction?>> {
  Future<List<PendingTransaction?>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item?.decryptFields();
    }
    return list;
  }
}

extension GoalEncryption on Goal {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension BudgetEncryption on Budget {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
  }
}

extension BudgetListDecryption on Future<List<Budget>> {
  Future<List<Budget>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension BudgetStreamDecryption on Stream<List<Budget>> {
  Stream<List<Budget>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension GoalListDecryption on Future<List<Goal>> {
  Future<List<Goal>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension RecurringTransactionListDecryption
    on Future<List<RecurringTransaction>> {
  Future<List<RecurringTransaction>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension TransactionListDecryption on Future<List<Transaction>> {
  Future<List<Transaction>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension NotificationRecordListDecryption on Future<List<NotificationRecord>> {
  Future<List<NotificationRecord>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension NotificationRecordStreamDecryption
    on Stream<List<NotificationRecord>> {
  Stream<List<NotificationRecord>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension GoalStreamDecryption on Stream<List<Goal>> {
  Stream<List<Goal>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension TransactionStreamDecryption on Stream<List<Transaction>> {
  Stream<List<Transaction>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension RecurringTransactionStreamDecryption
    on Stream<List<RecurringTransaction>> {
  Stream<List<RecurringTransaction>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension UserProfileDecryption on Future<UserProfile?> {
  Future<UserProfile?> withDecryption() async {
    final profile = await this;
    profile?.decryptFields();
    return profile;
  }
}

extension GoalDecryption on Future<Goal?> {
  Future<Goal?> withDecryption() async {
    final goal = await this;
    goal?.decryptFields();
    return goal;
  }
}

extension BudgetDecryption on Future<Budget?> {
  Future<Budget?> withDecryption() async {
    final budget = await this;
    budget?.decryptFields();
    return budget;
  }
}

extension RecurringBillDecryption on Future<RecurringBill?> {
  Future<RecurringBill?> withDecryption() async {
    final bill = await this;
    bill?.decryptFields();
    return bill;
  }
}

extension RecurringTransactionDecryption on Future<RecurringTransaction?> {
  Future<RecurringTransaction?> withDecryption() async {
    final rt = await this;
    rt?.decryptFields();
    return rt;
  }
}

extension UserProfileListDecryption on Future<List<UserProfile>> {
  Future<List<UserProfile>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension CategoryRuleListDecryption on Future<List<CategoryRule>> {
  Future<List<CategoryRule>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension AccountListDecryption on Future<List<Account>> {
  Future<List<Account>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension AccountStreamDecryption on Stream<List<Account>> {
  Stream<List<Account>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}
