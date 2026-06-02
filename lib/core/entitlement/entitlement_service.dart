import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/constants/env.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

/// Keys used in [AppConfig] to persist entitlement state.
abstract class _Keys {
  static const isPro = 'ent_is_pro';
  static const source = 'ent_source'; // 'play_store' | 'promo'
  static const productId = 'ent_product_id';
  static const purchaseToken = 'ent_purchase_token';
  static const expiresAt = 'ent_expires_at';
  static const signature = 'ent_signature';
  static const grantedAt = 'ent_granted_at';

  // Grandfathered counts (snapshot at first upgrade-aware launch)
  static const gfAccounts = 'ent_gf_accounts';
  static const gfBudgets = 'ent_gf_budgets';
  static const gfGoals = 'ent_gf_goals';
  static const installDate = 'ent_install_date';
}

class EntitlementService {
  final IsarService _isarService;
  final _log = AppLog(getLogger(), 'Entitlement');

  EntitlementService(this._isarService);

  // ── Query ──────────────────────────────────────────────

  Future<bool> isPro() async {
    await _ensureDeviceSalt();
    final isar = await _isarService.getInstance();
    final record = await _getConfig(isar, _Keys.isPro);
    if (record?.boolValue != true) return false;

    // Verify signature hasn't been tampered with
    final sig = await _getConfig(isar, _Keys.signature);
    final token = await _getConfig(isar, _Keys.purchaseToken);
    final granted = await _getConfig(isar, _Keys.grantedAt);
    if (sig == null || token == null || granted == null) return false;

    final expected = _sign(
      '${token.stringValue}:${granted.dateValue?.millisecondsSinceEpoch}',
    );
    if (sig.stringValue != expected) {
      _log.w('Entitlement signature mismatch — possible tampering');
      return false;
    }

    // Check expiry for subscriptions
    final expires = await _getConfig(isar, _Keys.expiresAt);
    if (expires?.dateValue != null &&
        expires!.dateValue!.isBefore(DateTime.now())) {
      _log.i('Subscription expired');
      return false;
    }

    return true;
  }

  Future<bool> canAccess(ProFeature feature) async {
    if (await isPro()) return true;
    if (await isInTrialPeriod()) return true;

    switch (feature) {
      case ProFeature.unlimitedAccounts:
      case ProFeature.unlimitedBudgets:
      case ProFeature.unlimitedGoals:
      case ProFeature.unlimitedTrips:
        return true; // Limit checked separately via canCreate*
      default:
        return false;
    }
  }

  Future<bool> canCreateAccount() async {
    if (await isPro()) return true;
    if (await isInTrialPeriod()) return true;
    final count = await _countCollection<Account>();
    final gf = await _grandfathered(_Keys.gfAccounts);
    return count < FreeTierLimits.maxAccounts.clamp(gf, 999);
  }

  Future<bool> canCreateBudget() async {
    if (await isPro()) return true;
    if (await isInTrialPeriod()) return true;
    final count = await _countCollection<Budget>();
    final gf = await _grandfathered(_Keys.gfBudgets);
    return count < FreeTierLimits.maxBudgets.clamp(gf, 999);
  }

  Future<bool> canCreateGoal() async {
    if (await isPro()) return true;
    if (await isInTrialPeriod()) return true;
    final count = await _countCollection<Goal>();
    final gf = await _grandfathered(_Keys.gfGoals);
    return count < FreeTierLimits.maxGoals.clamp(gf, 999);
  }

  Future<bool> canCreateTrip() async {
    if (await isPro()) return true;
    if (await isInTrialPeriod()) return true;
    final isar = await _isarService.getInstance();
    final activeTrips = await isar.trips.filter().isActiveEqualTo(true).count();
    return activeTrips < FreeTierLimits.maxActiveTrips;
  }

  // ── Grant / Revoke ─────────────────────────────────────

  Future<void> grantPro({
    required String source,
    required String productId,
    required String purchaseToken,
    DateTime? expiresAt,
  }) async {
    final isar = await _isarService.getInstance();
    final now = DateTime.now();
    await _ensureDeviceSalt();
    final sig = _sign('$purchaseToken:${now.millisecondsSinceEpoch}');

    await isar.writeTxn(() async {
      await _putConfig(isar, _Keys.isPro, boolValue: true);
      await _putConfig(isar, _Keys.source, stringValue: source);
      await _putConfig(isar, _Keys.productId, stringValue: productId);
      await _putConfig(isar, _Keys.purchaseToken, stringValue: purchaseToken);
      await _putConfig(isar, _Keys.grantedAt, dateValue: now);
      await _putConfig(isar, _Keys.signature, stringValue: sig);
      if (expiresAt != null) {
        await _putConfig(isar, _Keys.expiresAt, dateValue: expiresAt);
      }
    });
    _log.i('Pro granted via $source ($productId)');
  }

