import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../export_plugin.dart';

class StandardPdfExportPlugin extends ExportPlugin {
  @override
  String get id => 'standard_pdf_export';
  
  @override
  String get name => 'Standard PDF Export';
  
  @override
  String get version => '1.0.0';
  
  @override
  String get exportType => 'PDF';
  
  @override
  String get templateName => 'Standard';

  @override
  bool supportsTemplate(String templateType) => templateType == 'standard';

  @override
  Future<Uint8List> generateExport(ExportData data) async {
    final pdf = pw.Document();
    final font = await _loadFont();
    
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 20),
          _buildSummary(data),
          pw.SizedBox(height: 20),
          _buildCategoryTable(data),
        ],
      ),
    );
    
    return pdf.save();
  }

  Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  pw.Widget _buildHeader(ExportData data) {
    return pw.Header(
      level: 0,
      child: pw.Text(
        'FINANCIAL REPORT',
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummary(ExportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Total Income', '${data.currency}${data.income.toStringAsFixed(2)}'),
          _buildSummaryRow('Total Expense', '${data.currency}${data.expense.toStringAsFixed(2)}'),
          _buildSummaryRow('Net Savings', '${data.currency}${(data.income - data.expense).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildCategoryTable(ExportData data) {
    return pw.TableHelper.fromTextArray(
      headers: ['Category', 'Amount'],
      data: data.categoryData.entries.map((entry) => [
        data.categoryDataMap[entry.key]?.name ?? 'Unknown',
        '${data.currency}${entry.value.toStringAsFixed(2)}',
      ]).toList(),
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}