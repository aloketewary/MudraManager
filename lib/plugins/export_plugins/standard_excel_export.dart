import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../export_plugin.dart';

class StandardExcelExportPlugin extends ExportPlugin {
  @override
  String get id => 'standard_excel_export';

  @override
  String get name => 'Standard Excel Export';

  @override
  String get version => '1.0.0';

  @override
  String get exportType => 'Excel';

  @override
  String get templateName => 'Standard';

  @override
  bool supportsTemplate(String templateType) => templateType == 'standard';

  @override
  Future<Uint8List> generateExport(ExportData data) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _createSummarySheet(excel, data);
    _createCategorySheet(excel, data);
    _createTransactionSheet(excel, data);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  void _createSummarySheet(Excel excel, ExportData data) {
    final summary = excel['Summary'];
    summary.cell(CellIndex.indexByString('A1')).value = 'FINANCIAL REPORT';
    summary.cell(CellIndex.indexByString('A3')).value = 'Total Income';
    summary.cell(CellIndex.indexByString('B3')).value = data.income;
    summary.cell(CellIndex.indexByString('A4')).value = 'Total Expense';
    summary.cell(CellIndex.indexByString('B4')).value = data.expense;
    summary.cell(CellIndex.indexByString('A5')).value = 'Net Savings';
    summary.cell(CellIndex.indexByString('B5')).value =
        data.income - data.expense;
  }

  void _createCategorySheet(Excel excel, ExportData data) {
    final categorySheet = excel['Categories'];
    categorySheet.cell(CellIndex.indexByString('A1')).value = 'Category';
    categorySheet.cell(CellIndex.indexByString('B1')).value = 'Amount';

    int row = 2;
    for (var entry in data.categoryData.entries) {
      categorySheet.cell(CellIndex.indexByString('A$row')).value =
          data.categoryDataMap[entry.key]?.name ?? 'Unknown';
      categorySheet.cell(CellIndex.indexByString('B$row')).value = entry.value;
      row++;
    }
  }

  void _createTransactionSheet(Excel excel, ExportData data) {
    final txnSheet = excel['Transactions'];
    txnSheet.cell(CellIndex.indexByString('A1')).value = 'Date';
    txnSheet.cell(CellIndex.indexByString('B1')).value = 'Amount';
    txnSheet.cell(CellIndex.indexByString('C1')).value = 'Type';

    int row = 2;
    for (var txn in data.transactions) {
      txnSheet.cell(CellIndex.indexByString('A$row')).value =
          DateFormat('dd/MM/yyyy').format(txn.date);
      txnSheet.cell(CellIndex.indexByString('B$row')).value = txn.amount;
      txnSheet.cell(CellIndex.indexByString('C$row')).value =
          txn.isExpense ? 'Expense' : 'Income';
      row++;
    }
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