  Future<void> revokePro() async {
    final isar = await _isarService.getInstance();
    await isar.writeTxn(() async {
      for (final key in [
        _Keys.isPro,
        _Keys.source,
        _Keys.productId,
        _Keys.purchaseToken,
        _Keys.expiresAt,
        _Keys.signature,
        _Keys.grantedAt,
      ]) {
        final existing =
            await isar.appConfigs.filter().keyEqualTo(key).findFirst();
        if (existing != null) await isar.appConfigs.delete(existing.id);
      }
    });
    _log.i('Pro revoked');
  }

  // ── Grandfathering ─────────────────────────────────────

  /// Call once on first launch after entitlement system is added.
  /// Snapshots existing counts so free-tier limits don't lock out
  /// existing users who already exceeded them.
  Future<void> snapshotGrandfatheredCounts() async {
    final isar = await _isarService.getInstance();

    // Only snapshot once
    final existing = await _getConfig(isar, _Keys.gfAccounts);
    if (existing != null) return;

    final accounts = await isar.accounts.filter().isActiveEqualTo(true).count();
    final budgets =
        await isar.budgets.filter().isArchivedEqualTo(false).count();
    final goals = await isar.goals.filter().isActiveEqualTo(true).count();

    await isar.writeTxn(() async {
      await _putConfig(isar, _Keys.gfAccounts, intValue: accounts);
      await _putConfig(isar, _Keys.gfBudgets, intValue: budgets);
      await _putConfig(isar, _Keys.gfGoals, intValue: goals);
    });
    _log.i('Grandfathered: $accounts accounts, $budgets budgets, $goals goals');
  }

  // ── Helpers ────────────────────────────────────────────

  static const _storage = FlutterSecureStorage();
  static const _deviceSaltKey = 'entitlement_device_salt';
  String? _deviceSalt;

  /// Initialize device-specific signing salt.
  Future<void> _ensureDeviceSalt() async {
    if (_deviceSalt != null) return;
    _deviceSalt = await _storage.read(key: _deviceSaltKey);
    if (_deviceSalt == null) {
      _deviceSalt = sha256
          .convert(utf8.encode(DateTime.now().toIso8601String()))
          .toString()
          .substring(0, 16);
      await _storage.write(key: _deviceSaltKey, value: _deviceSalt);
    }
  }

  /// Sign with both the static key AND a per-device salt.
  /// Attacker must have both APK + physical device access to forge.
  String _sign(String payload) {
    final deviceComponent = _deviceSalt ?? '';
    final key = utf8.encode('${Env.encryptKey}:$deviceComponent');
    final bytes = utf8.encode(payload);
    return Hmac(sha256, key).convert(bytes).toString().substring(0, 32);
  }

  Future<int> _grandfathered(String key) async {
    final isar = await _isarService.getInstance();
    final config = await _getConfig(isar, key);
    return config?.intValue ?? 0;
  }

  Future<int> _countCollection<T>() async {
    final isar = await _isarService.getInstance();
    if (T == Account) {
      return isar.accounts.filter().isActiveEqualTo(true).count();
    } else if (T == Budget) {
      return isar.budgets.filter().isArchivedEqualTo(false).count();
    } else if (T == Goal) {
      return isar.goals.filter().isActiveEqualTo(true).count();
    }
    return 0;
  }

  Future<AppConfig?> _getConfig(Isar isar, String key) {
    return isar.appConfigs.filter().keyEqualTo(key).findFirst();
  }

  Future<void> _putConfig(
    Isar isar,
    String key, {
    String? stringValue,
    int? intValue,
    bool? boolValue,
    DateTime? dateValue,
  }) async {
    final existing = await isar.appConfigs.filter().keyEqualTo(key).findFirst();
    final config = existing ?? AppConfig()
      ..key = key;
    config
      ..stringValue = stringValue
      ..intValue = intValue
      ..boolValue = boolValue
      ..dateValue = dateValue;
    await isar.appConfigs.put(config);
  }

  // ── Trial Period ─────────────────────────────────────

  /// Stamps install date once. Call during onboarding completion.
  Future<void> stampInstallDate() async {
    final isar = await _isarService.getInstance();
    final existing = await _getConfig(isar, _Keys.installDate);
    if (existing != null) return; // already stamped
    await isar.writeTxn(() async {
      await _putConfig(isar, _Keys.installDate, dateValue: DateTime.now());
    });
    _log.i('Install date stamped');
  }

  Future<bool> isInTrialPeriod() async {
    final isar = await _isarService.getInstance();
    final config = await _getConfig(isar, _Keys.installDate);
    if (config?.dateValue == null) return false;
    return DateTime.now().difference(config!.dateValue!).inDays < 90;
  }

  Future<int> trialDaysRemaining() async {
    final isar = await _isarService.getInstance();
    final config = await _getConfig(isar, _Keys.installDate);
    if (config?.dateValue == null) return 0;
    final remaining = 90 - DateTime.now().difference(config!.dateValue!).inDays;
    return remaining.clamp(0, 90);
  }
}
