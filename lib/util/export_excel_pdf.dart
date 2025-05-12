import 'dart:typed_data' show Uint8List;

import 'package:excel/excel.dart';
import 'package:mudra_manager/providers/status_data_provider.dart' show StatsData;
import 'package:mudra_manager/util/file_utils.dart' show saveExportedFile;
import 'package:pdf/widgets.dart' as pw;

Future<void> exportStatsToExcel(StatsData stats) async {
  final excel = Excel.createExcel();

  // Sheet: Summary
  final summary = excel['Summary'];
  summary.appendRow(['Total Income', stats.income]);
  summary.appendRow(['Total Expense', stats.expense]);

  // Sheet: Category Breakdown
  final categorySheet = excel['Category Breakdown'];
  categorySheet.appendRow(['Category', 'Amount']);
  stats.categoryData.forEach((categoryId, amount) {
    final categoryName = stats.categoryDataMap[categoryId]?.name ?? 'Unknown';
    categorySheet.appendRow([categoryName, amount]);
  });

  // Sheet: Recent Transactions
  final txnSheet = excel['Recent Transactions'];
  txnSheet.appendRow(['Date', 'Description', 'Amount', 'Type']);
  for (var txn in stats.recent) {
    txnSheet.appendRow([
      txn.date.toIso8601String(),
      txn.description ?? '',
      txn.amount,
      txn.isExpense ? 'Expense' : 'Income',
    ]);
  }

  // Save the file
  final excelBytes = excel.encode();
  if (excelBytes != null) {
    final uint8list = Uint8List.fromList(excelBytes);
    await saveExportedFile(uint8list, 'report_${DateTime
        .now()
        .millisecondsSinceEpoch}.xlsx', askUser: true);
  }

}

Future<void> exportStatsToPdf(StatsData stats) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('Mudra Statistics Report', style: pw.TextStyle(fontSize: 24)),
        pw.SizedBox(height: 20),
        pw.Text('Total Income: ₹${stats.income.toStringAsFixed(2)}'),
        pw.Text('Total Expense: ₹${stats.expense.toStringAsFixed(2)}'),
        pw.SizedBox(height: 20),
        pw.Text('Category Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          data: [
            ['Category', 'Amount'],
            ...stats.categoryData.entries.map((entry) => [
              stats.categoryDataMap[entry.key]?.name ?? 'Unknown',
              entry.value.toStringAsFixed(2)
            ])
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Recent Transactions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          data: [
            ['Date', 'Description', 'Amount', 'Type'],
            ...stats.recent.map((txn) => [
              txn.date.toLocal().toIso8601String(),
              txn.description ?? '',
              txn.amount.toStringAsFixed(2),
              txn.isExpense ? 'Expense' : 'Income'
            ])
          ],
        )
      ],
    ),
  );
  final pdfBytes = await pdf.save(); // from pdf package
  await saveExportedFile(pdfBytes, 'report_${DateTime.now().millisecondsSinceEpoch}.pdf', askUser: true);
}
