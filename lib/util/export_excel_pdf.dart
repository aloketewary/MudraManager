import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/status_data_provider.dart' show StatsData;
import 'package:mudra_manager/service/advanced_analytics_service.dart' show FinancialHealthScore, CategoryTrend;
import 'package:mudra_manager/util/file_utils.dart' show saveExportedFile;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

Future<void> exportStatsToExcel(StatsData stats) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');
  final now = DateTime.now();

  final summary = excel['Summary'];
  summary.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
  summary.cell(CellIndex.indexByString('A1')).value = 'MUDRA MANAGER - FINANCIAL REPORT';
  summary.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 18,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: '#1976D2',
    fontColorHex: '#FFFFFF',
  );
  summary.appendRow([]);
  summary.appendRow(['Generated:', DateFormat('MMM dd, yyyy hh:mm a').format(now)]);
  summary.appendRow([]);
  
  summary.appendRow(['FINANCIAL OVERVIEW']);
  summary.cell(CellIndex.indexByString('A5')).cellStyle = CellStyle(bold: true, fontSize: 14);
  summary.appendRow(['Metric', 'Amount', '', 'Details']);
  summary.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(bold: true, backgroundColorHex: '#E3F2FD');
  summary.cell(CellIndex.indexByString('B6')).cellStyle = CellStyle(bold: true, backgroundColorHex: '#E3F2FD');
  summary.cell(CellIndex.indexByString('D6')).cellStyle = CellStyle(bold: true, backgroundColorHex: '#E3F2FD');
  
  summary.appendRow(['Total Income', stats.income, '', 'Money received']);
  summary.appendRow(['Total Expense', stats.expense, '', 'Money spent']);
  summary.appendRow(['Net Savings', stats.income - stats.expense, '', 'Income - Expense']);
  summary.appendRow(['Savings Rate', '${stats.savingsRate.toStringAsFixed(1)}%', '', 'Percentage saved']);
  summary.appendRow(['Avg Daily Spend', stats.avgDailySpend, '', 'Average per day']);
  summary.appendRow(['Transaction Count', stats.recent.length, '', 'Total transactions']);

  final categorySheet = excel['Categories'];
  categorySheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
  categorySheet.cell(CellIndex.indexByString('A1')).value = 'EXPENSE BY CATEGORY';
  categorySheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 16,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: '#1976D2',
    fontColorHex: '#FFFFFF',
  );
  categorySheet.appendRow([]);
  categorySheet.appendRow(['Rank', 'Category', 'Amount', 'Percentage']);
  for (int i = 0; i < 4; i++) {
    categorySheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2)).cellStyle = 
      CellStyle(bold: true, backgroundColorHex: '#E3F2FD');
  }
  
  final sortedCategories = stats.categoryData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  
  int rank = 1;
  for (var entry in sortedCategories) {
    final categoryName = stats.categoryDataMap[entry.key]?.name ?? 'Unknown';
    final percentage = stats.expense > 0 ? (entry.value / stats.expense * 100).toStringAsFixed(1) : '0.0';
    categorySheet.appendRow([rank++, categoryName, entry.value, '$percentage%']);
  }
  
  categorySheet.appendRow([]);
  categorySheet.appendRow(['TOTAL', '', stats.expense, '100%']);
  final totalRow = categorySheet.maxRows;
  for (int i = 0; i < 4; i++) {
    categorySheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: totalRow - 1)).cellStyle = 
      CellStyle(bold: true, backgroundColorHex: '#FFF3E0');
  }

  final txnSheet = excel['Transactions'];
  txnSheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
  txnSheet.cell(CellIndex.indexByString('A1')).value = 'ALL TRANSACTIONS';
  txnSheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    bold: true,
    fontSize: 16,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: '#1976D2',
    fontColorHex: '#FFFFFF',
  );
  txnSheet.appendRow([]);
  txnSheet.appendRow(['#', 'Date', 'Category', 'Description', 'Amount', 'Type']);
  for (int i = 0; i < 6; i++) {
    txnSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2)).cellStyle = 
      CellStyle(bold: true, backgroundColorHex: '#E3F2FD');
  }
  
  int txnNum = 1;
  for (var txn in stats.recent) {
    txn.category.loadSync();
    final dateStr = DateFormat('MMM dd, yyyy').format(txn.date);
    txnSheet.appendRow([
      txnNum++,
      dateStr,
      txn.category.value?.name ?? 'N/A',
      txn.description ?? '-',
      txn.amount,
      txn.isExpense ? 'Expense' : 'Income',
    ]);
  }

  final excelBytes = excel.encode();
  if (excelBytes != null) {
    final fileName = 'MudraManager_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
    await saveExportedFile(Uint8List.fromList(excelBytes), fileName, askUser: true);
  }
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
}) async {
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
          decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total Income:', style: pw.TextStyle(fontSize: 12)),
                pw.Text(ctxt.formatCurrencyWithSign(2, stats.income), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total Expense:', style: pw.TextStyle(fontSize: 12)),
                pw.Text(ctxt.formatCurrencyWithSign(2, stats.expense), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              ]),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Net Savings:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(ctxt.formatCurrencyWithSign(2, stats.income - stats.expense), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Savings Rate:', style: pw.TextStyle(fontSize: 12)),
                pw.Text('${stats.savingsRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        
        pw.Text('INCOME & EXPENSE TRENDS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
          child: pw.ClipRRect(horizontalRadius: 8, verticalRadius: 8, child: pw.Image(pdfImageLine, height: 220)),
        ),
        pw.SizedBox(height: 30),

        if (health != null && health.score > 0) ...[ 
          pw.Text('FINANCIAL HEALTH', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Score:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('${health.score}/100 (${health.rating})', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Savings Rate:', style: pw.TextStyle(fontSize: 12)),
                pw.Text('${health.savingsRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12)),
              ]),
            ]),
          ),
          pw.SizedBox(height: 30),
        ],

        if (predicted != null && predicted > 0) ...[
          pw.Text('SPENDING PREDICTION', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Next Month:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(ctxt.formatCurrencyWithSign(2, predicted), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.SizedBox(height: 30),
        ],

        if (categoryTrends != null && categoryTrends.isNotEmpty) ...[
          pw.Text('CATEGORY TRENDS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
            data: [
              ['Category', 'Amount', 'Change'],
              ...(categoryTrends.values.toList()..sort((a, b) => b.thisMonth.compareTo(a.thisMonth))).take(8).map((t) => [
                t.categoryName,
                ctxt.formatCurrencyWithSign(2, t.thisMonth),
                t.changePercent != 0 ? '${t.changePercent > 0 ? '+' : ''}${t.changePercent.toStringAsFixed(1)}%' : '-',
              ]),
            ],
          ),
          pw.SizedBox(height: 30),
        ],

        if (spendingByDay != null && spendingByDay.isNotEmpty) ...[
          pw.Text('SPENDING BY DAY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
            data: [
              ['Day', 'Avg Spending'],
              ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => [d, ctxt.formatCurrencyWithSign(2, spendingByDay[d] ?? 0)]),
            ],
          ),
          pw.SizedBox(height: 30),
        ],
        
        pw.Text('EXPENSE BREAKDOWN BY CATEGORY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
          data: [
            ['Rank', 'Category', 'Amount', '%'],
            ...(stats.categoryData.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).asMap().entries.map((entry) {
              final percentage = stats.expense > 0 ? (entry.value.value / stats.expense * 100).toStringAsFixed(1) : '0.0';
              return [
                '${entry.key + 1}',
                stats.categoryDataMap[entry.value.key]?.name ?? 'Unknown',
                ctxt.formatCurrencyWithSign(2, entry.value.value),
                '$percentage%',
              ];
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 30),
        
        pw.Text('RECENT TRANSACTIONS (Last 15)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(6),
          cellStyle: pw.TextStyle(fontSize: 9),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
          data: [
            ['Date', 'Category', 'Description', 'Amount', 'Type'],
            ...stats.recent.take(15).map((txn) {
              txn.category.loadSync();
              return [
                DateFormat('MMM dd').format(txn.date),
                txn.category.value?.name ?? 'N/A',
                (txn.description ?? '-').length > 25 ? '${(txn.description ?? '-').substring(0, 25)}...' : (txn.description ?? '-'),
                ctxt.formatCurrencyWithSign(2, txn.amount),
                txn.isExpense ? 'Exp' : 'Inc',
              ];
            }),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated by Mudra Manager on ${DateFormat('MMMM dd, yyyy \\\\at hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
  
  final pdfBytes = await pdf.save();
  final fileName = 'MudraManager_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
  await saveExportedFile(pdfBytes, fileName, askUser: true);
}
