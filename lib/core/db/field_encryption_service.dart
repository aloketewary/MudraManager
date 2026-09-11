import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

/// Lifecycle of field encryption key availability.
enum FieldEncryptionReadiness { pending, ready, failed }

/// Redacted readiness snapshot. No exception/key/value is carried.
class FieldEncryptionReadinessResult {
  final FieldEncryptionReadiness state;
  final String? errorCategory;

  const FieldEncryptionReadinessResult(this.state, {this.errorCategory});

  bool get isReady => state == FieldEncryptionReadiness.ready;
  bool get isPending => state == FieldEncryptionReadiness.pending;
  bool get isFailed => state == FieldEncryptionReadiness.failed;
}

/// Strict decrypt classification used by account-data boundary.
///
/// [plaintext] is populated only for resolved values inside this boundary. It
/// is never populated with an input ciphertext or a failed decrypt result.
enum StrictDecryptStatus {
  nullOrEmpty,
  legacyPlaintext,
  decrypted,
  malformed,
  keyMismatch,
  unavailable,
}

class StrictDecryptResult {
  final StrictDecryptStatus status;
  final String? plaintext;
  final String? errorCategory;

  const StrictDecryptResult._(
    this.status, {
    this.plaintext,
    this.errorCategory,
  });

  factory StrictDecryptResult.nullOrEmpty() =>
      const StrictDecryptResult._(StrictDecryptStatus.nullOrEmpty);

  factory StrictDecryptResult.legacyPlaintext(String value) =>
      StrictDecryptResult._(
        StrictDecryptStatus.legacyPlaintext,
        plaintext: value,
      );

  factory StrictDecryptResult.decrypted(String value) => StrictDecryptResult._(
        StrictDecryptStatus.decrypted,
        plaintext: value,
      );

  factory StrictDecryptResult.failure(
    StrictDecryptStatus status,
    String category,
  ) =>
      StrictDecryptResult._(status, errorCategory: category);

  bool get isResolved =>
      status == StrictDecryptStatus.legacyPlaintext ||
      status == StrictDecryptStatus.decrypted;

  bool get isFailure =>
      !isResolved && status != StrictDecryptStatus.nullOrEmpty;
}

/// Typed, redacted account-crypto failure.
class FieldEncryptionException implements Exception {
  final String category;

  const FieldEncryptionException(this.category);

  @override
  String toString() => 'Field encryption failed: $category';
}

/// Field-level AES-256 encryption for sensitive Isar fields.
///
/// Isar Community doesn't support DB-level encryption, so sensitive fields are
/// encrypted before writing and decrypted after reading.
class FieldEncryptionService {
  static const _keyName = 'mudra_field_encryption_key';
  static const _prefix = 'ENC:';
  static const _storage = FlutterSecureStorage();
  static final _log = AppLog(getLogger(), 'FieldEncryption');

  static enc.Key? _cachedKey;
  static FieldEncryptionReadiness _readiness = FieldEncryptionReadiness.pending;
  static Future<FieldEncryptionReadinessResult>? _initialization;

  /// Current shared readiness state. Pending is not success.
  static FieldEncryptionReadiness get readiness => _readiness;

  /// Redacted shared readiness snapshot for providers/services.
  static FieldEncryptionReadinessResult get readinessResult =>
      FieldEncryptionReadinessResult(
        _readiness,
        errorCategory: _readiness == FieldEncryptionReadiness.failed
            ? 'initialization_failed'
            : null,
      );

  /// Initialize key once. Concurrent callers receive same Future/result.
  static Future<FieldEncryptionReadinessResult> initialize() {
    final existing = _initialization;
    if (existing != null) return existing;

    final future = _initialize();
    _initialization = future;
    return future;
  }

  static Future<FieldEncryptionReadinessResult> _initialize() async {
    _readiness = FieldEncryptionReadiness.pending;
    try {
      _cachedKey = await _getOrCreateKey();
      _readiness = FieldEncryptionReadiness.ready;
      _log.i('Field encryption initialized');
      return const FieldEncryptionReadinessResult(
        FieldEncryptionReadiness.ready,
      );
    } catch (_) {
      _cachedKey = null;
      _readiness = FieldEncryptionReadiness.failed;
      // Never pass exception text to logs: storage/plugin errors can contain
      // implementation details that must not cross an account boundary.
      _log.e('Field encryption initialization failed: initialization_failed');
      return const FieldEncryptionReadinessResult(
        FieldEncryptionReadiness.failed,
        errorCategory: 'initialization_failed',
      );
    }
  }

  /// Await shared readiness. Starts initialization if no caller started it.
  static Future<FieldEncryptionReadinessResult> waitForReadiness() {
    return initialize();
  }

  /// Whether encryption is available (key loaded successfully).
  static bool get isReady =>
      _readiness == FieldEncryptionReadiness.ready && _cachedKey != null;

