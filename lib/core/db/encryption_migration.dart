import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration: encrypts existing plaintext sensitive fields.
/// Runs after FieldEncryptionService.initialize() succeeds.
class EncryptionMigration {
  static const _migrationKey = 'migration_field_encryption_v1';
  static final _log = AppLog(getLogger(), 'EncryptionMigration');

  static Future<void> run(Isar isar) async {
    if (!FieldEncryptionService.isReady) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting field encryption migration...');
    var count = 0;

    // 1. SmsActivity — body, merchant
    final activities = await isar.smsActivitys.where().findAll();
    if (activities.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final a in activities) {
          var changed = false;
          if (!FieldEncryptionService.isEncrypted(a.body)) {
            a.body = FieldEncryptionService.encrypt(a.body);
            changed = true;
          }
          if (a.merchant != null &&
              !FieldEncryptionService.isEncrypted(a.merchant)) {
            a.merchant = FieldEncryptionService.encryptNullable(a.merchant);
            changed = true;
          }
          if (changed) {
            await isar.smsActivitys.put(a);
            count++;
          }
        }
      });
    }

    // 2. Transaction — description
    final txns = await isar.transactions.where().findAll();
    if (txns.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final t in txns) {
          if (t.description != null &&
              !FieldEncryptionService.isEncrypted(t.description)) {
            t.description =
                FieldEncryptionService.encryptNullable(t.description);
            await isar.transactions.put(t);
            count++;
          }
        }
      });
    }

    // 3. UserProfile — name, email, phone
    final profiles = await isar.userProfiles.where().findAll();
    if (profiles.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final p in profiles) {
          var changed = false;
          if (p.name != null && !FieldEncryptionService.isEncrypted(p.name)) {
            p.name = FieldEncryptionService.encryptNullable(p.name);
            changed = true;
          }
          if (p.email != null && !FieldEncryptionService.isEncrypted(p.email)) {
            p.email = FieldEncryptionService.encryptNullable(p.email);
            changed = true;
          }
          if (p.phone != null && !FieldEncryptionService.isEncrypted(p.phone)) {
            p.phone = FieldEncryptionService.encryptNullable(p.phone);
            changed = true;
          }
          if (changed) {
            await isar.userProfiles.put(p);
            count++;
          }
        }
      });
    }

    await prefs.setBool(_migrationKey, true);
    _log.i('Field encryption migration complete: $count records updated');
  }
}
