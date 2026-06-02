import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final authServiceProvider = Provider((_) => AuthService());

class AuthService {
  static const _pinHashKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _bioKey = 'bio_enabled';
  static const _failedAttemptsKey = 'pin_failed_attempts';
  static const _lockoutUntilKey = 'pin_lockout_until';

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _authenticating = false;

  /// Enable/disable biometric unlock
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _bioKey, value: enabled ? '1' : '0');

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _bioKey)) == '1';

  /// Check if device supports biometrics
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  /// Enroll PIN (stored as salted hash)
  Future<void> setPin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _resetFailedAttempts();
  }

  /// Remove PIN
  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _resetFailedAttempts();
  }

  /// Check if a PIN is set
  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinHashKey)) != null;
  }

  /// Validate a PIN with brute-force protection.
  /// Returns null if locked out, false if wrong, true if correct.
  Future<bool> validatePin(String pin) async {
    // Check lockout
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
        return false; // Still locked out
      }
      await _resetFailedAttempts();
    }

    final storedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    if (storedHash == null || salt == null) return false;

    final inputHash = _hashPin(pin, salt);
    if (inputHash == storedHash) {
      await _resetFailedAttempts();
      return true;
    }

    // Wrong PIN — increment failed attempts
    await _incrementFailedAttempts();
    return false;
  }

  /// Get remaining lockout duration (null if not locked).
  Future<Duration?> getLockoutRemaining() async {
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return null;
    final lockoutUntil = DateTime.tryParse(lockoutStr);
    if (lockoutUntil == null) return null;
    final remaining = lockoutUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Perform biometric auth
  Future<bool> authenticateBiometric() async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        biometricOnly: true,
      );
    } catch (e) {
      return false;
    } finally {
      _authenticating = false;
    }
  }

  String _hashPin(String pin, String salt) {
    // PBKDF2-like: iterate HMAC 10,000 times
    final key = utf8.encode('$salt:$pin');
    var hash = Hmac(sha256, key).convert(utf8.encode(pin)).bytes;
    for (var i = 0; i < 10000; i++) {
      hash = Hmac(sha256, key).convert(hash).bytes;
    }
    return base64Encode(hash);
  }

  Future<void> _incrementFailedAttempts() async {
    final attemptsStr = await _storage.read(key: _failedAttemptsKey);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final newAttempts = attempts + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$newAttempts');

    // Exponential lockout: 3 fails=30s, 5 fails=5min, 8+=30min
    Duration? lockout;
    if (newAttempts >= 8) {
      lockout = const Duration(minutes: 30);
    } else if (newAttempts >= 5) {
      lockout = const Duration(minutes: 5);
    } else if (newAttempts >= 3) {
      lockout = const Duration(seconds: 30);
    }

    if (lockout != null) {
      final until = DateTime.now().add(lockout).toIso8601String();
      await _storage.write(key: _lockoutUntilKey, value: until);
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }
}
