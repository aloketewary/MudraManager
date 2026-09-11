import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration: encrypts legacy account numbers and generates suffix
/// hashes. It is guarded and retryable when a record cannot be resolved.
class AccountEncryptionMigration {
  static const _migrationKey = 'migration_account_encryption_v1';
  static final _log = AppLog(getLogger(), 'AccountEncryptionMigration');

  static Future<void> run(Isar isar) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting account encryption migration...');
    final updates = <Account>[];
    var unresolved = 0;

    final accounts = await isar.accounts.where().findAll();
    for (final account in accounts) {
      final storedValue = account.accountNumber;
      if (storedValue == null || storedValue.isEmpty) {
        if (account.accountSuffixHash != null) {
          final cleared = AccountDataContract.copyAccount(account)
            ..accountSuffixHash = null;
          updates.add(cleared);
        }
        continue;
      }

      final candidate = AccountDataContract.copyAccount(account);
      if (FieldEncryptionService.isEncrypted(storedValue)) {
        // Validate existing device ciphertext before deriving metadata. Keep
        // exact ciphertext; this migration must not double-encrypt it.
        final resolution = await account.resolveAccountNumberStrict();
        if (!resolution.isResolved || resolution.resolvedValue == null) {
          unresolved++;
          _log.w(
            AccountDataContract.redactedFailure(
              accountId: account.id,
              category:
                  resolution.errorCategory ?? 'account_number_unavailable',
            ),
          );
          continue;
        }
        candidate.accountSuffixHash = accountSuffixHashFor(
          resolution.resolvedValue!,
        );
      } else {
        // Strict preparation encrypts legacy plaintext before any put and
        // leaves candidate/storage unchanged when crypto fails.
        final preparation = await candidate.prepareStrictWrite();
        if (!preparation.succeeded) {
          unresolved++;
          _log.w(
            AccountDataContract.redactedFailure(
              accountId: account.id,
              category: preparation.errorCategory ?? 'encryption_failed',
            ),
          );
          continue;
        }
        candidate.applyStrictWrite(preparation);
      }

      if (candidate.accountNumber != account.accountNumber ||
          candidate.accountSuffixHash != account.accountSuffixHash) {
        updates.add(candidate);
      }
    }

    if (updates.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final account in updates) {
          await isar.accounts.put(account);
        }
      });
    }

    // Unresolved records remain untouched and force a later retry.
    if (unresolved == 0) {
      await prefs.setBool(_migrationKey, true);
    }
    _log.i(
      'Account encryption migration complete: ${updates.length} accounts updated; '
      'unresolved=$unresolved',
    );
  }
}
