import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migration: upgrades truncated 16-character suffix hashes to full SHA-256.
/// Unresolved account values remain unchanged and keep migration retryable.
class AccountSuffixHashMigration {
  static const _migrationKey = 'migration_account_suffix_hash_full_v1';
  static final _log = AppLog(getLogger(), 'AccountSuffixHashMigration');

  static Future<void> run(Isar isar) async {
    final readiness = await FieldEncryptionService.waitForReadiness();
    if (!readiness.isReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting suffix hash upgrade migration...');
    final updates = <Account>[];
    var unresolved = 0;

    final accounts = await isar.accounts.where().findAll();
    for (final account in accounts) {
      final hash = account.accountSuffixHash;
      if (hash == null || hash.length > 16) continue;

      final value = account.accountNumber;
      if (value == null || value.isEmpty) {
        // A stale hash cannot match a missing number; clear it via a raw copy.
        final cleared = AccountDataContract.copyAccount(account)
          ..accountSuffixHash = null;
        updates.add(cleared);
        continue;
      }

      final resolution = await account.resolveAccountNumberStrict();
      if (!resolution.isResolved || resolution.resolvedValue == null) {
        unresolved++;
        _log.w(
          AccountDataContract.redactedFailure(
            accountId: account.id,
            category: resolution.errorCategory ?? 'account_number_unavailable',
          ),
        );
        continue;
      }

      final upgraded = AccountDataContract.copyAccount(account)
        ..accountSuffixHash = accountSuffixHashFor(resolution.resolvedValue!);
      if (upgraded.accountSuffixHash != account.accountSuffixHash) {
        updates.add(upgraded);
      }
    }

    if (updates.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final account in updates) {
          await isar.accounts.put(account);
        }
      });
    }

    // Keep guard unset while malformed/foreign records need retry.
    if (unresolved == 0) {
      await prefs.setBool(_migrationKey, true);
    }
    _log.i(
      'Suffix hash migration complete: ${updates.length} accounts upgraded; '
      'unresolved=$unresolved',
    );
  }
}
