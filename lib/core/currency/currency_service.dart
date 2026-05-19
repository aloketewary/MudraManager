import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/archived_transaction.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/services/app_config_service.dart';

const _kBaseCurrencyKey = 'base_currency';
const _kDefaultBase = 'INR';

/// Static accessor for places that can't use ref (services, plugins, callbacks).
class BaseCurrency {
  BaseCurrency._();
  static String _code = _kDefaultBase;
  static String get code => _code;
  static String get symbol => currencySymbol(_code);
  static IconData get icon => currencyIcon(_code);
  static void sync(String code) => _code = code;
}

class CurrencyService {
  final Isar _isar;
  final AppConfigService _config;

  /// In-memory rate cache. Populated on first access, invalidated on update.
  /// Accessible via [cachedRates] for hot paths that can't await.
  static Map<String, double>? _rateCache;

  CurrencyService(this._isar, this._config);

  /// Returns the cached rate map. Returns empty if not yet loaded.
  /// Call [loadRateCache] at startup to populate.
  static Map<String, double> get cachedRates => _rateCache ?? const {};

  /// Load all rates into memory. Call once at startup (deferred tier).
  Future<void> loadRateCache() async {
    _rateCache = await getAllRates();
  }

  /// Get a rate from cache (sync, no DB hit). Returns null if not cached.
  static double? getCachedRate(String currencyCode) =>
      _rateCache?[currencyCode];

  // ── Base currency ──────────────────────────────────────────────

  Future<String> getBaseCurrency() async =>
      await _config.getString(_kBaseCurrencyKey) ?? _kDefaultBase;

  Future<void> setBaseCurrency(String code) =>
      _config.setString(_kBaseCurrencyKey, code);

  // ── Rate lookup ────────────────────────────────────────────────

  Future<double?> getRate(String currencyCode) async {
    // Try cache first
    final cached = _rateCache?[currencyCode];
    if (cached != null) return cached;

    final rate = await _isar.exchangeRates
        .filter()
        .currencyCodeEqualTo(currencyCode)
        .findFirst();
    final value = rate?.rateToBase;
    // Populate cache entry
    if (value != null) {
      _rateCache ??= {};
      _rateCache![currencyCode] = value;
    }
    return value;
  }

  Future<Map<String, double>> getAllRates() async {
    final rates = await _isar.exchangeRates.where().findAll();
    return {for (final r in rates) r.currencyCode: r.rateToBase};
  }

  Future<List<ExchangeRate>> getAllExchangeRates() async {
    return _isar.exchangeRates.where().findAll();
  }

  // ── Conversion (use at transaction time) ───────────────────────

  /// Converts [amount] in [fromCurrency] to base currency.
  /// Returns (convertedAmount, rateUsed) or null if rate unavailable.
  Future<({double converted, double rate})?> convertToBase(
    double amount,
    String fromCurrency,
  ) async {
    final base = await getBaseCurrency();
    if (fromCurrency == base) return (converted: amount, rate: 1.0);

    final rate = await getRate(fromCurrency);
    if (rate == null) return null;

    return (converted: amount * rate, rate: rate);
  }

  /// Converts [amount] from one currency to another.
  Future<({double converted, double rate})?> convert(
    double amount,
    String from,
    String to,
  ) async {
    if (from == to) return (converted: amount, rate: 1.0);

    final fromRate = await getRate(from);
    final toRate = await getRate(to);
    if (fromRate == null || toRate == null) return null;

    // from → base → to
    final crossRate = fromRate / toRate;
    return (converted: amount * crossRate, rate: crossRate);
  }

  // ── Seed from bundled JSON ─────────────────────────────────────

  Future<void> seedIfEmpty() async {
    final count = await _isar.exchangeRates.count();
    if (count > 0) return;
    await seedFromAsset();
  }

  Future<void> seedFromAsset() async {
    final json = await rootBundle.loadString('assets/data/exchange_rates.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rates = (data['rates'] as Map<String, dynamic>).entries.map((e) {
      return ExchangeRate.create(
        currencyCode: e.key,
        rateToBase: (e.value as num).toDouble(),
      );
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.exchangeRates.putAll(rates);
    });
  }

  // ── Update rates (call when online) ────────────────────────────

  Future<void> updateRates(Map<String, double> freshRates) async {
    final now = DateTime.now();
    final rates = freshRates.entries.map((e) {
      return ExchangeRate.create(currencyCode: e.key, rateToBase: e.value)
        ..updatedAt = now;
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.exchangeRates.putAll(rates);
    });

    // Invalidate cache so next access picks up fresh rates
    _rateCache = null;
  }

  // ── Change base currency (archives all transactions) ───────────

  /// Returns the count of archived transactions.
  Future<int> changeBaseCurrency(String newBase) async {
    final oldBase = await getBaseCurrency();
    if (oldBase == newBase) return 0;

    final allTxns = await _isar.transactions.where().findAll().withDecryption();
    final now = DateTime.now();

    final archived = <ArchivedTransaction>[];
    for (final txn in allTxns) {
      await txn.account.load();
      await txn.category.load();
      final aTxn = ArchivedTransaction()
        ..originalTransactionId = txn.id
        ..date = txn.date
        ..amount = txn.amount
        ..isExpense = txn.isExpense
        ..description = txn.description
        ..currencyCode = txn.currencyCode
        ..convertedAmount = txn.convertedAmount
        ..rateUsed = txn.rateUsed
        ..isTransfer = txn.isTransfer
        ..accountName = txn.account.value?.name
        ..categoryName = txn.category.value?.name
        ..archivedFromBase = oldBase
        ..archivedToBase = newBase
        ..archivedAt = now;

      aTxn.encryptFields();
      archived.add(aTxn);
    }

    await _isar.writeTxn(() async {
      await _isar.archivedTransactions.putAll(archived);
      await _isar.transactions.clear();
    });

    await setBaseCurrency(newBase);
    return archived.length;
  }
}
