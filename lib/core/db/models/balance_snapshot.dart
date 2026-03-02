import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'account.dart';

part 'balance_snapshot.g.dart';

@collection
@JsonSerializable()
class BalanceSnapshot {
  Id id = Isar.autoIncrement;

  @Index()
  final account = IsarLink<Account>();

  @Index()
  late DateTime date;

  late double balance;

  BalanceSnapshot();

  BalanceSnapshot.create({
    required this.date,
    required this.balance,
  });

  factory BalanceSnapshot.fromJson(Map<String, dynamic> json) =>
      _$BalanceSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$BalanceSnapshotToJson(this);
}
