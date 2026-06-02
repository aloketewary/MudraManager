import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/auth_service.dart';

/// One-time migration: converts plaintext PINs to salted hashes.
/// If old PIN exists, re-hashes it with the new format.
class PinMigration {
  static const _oldPinKey = 'app_pin';
  static const _migrationKey = 'pin_migration_v1';
  static const _storage = FlutterSecureStorage();
  static final _log = AppLog(getLogger(), 'PinMigration');

  static Future<void> run() async {
    final migrated = await _storage.read(key: _migrationKey);
    if (migrated == '1') return;

    final oldPin = await _storage.read(key: _oldPinKey);
    if (oldPin == null) {
      // No PIN set, just mark as migrated
      await _storage.write(key: _migrationKey, value: '1');
      return;
    }

    _log.i('Migrating plaintext PIN to hashed format...');

    // Re-set the PIN using new secure method
    final authService = AuthService();
    await authService.setPin(oldPin);

    // Delete old plaintext PIN
    await _storage.delete(key: _oldPinKey);
    await _storage.write(key: _migrationKey, value: '1');

    _log.i('PIN migration complete');
  }
}
