import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

/// Field-level AES-256 encryption for sensitive Isar fields.
///
/// Isar Community doesn't support DB-level encryption, so we encrypt
/// sensitive fields (SMS body, account numbers, descriptions) before
/// writing and decrypt after reading.
///
/// Key is stored in Android Keystore / iOS Keychain via FlutterSecureStorage.
class FieldEncryptionService {
  static const _keyName = 'mudra_field_encryption_key';
  static const _prefix = 'ENC:';
  static const _storage = FlutterSecureStorage();
  static final _log = AppLog(getLogger(), 'FieldEncryption');

  static enc.Key? _cachedKey;

  /// Initialize and cache the encryption key. Call once at app start.
  static Future<void> initialize() async {
    try {
      _cachedKey = await _getOrCreateKey();
      _log.i('Field encryption initialized');
    } catch (e) {
      _log.e('Failed to initialize encryption', e);
    }
  }

  /// Whether encryption is available (key loaded successfully).
  static bool get isReady => _cachedKey != null;

  /// Encrypt a plaintext string. Returns prefixed ciphertext.
  /// Throws [StateError] if encryption service is not ready.
  /// Returns original if already encrypted.
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    if (plaintext.startsWith(_prefix)) return plaintext; // already encrypted
    if (!isReady) {
      _log.e('Encryption key not available — data will NOT be stored');
      throw StateError('FieldEncryptionService not initialized');
    }
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (e) {
      _log.e('Encrypt failed', e);
      throw StateError('Encryption failed: $e');
    }
  }

  /// Encrypt with graceful fallback — only use for non-critical fields
  /// where losing data would be worse than storing unencrypted.
  static String encryptOrFallback(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    if (plaintext.startsWith(_prefix)) return plaintext;
    if (!isReady) {
      _log.w('Encryption unavailable, storing plaintext');
      return plaintext;
    }
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (e) {
      _log.w('Encrypt failed, storing plaintext', e);
      return plaintext;
    }
  }

  /// Decrypt a ciphertext string. Returns plaintext.
  /// Returns original value if not encrypted or decryption fails.
  static String decrypt(String ciphertext) {
    if (!isReady || !ciphertext.startsWith(_prefix)) return ciphertext;
    try {
      final payload = ciphertext.substring(_prefix.length);
      final parts = payload.split(':');
      if (parts.length != 2) return ciphertext;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      _log.w('Decrypt failed, returning raw value', e);
      return ciphertext;
    }
  }

  /// Encrypt a nullable string. Throws if service not ready.
  static String? encryptNullable(String? value) {
    if (value == null) return null;
    return encrypt(value);
  }

  /// Encrypt nullable with graceful fallback.
  static String? encryptNullableOrFallback(String? value) {
    if (value == null) return null;
    return encryptOrFallback(value);
  }

  /// Decrypt a nullable string.
  static String? decryptNullable(String? value) {
    if (value == null) return null;
    return decrypt(value);
  }

  /// Check if a value is already encrypted.
  static bool isEncrypted(String? value) =>
      value != null && value.startsWith(_prefix);

  /// Safe display helper — guarantees no encrypted text reaches UI.
  /// Use this as a last-resort guard when displaying any potentially
  /// encrypted string. Returns decrypted value or empty string on failure.
  static String safeDisplay(String? value, [String fallback = '']) {
    if (value == null || value.isEmpty) return fallback;
    // Full-field encrypted
    if (value.startsWith(_prefix)) {
      if (!isReady) return fallback;
      final decrypted = decrypt(value);
      return decrypted.startsWith(_prefix) ? fallback : decrypted;
    }
    // Embedded ENC: token mid-string — strip it out
    if (value.contains(_prefix)) {
      if (!isReady) return fallback;
      return value.replaceAllMapped(
        RegExp(r'ENC:[A-Za-z0-9+/=]+:[A-Za-z0-9+/=]+'),
        (m) {
          final decrypted = decrypt(m.group(0)!);
          return decrypted.startsWith(_prefix) ? '' : decrypted;
        },
      );
    }
    return value;
  }

  static Future<enc.Key> _getOrCreateKey() async {
    var keyStr = await _storage.read(key: _keyName);
    if (keyStr == null) {
      final bytes =
          List<int>.generate(32, (_) => Random.secure().nextInt(256));
      keyStr = base64Encode(Uint8List.fromList(bytes));
      await _storage.write(key: _keyName, value: keyStr);
    }
    return enc.Key.fromBase64(keyStr);
  }
}
