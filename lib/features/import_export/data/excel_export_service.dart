import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class ExcelExportService {
  static Future<Uint8List> exportTransactions({
    required IsarService isarService,
    DateTime? startDate,
    DateTime? endDate,
    String currencyCode = 'INR',
  }) async {
    final isar = await isarService.getInstance();
    final start = startDate ?? DateTime(2000);
    final end = endDate ?? DateTime.now();

    final transactions = await isar.transactions
        .where()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();

    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Transactions'];

    // Header
    final headers = [
      'Date', 'Time', 'Amount', 'Currency', 'Type',
      'Category', 'Account', 'Description', 'Tags',
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }

    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    for (int r = 0; r < transactions.length; r++) {
      final txn = transactions[r];
      final row = r + 1;

      final type = txn.isTransfer ? 'Transfer' : txn.isExpense ? 'Expense' : 'Income';

      await txn.tags.load();
      final tags = txn.tags.map((t) => t.name).join(', ');

      final values = <dynamic>[
        dateFmt.format(txn.date),
        timeFmt.format(txn.date),
        txn.amount,
        currencyCode,
        type,
        txn.category.value?.name ?? '',
        txn.account.value?.name ?? '',
        txn.description ?? '',
        tags,
      ];

      for (int i = 0; i < values.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = TextCellValue(values[i]);
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }
}
