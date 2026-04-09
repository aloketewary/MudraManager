import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final authServiceProvider = Provider((_) => AuthService());

class AuthService {
  static const _pinKey = 'app_pin';
  static const _bioKey = 'bio_enabled';

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

  /// Enroll PIN
  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Remove PIN
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  /// Check if a PIN is set
  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinKey)) != null;
  }

  /// Validate a PIN
  Future<bool> validatePin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  /// Perform biometric auth
  Future<bool> authenticateBiometric() async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      return false;
    } finally {
      _authenticating = false;
    }
  }
}
