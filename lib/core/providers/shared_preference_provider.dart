import 'dart:collection';

import 'package:mudra_manager/core/services/auto_backup_service.dart';
import 'package:mudra_manager/features/sms/domain/detection_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  SharedPrefsUtil._(this._prefs);

  static late SharedPrefsUtil instance;
  static const _lastBackupKey = 'last_backup_date';
  static const _lowBalanceThresholdKey = 'low_balance_threshold';
  static const _setSmsImportEnabledKey = 'sms_import_enabled';
  static const _hasSeenHelpGuideKey = 'has_seen_help_guide';
  static const _lastDailyCheckInKey = 'last_daily_check_in';
  final Queue<String> _hashQueue = Queue();
  final Set<String> _hashSet = {};
  bool _isUpdatingHashes = false;

  static const _processedHashesKey = 'processed_sms_hashes';
  static const _maxHashes = 500;

  final SharedPreferences _prefs;

  static void init(SharedPreferences prefs) {
    instance = SharedPrefsUtil._(prefs);
    instance.initHashes();
  }

  Future<void> initHashes() async {
    final stored = _prefs.getStringList(_processedHashesKey) ?? [];

    _hashQueue.clear();
    _hashSet.clear();

    for (final h in stored) {
      _hashQueue.addLast(h);
      _hashSet.add(h);
    }
  }

  static const _accountDisplayStyleKey = 'account_display_style';

  String getAccountDisplayStyle() =>
      _prefs.getString(_accountDisplayStyleKey) ?? 'carousel';

  Future<void> setAccountDisplayStyle(String style) =>
      _prefs.setString(_accountDisplayStyleKey, style);

  // Save onboarding completion (also stamps timestamp)
  void setOnboardingComplete() {
    _prefs.setBool('onboarding_complete', true);
    _prefs.setInt('onboarding_completed_at', DateTime.now().millisecondsSinceEpoch);
  }

  // Check if onboarding is complete
  bool isOnboardingComplete() {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  // Save onboarding completion
  void setLanguage(String locale) {
    _prefs.setString('user_language', locale);
  }

  // Check if onboarding is complete
  String getLanguage() {
    return _prefs.getString('user_language') ?? 'en';
  }

  Future<void> storeProcessedHash(String hash) async {
    if (hash.isEmpty) return;

    // Prevent async interleaving
    while (_isUpdatingHashes) {
      await Future.delayed(const Duration(milliseconds: 1));
    }
    _isUpdatingHashes = true;

    try {
      if (_hashSet.contains(hash)) return;

      _hashSet.add(hash);
      _hashQueue.addLast(hash);

      if (_hashQueue.length > _maxHashes) {
        final oldest = _hashQueue.removeFirst();
        _hashSet.remove(oldest);
      }

      // Persist snapshot
      await _prefs.setStringList(
        _processedHashesKey,
        _hashQueue.toList(),
      );
    } finally {
      _isUpdatingHashes = false;
    }
  }

  bool isAlreadyProcessed(String hash) {
    if (hash.isEmpty) return false;
    return _hashSet.contains(hash);
  }

  void clearProcessedHashes() {
    _hashQueue.clear();
    _hashSet.clear();
    _prefs.remove(_processedHashesKey);
  }

  void clear() {
    _prefs.clear();
  }

  Future<void> saveBackupDate(DateTime date) async {
    await _prefs.setString(_lastBackupKey, date.toIso8601String());
  }

  Future<DateTime?> getLastBackupDate() async {
    final date = _prefs.getString(_lastBackupKey);
    return date != null ? DateTime.tryParse(date) : null;
  }

  Future<Map<String, dynamic>> exportAll() async {
    final keys = _prefs.getKeys();
    final data = <String, dynamic>{};

    for (var key in keys) {
      final value = _prefs.get(key);
      data[key] = value;
    }

    return data;
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    for (var entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        _prefs.setDouble(key, value);
      } else if (value is bool) {
        _prefs.setBool(key, value);
      } else if (value is String) {
        _prefs.setString(key, value);
      } else if (value is List<String>) {
        _prefs.setStringList(key, value);
      }
    }
  }

  void setLowBalanceThreshold(double value) {
    _prefs.setDouble(_lowBalanceThresholdKey, value);
  }

  double getLowBalanceThreshold() {
    return _prefs.getDouble(_lowBalanceThresholdKey) ?? 100.0; // Default
  }

  void setSmsImportEnabled(bool value) {
    _prefs.setBool(_setSmsImportEnabledKey, value);
  }

  bool getSmsImportEnabled() {
    return _prefs.getBool(_setSmsImportEnabledKey) ?? false; // Default
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  bool hasSeenHelpGuide() {
    return _prefs.getBool(_hasSeenHelpGuideKey) ?? false;
  }

  Future<void> setHasSeenHelpGuide(bool value) async {
    await _prefs.setBool(_hasSeenHelpGuideKey, value);
  }

  DateTime? getLastDailyCheckIn() {
    final date = _prefs.getString(_lastDailyCheckInKey);
    return date != null ? DateTime.tryParse(date) : null;
  }

  Future<void> setLastDailyCheckIn(DateTime date) async {
    await _prefs.setString(_lastDailyCheckInKey, date.toIso8601String());
  }

  Future<void> setString(
    String configKey,
    String jsonEncode,
  ) async {
    await _prefs.setString(configKey, jsonEncode);
  }

  String? getString(String configKey) {
    return _prefs.getString(configKey);
  }

  bool getHighContrastMode() {
    return _prefs.getBool('high_contrast_mode') ?? false;
  }

  Future<void> setHighContrastMode(bool enabled) async {
    await _prefs.setBool('high_contrast_mode', enabled);
  }

  Future<void> setSmsBannerDismiss() async {
    await _prefs.setBool('sms_banner_dismissed', true);
  }

  bool getSmsbannerDismiss() {
    return _prefs.getBool('sms_banner_dismissed') ?? false;
  }

  DetectionSensitivity getDetectionMode() {
    final value = _prefs.getString('detection_mode') ?? 'balanced';
    return DetectionSensitivity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DetectionSensitivity.balanced,
    );
  }

  Future<void> setDetectionMode(DetectionSensitivity mode) async {
    await _prefs.setString('detection_mode', mode.name);
  }

  // App mode (simple / full)
  String getAppMode() => _prefs.getString('app_mode') ?? 'simple';
  Future<void> setAppMode(String mode) => _prefs.setString('app_mode', mode);

  // First transaction nudge
  bool getFirstTxnNudgeDismissed() => _prefs.getBool('first_txn_nudge_dismissed') ?? false;
  Future<void> setFirstTxnNudgeDismissed() => _prefs.setBool('first_txn_nudge_dismissed', true);

  // Starter transactions offered during onboarding
  bool getStarterTxnsOffered() => _prefs.getBool('starter_txns_offered') ?? false;
  Future<void> setStarterTxnsOffered() => _prefs.setBool('starter_txns_offered', true);

  // Onboarding completion timestamp
  DateTime? getOnboardingCompletedAt() {
    final ms = _prefs.getInt('onboarding_completed_at');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }
  Future<void> setOnboardingCompletedAt(DateTime dt) =>
      _prefs.setInt('onboarding_completed_at', dt.millisecondsSinceEpoch);

  // Auto backup frequency
  BackupFrequency getAutoBackupFrequency() {
    final value = _prefs.getString('auto_backup_frequency') ?? 'never';
    return BackupFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BackupFrequency.never,
    );
  }
  Future<void> setAutoBackupFrequency(String frequency) =>
      _prefs.setString('auto_backup_frequency', frequency);
}