  /// Encrypt plaintext. Generic behavior preserved for non-account fields.
  /// Throws [StateError] if encryption service is not ready.
  /// Returns original if already encrypted.
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    if (plaintext.startsWith(_prefix)) return plaintext;
    if (!isReady) {
      _log.e('Encryption key not available — data will NOT be stored');
      throw StateError('FieldEncryptionService not initialized');
    }
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (_) {
      // Keep generic failure semantics, but never expose plugin/crypto details.
      _log.e('Encrypt failed: encryption_failed');
      throw StateError('Encryption failed');
    }
  }

  /// Encrypt with graceful fallback — only for non-critical fields.
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
    } catch (_) {
      _log.w('Encrypt failed, storing plaintext: encryption_failed');
      return plaintext;
    }
  }

  /// Decrypt ciphertext. Generic fail-open behavior preserved for non-account
  /// fields; account paths must use [decryptStrict].
  static String decrypt(String ciphertext) {
    if (!isReady || !ciphertext.startsWith(_prefix)) return ciphertext;
    try {
      final payload = ciphertext.substring(_prefix.length);
      final parts = payload.split(':');
      if (parts.length != 2) return ciphertext;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      final recovered = _tryRecoverTruncated(ciphertext);
      if (recovered != null) return recovered;
      // Generic non-account callers retain fail-open return semantics, while
      // diagnostics stay free of ciphertext and plugin exception details.
      _log.w('Decrypt failed, returning raw value: decrypt_failed');
      return ciphertext;
    }
  }

  /// Strict account-safe decrypt. Never returns input ciphertext on failure.
  static Future<StrictDecryptResult> decryptStrict(String? value) async {
    final readinessResult = await waitForReadiness();
    if (!readinessResult.isReady) {
      return StrictDecryptResult.failure(
        StrictDecryptStatus.unavailable,
        readinessResult.errorCategory ?? 'encryption_unavailable',
      );
    }
    return decryptStrictReady(value);
  }

  /// Synchronous strict decrypt for legacy synchronous account extensions.
  /// Caller must already have awaited readiness; pending/failed states fail
  /// closed instead of falling back to generic decrypt behavior.
  static StrictDecryptResult decryptStrictReady(String? value) {
    if (value == null || value.isEmpty) {
      return StrictDecryptResult.nullOrEmpty();
    }
    if (!isReady) {
      return StrictDecryptResult.failure(
        StrictDecryptStatus.unavailable,
        'encryption_unavailable',
      );
    }
    if (!value.startsWith(_prefix)) {
      return StrictDecryptResult.legacyPlaintext(value);
    }

    final payload = value.substring(_prefix.length);
    final parts = payload.split(':');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return StrictDecryptResult.failure(
        StrictDecryptStatus.malformed,
        'malformed_ciphertext',
      );
    }
    if (!_isBase64(parts[0]) || !_isBase64(parts[1])) {
      return StrictDecryptResult.failure(
        StrictDecryptStatus.malformed,
        'malformed_ciphertext',
      );
    }

    try {
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final plaintext = encrypter.decrypt64(parts[1], iv: iv);
      if (plaintext.startsWith(_prefix)) {
        return StrictDecryptResult.failure(
          StrictDecryptStatus.malformed,
          'malformed_plaintext',
        );
      }
      return StrictDecryptResult.decrypted(plaintext);
    } catch (_) {
      // Do not expose value, key, exception, or ciphertext.
      return StrictDecryptResult.failure(
        StrictDecryptStatus.keyMismatch,
        'key_mismatch',
      );
    }
  }

  /// Strict encrypt for account writes. Never falls back to plaintext.
  static String encryptStrict(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    if (plaintext.startsWith(_prefix)) return plaintext;
    if (!isReady) {
      throw const FieldEncryptionException('encryption_unavailable');
    }
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (_) {
      throw const FieldEncryptionException('encryption_failed');
    }
  }

  /// Strict nullable encrypt. No plaintext fallback.
  static String? encryptNullableStrict(String? value) {
    if (value == null || value.isEmpty) return value;
    return encryptStrict(value);
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
  /// Generic behavior preserved; account UI must use account resolution model.
  static String safeDisplay(String? value, [String fallback = '']) {
    if (value == null || value.isEmpty) return fallback;
    if (value.startsWith(_prefix)) {
      if (!isReady) return fallback;
      final decrypted = decrypt(value);
      return decrypted.startsWith(_prefix) ? fallback : decrypted;
    }
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

  /// Test-only key injection keeps strict boundary tests deterministic.
  /// Production startup still uses [initialize].
  static void setKeyForTesting(String base64Key) {
    _cachedKey = enc.Key.fromBase64(base64Key);
    _readiness = FieldEncryptionReadiness.ready;
    _initialization = Future.value(readinessResult);
  }

  /// Test-only reset. Production callers use [initialize] and retry policy.
  static void resetForTesting() {
    _cachedKey = null;
    _readiness = FieldEncryptionReadiness.pending;
    _initialization = null;
  }

  static bool _isBase64(String value) {
    if (value.isEmpty || value.length % 4 != 0) return false;
    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(value)) return false;
    try {
      base64Decode(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _tryRecoverTruncated(String ciphertext) {
    try {
      final payload = ciphertext.substring(_prefix.length);
      final parts = payload.split(':');
      if (parts.length != 2) return null;
      final ivPart = parts[0];
      final cipherPart = parts[1];
      final match = RegExp(r'^[A-Za-z0-9+/]*={0,2}').firstMatch(cipherPart);
      final cleanCipher = match?.group(0) ?? '';
      if (cleanCipher.isEmpty || cleanCipher == cipherPart) return null;
      final suffix = cipherPart.substring(cleanCipher.length);
      final iv = enc.IV.fromBase64(ivPart);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!));
      final plaintext = encrypter.decrypt64(cleanCipher, iv: iv);
      return suffix.isEmpty ? plaintext : '$plaintext$suffix';
    } catch (_) {
      return null;
    }
  }

  static Future<enc.Key> _getOrCreateKey() async {
    var keyStr = await _storage.read(key: _keyName);
    if (keyStr == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      keyStr = base64Encode(Uint8List.fromList(bytes));
      await _storage.write(key: _keyName, value: keyStr);
    }
    return enc.Key.fromBase64(keyStr);
  }
}
