import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../export_plugin.dart';

class BusinessPdfExportPlugin extends ExportPlugin {
  @override
  String get id => 'business_pdf_export';

  @override
  String get name => 'Business PDF Export';

  @override
  String get version => '1.0.0';

  @override
  String get exportType => 'PDF';

  @override
  String get templateName => 'Business';

  @override
  bool supportsTemplate(String templateType) => templateType == 'business';

  @override
  Future<Uint8List> generateExport(ExportData data) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    pdf.addPage(
      pw.MultiPage(
        theme: font,
        header: (context) => _buildHeader(data),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildExecutiveSummary(data),
          pw.NewPage(),
          _buildProfitLoss(data),
          pw.NewPage(),
          _buildCashFlow(data),
          pw.NewPage(),
          _buildTransactionDetails(data),
        ],
      ),
    );

    return pdf.save();
  }

  Future<pw.ThemeData> _loadFont() async {
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final fallback = pw.Font.ttf(
      await rootBundle
          .load('assets/fonts/NotoSansDevanagari-VariableFont_wdth,wght.ttf'),
    );
    return pw.ThemeData.withFont(base: font, fontFallback: [fallback]);
  }

  pw.Widget _buildHeader(ExportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BUSINESS FINANCIAL REPORT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${DateFormat('MMMM dd, yyyy').format(data.startDate)} - ${DateFormat('MMMM dd, yyyy').format(data.endDate)}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'CONFIDENTIAL',
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
      ),
    );
  }

  pw.Widget _buildExecutiveSummary(ExportData data) {
    final netProfit = data.income - data.expense;
    final profitMargin = data.income > 0 ? (netProfit / data.income) * 100 : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EXECUTIVE SUMMARY'),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                data.income,
                PdfColors.green,
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _buildMetricCard(
                'Total Expenses',
                data.expense,
                PdfColors.red,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard(
                'Net Profit',
                netProfit,
                netProfit >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _buildMetricCard(
                'Profit Margin',
                profitMargin.toDouble(),
                PdfColors.blue,
                suffix: '%',
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        _buildInsights(data),
      ],
    );
  }

  pw.Widget _buildProfitLoss(ExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PROFIT & LOSS STATEMENT'),
        pw.SizedBox(height: 20),
        _buildPLSection('REVENUE', [
          ['Total Income', data.income],
        ]),
        pw.SizedBox(height: 20),
        _buildPLSection(
          'EXPENSES',
          data.categoryData.entries
              .map(
                (e) =>
                    [data.categoryDataMap[e.key]?.name ?? 'Unknown', e.value],
              )
              .toList(),
        ),
        pw.SizedBox(height: 20),
        _buildPLSection(
          'NET RESULT',
          [
            ['NET PROFIT/LOSS', data.income - data.expense],
          ],
          isTotal: true,
        ),
      ],
    );
  }

  pw.Widget _buildCashFlow(ExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CASH FLOW STATEMENT'),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow(['Cash Flow Item', 'Amount'], isHeader: true),
            _buildTableRow([
              'Cash Inflows',
              '${data.currency}${data.income.toStringAsFixed(2)}',
            ]),
            _buildTableRow([
              'Cash Outflows',
              '${data.currency}${data.expense.toStringAsFixed(2)}',
            ]),
            _buildTableRow(
              [
                'Net Cash Flow',
                '${data.currency}${(data.income - data.expense).toStringAsFixed(2)}',
              ],
              isTotal: true,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTransactionDetails(ExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TRANSACTION DETAILS'),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FixedColumnWidth(80),
            4: const pw.FixedColumnWidth(60),
          },
          children: [
            _buildTableRow(
              ['Date', 'Description', 'Category', 'Amount', 'Type'],
              isHeader: true,
            ),
            ...data.transactions.map(
              (txn) => _buildTableRow([
                DateFormat('dd/MM/yy').format(txn.date),
                txn.description,
                txn.category.value?.name ?? 'Unknown',
                '${data.currency}${txn.amount.toStringAsFixed(2)}',
                txn.isExpense ? 'Expense' : 'Income',
              ]),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildMetricCard(
    String title,
    double value,
    PdfColor color, {
    String suffix = '',
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${value.toStringAsFixed(2)}$suffix',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPLSection(
    String title,
    List<List<dynamic>> items, {
    bool isTotal = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: items
              .map(
                (item) => _buildTableRow(
                  [
                    item[0].toString(),
                    '₹${(item[1] as double).toStringAsFixed(2)}',
                  ],
                  isTotal: isTotal,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  pw.TableRow _buildTableRow(
    List<String> cells, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.blue900)
          : isTotal
              ? const pw.BoxDecoration(color: PdfColors.grey100)
              : null,
      children: cells
          .map(
            (cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  color: isHeader ? PdfColors.white : PdfColors.black,
                  fontWeight: isHeader || isTotal
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  fontSize: isHeader ? 12 : 10,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildInsights(ExportData data) {
    final insights = <String>[];
    final netProfit = data.income - data.expense;

    if (netProfit > 0) {
      insights.add('• Positive cash flow of ₹${netProfit.toStringAsFixed(2)}');
    } else {
      insights.add(
        '• Negative cash flow of ₹${netProfit.abs().toStringAsFixed(2)}',
      );
    }

    if (data.categoryData.isNotEmpty) {
      final topCategory =
          data.categoryData.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
        '• Highest expense category: ${data.categoryDataMap[topCategory.key]?.name ?? 'Unknown'}',
      );
    }

    insights.add(
      '• Average daily spending: ₹${data.avgDailySpend.toStringAsFixed(2)}',
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KEY INSIGHTS',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...insights.map(
            (insight) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(insight, style: const pw.TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
