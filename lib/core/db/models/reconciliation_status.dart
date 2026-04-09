import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reconciliation_status.g.dart';

@collection
@JsonSerializable()
class ReconciliationStatus {
  Id id = Isar.autoIncrement;

  @Index()
  late int transactionId;

  @Index()
  late DateTime reconciliationDate;

  @enumerated
  late ReconciliationState state; // pending, verified, discrepancy

  String? notes;

  double? bankAmount; // Amount from bank statement for comparison

  ReconciliationStatus();

  ReconciliationStatus.create({
    required this.transactionId,
    required this.state,
    this.notes,
    this.bankAmount,
  }) {
    reconciliationDate = DateTime.now();
  }

  factory ReconciliationStatus.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationStatusFromJson(json);
  Map<String, dynamic> toJson() => _$ReconciliationStatusToJson(this);
}

enum ReconciliationState { pending, verified, discrepancy, unrecognized }
