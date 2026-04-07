import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_plugin_sdk/plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';

abstract class ExportPlugin extends MudraPlugin {
  String get exportType; // 'PDF', 'Excel', 'CSV'
  String get templateName;
  Future<Uint8List> generateExport(ExportData data);
  bool supportsTemplate(String templateType);
}

class ExportData {
  final double income;
  final double expense;
  final double savingsRate;
  final double avgDailySpend;
  final List<dynamic> transactions;
  final Map<String, double> categoryData;
  final Map<String, dynamic> categoryDataMap;
  final DateTime startDate;
  final DateTime endDate;
  late final String currency;
  final String? userName;

  ExportData({
    required this.income,
    required this.expense,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.transactions,
    required this.categoryData,
    required this.categoryDataMap,
    required this.startDate,
    required this.endDate,
    String? currency,
    this.userName,
  }) : currency = currency ?? BaseCurrency.symbol;
}