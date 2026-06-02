import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration: encrypts account numbers and generates suffix hashes.
/// Runs after FieldEncryptionService.initialize() succeeds.
class AccountEncryptionMigration {
  static const _migrationKey = 'migration_account_encryption_v1';
  static final _log = AppLog(getLogger(), 'AccountEncryptionMigration');

  static Future<void> run(Isar isar) async {
    if (!FieldEncryptionService.isReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting account encryption migration...');
    var count = 0;

    final accounts = await isar.accounts.where().findAll();
    if (accounts.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final account in accounts) {
          final accNum = account.accountNumber;
          if (accNum == null || accNum.isEmpty) continue;

          // Skip if already encrypted
          if (FieldEncryptionService.isEncrypted(accNum)) continue;

          // Generate suffix hash BEFORE encrypting
          final last4 = accNum.length >= 4
              ? accNum.substring(accNum.length - 4)
              : accNum;
          // Use full SHA-256 hash to prevent birthday-attack collisions
          account.accountSuffixHash = sha256
              .convert(utf8.encode(last4))
              .toString();

          // Encrypt the account number
          account.accountNumber =
              FieldEncryptionService.encryptOrFallback(accNum);

          await isar.accounts.put(account);
          count++;
        }
      });
    }

    await prefs.setBool(_migrationKey, true);
    _log.i('Account encryption migration complete: $count accounts updated');
  }
}
