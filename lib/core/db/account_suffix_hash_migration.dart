import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migration: upgrades truncated 16-char suffix hashes to full SHA-256.
/// This prevents birthday-attack collisions on the accountSuffixHash field
/// which is used for SMS → account matching.
class AccountSuffixHashMigration {
  static const _migrationKey = 'migration_account_suffix_hash_full_v1';
  static final _log = AppLog(getLogger(), 'AccountSuffixHashMigration');

  static Future<void> run(Isar isar) async {
    if (!FieldEncryptionService.isReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting suffix hash upgrade migration...');
    var count = 0;

    final accounts = await isar.accounts.where().findAll();
    if (accounts.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final account in accounts) {
          // Only upgrade truncated hashes (16 chars = old format)
          if (account.accountSuffixHash == null ||
              account.accountSuffixHash!.length > 16) {
            continue;
          }

          final accNum = account.accountNumber;
          if (accNum == null || accNum.isEmpty) continue;

          // Decrypt to get plaintext
          final plainNum = FieldEncryptionService.isEncrypted(accNum)
              ? FieldEncryptionService.decrypt(accNum)
              : accNum;

          // Skip if decryption failed (returned ciphertext)
          if (plainNum.startsWith('ENC:')) continue;

          final last4 = plainNum.length >= 4
              ? plainNum.substring(plainNum.length - 4)
              : plainNum;

          // Upgrade to full SHA-256 hash
          account.accountSuffixHash =
              sha256.convert(utf8.encode(last4)).toString();

          await isar.accounts.put(account);
          count++;
        }
      });
    }

    await prefs.setBool(_migrationKey, true);
    _log.i('Suffix hash migration complete: $count accounts upgraded');
  }
}
