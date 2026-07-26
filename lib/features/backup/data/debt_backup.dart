import 'package:mudra_manager/core/db/models/debt.dart';
import 'package:mudra_manager/features/backup/data/backable_model.dart';

class DebtBackup implements BackupAdapter<Debt> {
  final int id;
  final String name;
  final double balance;
  final double minimumPayment;
  final double interestRate;
  final double? extraPayment;
  final String? iconName;
  final int? colorValue;
  final bool isActive;
  final String creationDate;

  DebtBackup.fromDebt(Debt debt)
      : id = debt.id,
        name = debt.name,
        balance = debt.balance,
        minimumPayment = debt.minimumPayment,
        interestRate = debt.interestRate,
        extraPayment = debt.extraPayment,
        iconName = debt.iconName,
        colorValue = debt.colorValue,
        isActive = debt.isActive,
        creationDate = debt.creationDate.toIso8601String();

  DebtBackup()
      : id = 0,
        name = '',
        balance = 0.0,
        minimumPayment = 0.0,
        interestRate = 0.0,
        extraPayment = null,
        iconName = null,
        colorValue = null,
        isActive = true,
        creationDate = DateTime.now().toIso8601String();

  @override
  Map<String, dynamic> toBackupJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'minimumPayment': minimumPayment,
        'interestRate': interestRate,
        'extraPayment': extraPayment,
        'iconName': iconName,
        'colorValue': colorValue,
        'isActive': isActive,
        'creationDate': creationDate,
      };

  @override
  Debt fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    return Debt()
      ..id = json['id']
      ..name = json['name']
      ..balance = (json['balance'] as num).toDouble()
      ..minimumPayment = (json['minimumPayment'] as num).toDouble()
      ..interestRate = (json['interestRate'] as num).toDouble()
      ..extraPayment = (json['extraPayment'] as num?)?.toDouble()
      ..iconName = json['iconName'] as String?
      ..colorValue = json['colorValue'] as int?
      ..isActive = json['isActive'] as bool? ?? true
      ..creationDate = DateTime.parse(json['creationDate']);
  }
}
