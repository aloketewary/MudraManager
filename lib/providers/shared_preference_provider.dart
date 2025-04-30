import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  SharedPrefsUtil._(this._prefs);

  static late SharedPrefsUtil instance;

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
    _prefs.setBool('user_language', true);
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
}
