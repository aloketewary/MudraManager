import 'package:mudra_plugin_sdk/plugin.dart';
import 'package:flutter/foundation.dart';

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
  final String currency;

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
    this.currency = '₹',
  });
}