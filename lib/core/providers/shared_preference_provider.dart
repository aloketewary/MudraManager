import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  SharedPrefsUtil._(this._prefs);

  static late SharedPrefsUtil instance;
  static const _lastBackupKey = 'last_backup_date';
  static const _lowBalanceThresholdKey = 'low_balance_threshold';
  static const _setSmsImportEnabledKey = 'sms_import_enabled';
  static const _hasSeenHelpGuideKey = 'has_seen_help_guide';
  static const _lastDailyCheckInKey = 'last_daily_check_in';

  final SharedPreferences _prefs;

  static void init(SharedPreferences prefs) {
    instance = SharedPrefsUtil._(prefs);
  }

  // Save onboarding completion
  void setOnboardingComplete() {
    _prefs.setBool('onboarding_complete', true);
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

  void storeProcessedHash(String hash) {
    final hashes = _prefs.getStringList('processed_sms_hashes') ?? [];
    if (!hashes.contains(hash)) {
      hashes.add(hash);
      _prefs.setStringList('processed_sms_hashes', hashes);
    }
  }

  bool isAlreadyProcessed(String hash) {
    final hashes = _prefs.getStringList('processed_sms_hashes') ?? [];
    return hashes.contains(hash);
  }

  void clearProcessedHashes() {
    _prefs.remove('processed_sms_hashes');
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
}
