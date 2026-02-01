import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/status_data_provider.dart' show StatsData;
import 'package:mudra_manager/util/file_utils.dart' show saveExportedFile;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportStatsToExcel(StatsData stats) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');

  // Sheet: Summary
  final summary = excel['Summary'];
  summary.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('B1'));
  summary.cell(CellIndex.indexByString('A1')).value = 'FINANCIAL SUMMARY REPORT';
  summary.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 16,
    horizontalAlign: HorizontalAlign.Center,
  );
  summary.appendRow([]);
  summary.appendRow(['Metric', 'Amount']);
  summary.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(bold: true);
  summary.cell(CellIndex.indexByString('B3')).cellStyle = CellStyle(bold: true);
  summary.appendRow(['Total Income', stats.income]);
  summary.appendRow(['Total Expense', stats.expense]);
  summary.appendRow(['Net Savings', stats.income - stats.expense]);
  summary.appendRow(['Savings Rate', '${stats.savingsRate.toStringAsFixed(1)}%']);
  summary.appendRow(['Avg Daily Spend', stats.avgDailySpend]);

  // Sheet: Category Breakdown
  final categorySheet = excel['Categories'];
  categorySheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('C1'));
  categorySheet.cell(CellIndex.indexByString('A1')).value = 'EXPENSE BY CATEGORY';
  categorySheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 16,
    horizontalAlign: HorizontalAlign.Center,
  );
  categorySheet.appendRow([]);
  categorySheet.appendRow(['Category', 'Amount', 'Percentage']);
  categorySheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(bold: true);
  categorySheet.cell(CellIndex.indexByString('B3')).cellStyle = CellStyle(bold: true);
  categorySheet.cell(CellIndex.indexByString('C3')).cellStyle = CellStyle(bold: true);
  
  final sortedCategories = stats.categoryData.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  for (var entry in sortedCategories) {
    final categoryName = stats.categoryDataMap[entry.key]?.name ?? 'Unknown';
    final percentage = stats.expense > 0 ? (entry.value / stats.expense * 100).toStringAsFixed(1) : '0.0';
    categorySheet.appendRow([categoryName, entry.value, '$percentage%']);
  }

  // Sheet: Recent Transactions
  final txnSheet = excel['Transactions'];
  txnSheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
  txnSheet.cell(CellIndex.indexByString('A1')).value = 'RECENT TRANSACTIONS';
  txnSheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 16,
    horizontalAlign: HorizontalAlign.Center,
  );
  txnSheet.appendRow([]);
  txnSheet.appendRow(['Date', 'Category', 'Description', 'Amount', 'Type']);
  for (int i = 0; i < 5; i++) {
    txnSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2)).cellStyle = CellStyle(bold: true);
  }
  
  for (var txn in stats.recent) {
    txn.category.loadSync();
    final dateStr = '${txn.date.day}/${txn.date.month}/${txn.date.year}';
    txnSheet.appendRow([
      dateStr,
      txn.category.value?.name ?? 'N/A',
      txn.description ?? '-',
      txn.amount,
      txn.isExpense ? 'Expense' : 'Income',
    ]);
  }

  final excelBytes = excel.encode();
  if (excelBytes != null) {
    final uint8list = Uint8List.fromList(excelBytes);
    await saveExportedFile(uint8list, 'MudraManager_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx', askUser: true);
  }
}

Future<void> exportStatsToPdf(BuildContext context, StatsData stats, Uint8List? pieImage, Uint8List lineImage) async {
  final ctxt = AppLocalizations.of(context)!;
  final pdf = pw.Document(
    title: 'Mudra Manager Financial Report',
    author: 'Mudra Manager',
    subject: 'Financial Statistics Report',
    pageMode: PdfPageMode.outlines,
  );
  final pdfImageLine = pw.MemoryImage(lineImage);
  final file = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final ttf = pw.Font.ttf(file.buffer.asByteData());
  final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);

  pdf.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MUDRA MANAGER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Financial Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now()), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 20),
        
        pw.Text('FINANCIAL SUMMARY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Income:', style: pw.TextStyle(fontSize: 12)),
                  pw.Text(ctxt.formatCurrencyWithSign(2, stats.income), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Expense:', style: pw.TextStyle(fontSize: 12)),
                  pw.Text(ctxt.formatCurrencyWithSign(2, stats.expense), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Net Savings:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(ctxt.formatCurrencyWithSign(2, stats.income - stats.expense), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Savings Rate:', style: pw.TextStyle(fontSize: 12)),
                  pw.Text('${stats.savingsRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        
        pw.Text('INCOME & EXPENSE TRENDS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(pdfImageLine, height: 220),
          ),
        ),
        pw.SizedBox(height: 30),
        
        pw.Text('EXPENSE BREAKDOWN BY CATEGORY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          data: [
            ['Category', 'Amount', 'Percentage'],
            ...stats.categoryData.entries.map((entry) {
              final percentage = stats.expense > 0 ? (entry.value / stats.expense * 100).toStringAsFixed(1) : '0.0';
              return [
                stats.categoryDataMap[entry.key]?.name ?? 'Unknown',
                ctxt.formatCurrencyWithSign(2, entry.value),
                '$percentage%',
              ];
            }),
          ],
        ),
        pw.SizedBox(height: 30),
        
        pw.Text('RECENT TRANSACTIONS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          data: [
            ['Date', 'Description', 'Amount', 'Type'],
            ...stats.recent.take(10).map((txn) {
              return [
                DateFormat('MMM dd, yyyy').format(txn.date),
                txn.description ?? '-',
                ctxt.formatCurrencyWithSign(2, txn.amount),
                txn.isExpense ? 'Expense' : 'Income',
              ];
            }),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated by Mudra Manager on ${DateFormat('MMMM dd, yyyy \\at hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
  
  final pdfBytes = await pdf.save();
  await saveExportedFile(pdfBytes, 'MudraManager_Report_${DateTime.now().millisecondsSinceEpoch}.pdf', askUser: true);
}
