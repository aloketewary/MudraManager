import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin_manager.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/export_options_screen.dart';
import 'package:mudra_manager/features/gamification/domain/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/data/gamification_service.dart';

String formatExportCurrency(double amount) {
  return formatCurrency(amount, code: BaseCurrency.code, decimals: 2);
}

Future<void> exportStatsToExcel(StatsData stats, [GamificationService? gamificationService]) async {
  final exportData = ExportData(
    income: stats.income,
    expense: stats.expense,
    savingsRate: stats.savingsRate,
    avgDailySpend: stats.avgDailySpend,
    transactions: stats.recent,
    categoryData: stats.categoryData,
    categoryDataMap: stats.categoryDataMap,
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );

  final plugin = await ExportPluginManager.instance.getPlugin('Excel', 'Standard');
  if (plugin == null) return;

  final excelBytes = await plugin.generateExport(exportData);
  final fileName = 'MudraManager_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
  
  await saveExportedFile(excelBytes, fileName, askUser: true);
  await gamificationService?.track(GamificationEvent.reportExported);
}

// New function to show export options
Future<void> showExportOptions(BuildContext context, StatsData stats) async {
  final exportData = ExportData(
    income: stats.income,
    expense: stats.expense,
    savingsRate: stats.savingsRate,
    avgDailySpend: stats.avgDailySpend,
    transactions: stats.recent,
    categoryData: stats.categoryData,
    categoryDataMap: stats.categoryDataMap,
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ExportOptionsScreen(exportData: exportData),
    ),
  );
}

Future<void> exportStatsToPdf(
  BuildContext context,
  StatsData stats,
  Uint8List? pieImage,
  Uint8List lineImage, {
  FinancialHealthScore? health,
  double? predicted,
  Map<String, CategoryTrend>? categoryTrends,
  Map<String, double>? spendingByDay,
  GamificationService? gamificationService,
}) async {
  final exportData = ExportData(
    income: stats.income,
    expense: stats.expense,
    savingsRate: stats.savingsRate,
    avgDailySpend: stats.avgDailySpend,
    transactions: stats.recent,
    categoryData: stats.categoryData,
    categoryDataMap: stats.categoryDataMap,
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );

  final plugin = await ExportPluginManager.instance.getPlugin('PDF', 'Standard');
  if (plugin == null) return;

  final pdfBytes = await plugin.generateExport(exportData);
  final fileName = 'MudraManager_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
  
  await saveExportedFile(pdfBytes, fileName, askUser: true);
  await gamificationService?.track(GamificationEvent.reportExported);
}
