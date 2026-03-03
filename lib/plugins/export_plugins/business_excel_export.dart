import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../export_plugin.dart';

class BusinessExcelExportPlugin extends ExportPlugin {
  @override
  String get id => 'business_excel_export';

  @override
  String get name => 'Business Excel Export';

  @override
  String get version => '1.0.0';

  @override
  String get exportType => 'Excel';

  @override
  String get templateName => 'Business';

  @override
  bool supportsTemplate(String templateType) => templateType == 'business';

  @override
  Future<Uint8List> generateExport(ExportData data) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _createExecutiveSummary(excel, data);
    _createProfitLoss(excel, data);
    _createCashFlow(excel, data);
    _createDetailedTransactions(excel, data);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  void _createExecutiveSummary(Excel excel, ExportData data) {
    final sheet = excel['Executive Summary'];
    sheet.cell(CellIndex.indexByString('A1')).value =
        'BUSINESS FINANCIAL REPORT';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        backgroundColorHex: '#1976D2',
        fontColorHex: '#FFFFFF');

    sheet.cell(CellIndex.indexByString('A3')).value = 'Period';
    sheet.cell(CellIndex.indexByString('B3')).value =
        '${DateFormat('MMM dd, yyyy').format(data.startDate)} - ${DateFormat('MMM dd, yyyy').format(data.endDate)}';

    sheet.cell(CellIndex.indexByString('A5')).value = 'KEY METRICS';
    sheet.cell(CellIndex.indexByString('A6')).value = 'Total Revenue';
    sheet.cell(CellIndex.indexByString('B6')).value = data.income;
    sheet.cell(CellIndex.indexByString('A7')).value = 'Total Expenses';
    sheet.cell(CellIndex.indexByString('B7')).value = data.expense;
    sheet.cell(CellIndex.indexByString('A8')).value = 'Net Profit';
    sheet.cell(CellIndex.indexByString('B8')).value =
        data.income - data.expense;
    sheet.cell(CellIndex.indexByString('A9')).value = 'Profit Margin';
    sheet.cell(CellIndex.indexByString('B9')).value =
        '${data.savingsRate.toStringAsFixed(2)}%';
  }

  void _createProfitLoss(Excel excel, ExportData data) {
    final sheet = excel['P&L Statement'];
    sheet.cell(CellIndex.indexByString('A1')).value = 'PROFIT & LOSS STATEMENT';

    sheet.cell(CellIndex.indexByString('A3')).value = 'REVENUE';
    sheet.cell(CellIndex.indexByString('A4')).value = 'Total Income';
    sheet.cell(CellIndex.indexByString('B4')).value = data.income;

    sheet.cell(CellIndex.indexByString('A6')).value = 'EXPENSES';
    int row = 7;
    for (var entry in data.categoryData.entries) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          data.categoryDataMap[entry.key]?.name ?? 'Unknown';
      sheet.cell(CellIndex.indexByString('B$row')).value = entry.value;
      row++;
    }

    sheet.cell(CellIndex.indexByString('A$row')).value = 'Total Expenses';
    sheet.cell(CellIndex.indexByString('B$row')).value = data.expense;
    row += 2;

    sheet.cell(CellIndex.indexByString('A$row')).value = 'NET PROFIT';
    sheet.cell(CellIndex.indexByString('B$row')).value =
        data.income - data.expense;
  }

  void _createCashFlow(Excel excel, ExportData data) {
    final sheet = excel['Cash Flow'];
    sheet.cell(CellIndex.indexByString('A1')).value = 'CASH FLOW STATEMENT';

    sheet.cell(CellIndex.indexByString('A3')).value = 'Cash Inflows';
    sheet.cell(CellIndex.indexByString('B3')).value = data.income;
    sheet.cell(CellIndex.indexByString('A4')).value = 'Cash Outflows';
    sheet.cell(CellIndex.indexByString('B4')).value = data.expense;
    sheet.cell(CellIndex.indexByString('A5')).value = 'Net Cash Flow';
    sheet.cell(CellIndex.indexByString('B5')).value =
        data.income - data.expense;
  }

  void _createDetailedTransactions(Excel excel, ExportData data) {
    final sheet = excel['Transaction Details'];
    sheet.cell(CellIndex.indexByString('A1')).value = 'Date';
    sheet.cell(CellIndex.indexByString('B1')).value = 'Description';
    sheet.cell(CellIndex.indexByString('C1')).value = 'Category';
    sheet.cell(CellIndex.indexByString('D1')).value = 'Amount';
    sheet.cell(CellIndex.indexByString('E1')).value = 'Type';

    int row = 2;
    for (var txn in data.transactions) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          DateFormat('dd/MM/yyyy').format(txn.date);
      sheet.cell(CellIndex.indexByString('B$row')).value = txn.description;
      sheet.cell(CellIndex.indexByString('C$row')).value = txn.category.value?.name ?? 'Unknown';
      sheet.cell(CellIndex.indexByString('D$row')).value = txn.amount;
      sheet.cell(CellIndex.indexByString('E$row')).value = txn.isExpense ? 'Expense' : 'Income';
      row++;
    }
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
