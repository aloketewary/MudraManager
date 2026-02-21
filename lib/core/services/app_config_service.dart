import 'package:isar_community/isar.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AppConfigService {
  final Isar isar;

  AppConfigService(this.isar);

  Future<String?> getString(String key) async {
    final config = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return config?.stringValue;
  }

  Future<int?> getInt(String key) async {
    final config = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return config?.intValue;
  }

  Future<double?> getDouble(String key) async {
    final config = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return config?.doubleValue;
  }

  Future<bool?> getBool(String key) async {
    final config = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return config?.boolValue;
  }

  Future<DateTime?> getDate(String key) async {
    final config = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return config?.dateValue;
  }

  Future<void> setString(String key, String value) async {
    await _set(key, stringValue: value);
  }

  Future<void> setInt(String key, int value) async {
    await _set(key, intValue: value);
  }

  Future<void> setDouble(String key, double value) async {
    await _set(key, doubleValue: value);
  }

  Future<void> setBool(String key, bool value) async {
    await _set(key, boolValue: value);
  }

  Future<void> setDate(String key, DateTime value) async {
    await _set(key, dateValue: value);
  }

  Future<void> _set(
    String key, {
    String? stringValue,
    int? intValue,
    double? doubleValue,
    bool? boolValue,
    DateTime? dateValue,
  }) async {
    final config = AppConfig()
      ..key = key
      ..stringValue = stringValue
      ..intValue = intValue
      ..doubleValue = doubleValue
      ..boolValue = boolValue
      ..dateValue = dateValue;

    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });
  }
}
