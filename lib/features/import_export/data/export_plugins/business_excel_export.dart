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
        TextCellValue('BUSINESS FINANCIAL REPORT');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Period');
    sheet.cell(CellIndex.indexByString('B3')).value =
        TextCellValue('${DateFormat('MMM dd, yyyy').format(data.startDate)} - ${DateFormat('MMM dd, yyyy').format(data.endDate)}');

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('KEY METRICS');
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Total Revenue');
    sheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(data.income);
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Total Expenses');
    sheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(data.expense);
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Net Profit');
    sheet.cell(CellIndex.indexByString('B8')).value =
        DoubleCellValue(data.income - data.expense);
    sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Profit Margin');
    sheet.cell(CellIndex.indexByString('B9')).value =
        TextCellValue('${data.savingsRate.toStringAsFixed(2)}%');

    sheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Made with Mudra Manager • mudramanager.com');
  }

  void _createProfitLoss(Excel excel, ExportData data) {
    final sheet = excel['P&L Statement'];
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('PROFIT & LOSS STATEMENT');

    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('REVENUE');
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Income');
    sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(data.income);

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('EXPENSES');
    int row = 7;
    for (var entry in data.categoryData.entries) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(data.categoryDataMap[entry.key]?.name ?? 'Unknown');
      sheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(entry.value);
      row++;
    }

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Total Expenses');
    sheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(data.expense);
    row += 2;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('NET PROFIT');
    sheet.cell(CellIndex.indexByString('B$row')).value =
        DoubleCellValue(data.income - data.expense);
  }

  void _createCashFlow(Excel excel, ExportData data) {
    final sheet = excel['Cash Flow'];
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('CASH FLOW STATEMENT');

    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Cash Inflows');
    sheet.cell(CellIndex.indexByString('B3')).value = DoubleCellValue(data.income);
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Cash Outflows');
    sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(data.expense);
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Net Cash Flow');
    sheet.cell(CellIndex.indexByString('B5')).value =
        DoubleCellValue(data.income - data.expense);
  }

  void _createDetailedTransactions(Excel excel, ExportData data) {
    final sheet = excel['Transaction Details'];
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Description');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Category');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Amount');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Currency');
    sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Base Amount');
    sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('Type');

    int row = 2;
    for (var txn in data.transactions) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(DateFormat('dd/MM/yyyy').format(txn.date));
      sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(txn.description);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(txn.category.value?.name ?? 'Unknown');
      sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(txn.amount);
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(txn.currencyCode ?? data.currency);
      sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(txn.baseAmount);
      sheet.cell(CellIndex.indexByString('G$row')).value =
          TextCellValue(txn.isExpense ? 'Expense' : 'Income');
      row++;
    }
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
