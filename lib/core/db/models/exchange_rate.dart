import 'package:isar_community/isar.dart';

part 'exchange_rate.g.dart';

@collection
class ExchangeRate {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String currencyCode; // e.g. "USD", "EUR"

  late double rateToBase; // 1 unit of this currency = X units of base currency

  late DateTime updatedAt;

  ExchangeRate();

  ExchangeRate.create({
    required this.currencyCode,
    required this.rateToBase,
  }) : updatedAt = DateTime.now();
}
