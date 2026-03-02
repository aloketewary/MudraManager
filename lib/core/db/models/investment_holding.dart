import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'account.dart';

part 'investment_holding.g.dart';

@collection
@JsonSerializable()
class InvestmentHolding {
  Id id = Isar.autoIncrement;

  @Index()
  final account = IsarLink<Account>();

  late String symbol; // AAPL, INFY, BTC, etc.
  late String name; // Apple Inc, Infosys, Bitcoin, etc.
  
  @enumerated
  late HoldingType type; // stock, mutualFund, crypto

  late double quantity; // Number of shares/units
  late double buyPrice; // Average buy price per unit
  late double currentPrice; // Current market price
  
  @Index()
  late DateTime purchaseDate;

  InvestmentHolding();

  InvestmentHolding.create({
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.purchaseDate,
  });

  double get totalCost => quantity * buyPrice;
  double get currentValue => quantity * currentPrice;
  double get gainLoss => currentValue - totalCost;
  double get gainLossPercent => (gainLoss / totalCost) * 100;

  factory InvestmentHolding.fromJson(Map<String, dynamic> json) =>
      _$InvestmentHoldingFromJson(json);
  Map<String, dynamic> toJson() => _$InvestmentHoldingToJson(this);
}

enum HoldingType { stock, mutualFund, crypto }
