import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/status_data_provider.dart' show StatsData;
import 'package:mudra_manager/util/file_utils.dart' show saveExportedFile;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:pdf/pdf.dart';
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
    txnSheet.appendRow([txn.date.toIso8601String(), txn.description ?? '', txn.amount, txn.isExpense ? 'Expense' : 'Income']);
  }

  // Save the file
  final excelBytes = excel.encode();
  if (excelBytes != null) {
    final uint8list = Uint8List.fromList(excelBytes);
    await saveExportedFile(uint8list, 'report_${DateTime.now().millisecondsSinceEpoch}.xlsx', askUser: true);
  }
}

Future<void> exportStatsToPdf(BuildContext context, StatsData stats, Uint8List pieImage, Uint8List lineImage) async {
  final ctxt = AppLocalizations.of(context)!;
  final pdf = pw.Document(
    title: 'Mudra Manager Statistics Report',
    author: 'Mudra Manager App',
    subject: 'Statistics Report',
    pageMode: PdfPageMode.outlines,
  );
  final pdfImagePie = pw.MemoryImage(pieImage);
  final pdfImageLine = pw.MemoryImage(lineImage);
  final file = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final ttf = pw.Font.ttf(file.buffer.asByteData());

  final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);

  pdf.addPage(
    pw.MultiPage(
      theme: theme,
      build:
          (context) => [
            pw.Text('Mudra Manager Statistics Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text('Total Income: ${ctxt.formatCurrencyWithSign(2, stats.income)}'),
            pw.Text('Total Expense: ${ctxt.formatCurrencyWithSign(2, stats.expense)}'),
            pw.SizedBox(height: 20),
            pw.Text('Charts', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Image(pdfImagePie, height: 200),
            pw.SizedBox(height: 20),
            pw.Image(pdfImageLine, height: 200),
            pw.SizedBox(height: 20),
            pw.Text('Category Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              data: [
                ['Category', 'Amount'],
                ...stats.categoryData.entries.map(
                  (entry) => [stats.categoryDataMap[entry.key]?.name ?? 'Unknown', ctxt.formatCurrencyWithSign(2, entry.value)],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Recent Transactions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              data: [
                ['Date', 'Description', 'Amount', 'Type'],
                ...stats.recent.map(
                  (txn) => [
                    txn.date.toLocal().toIso8601String(),
                    txn.description ?? '',
                    ctxt.formatCurrencyWithSign(2, txn.amount),
                    txn.isExpense ? 'Expense' : 'Income',
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  final pdfBytes = await pdf.save(); // from pdf package
  await saveExportedFile(pdfBytes, 'report_${DateTime.now().millisecondsSinceEpoch}.pdf', askUser: true);
}
