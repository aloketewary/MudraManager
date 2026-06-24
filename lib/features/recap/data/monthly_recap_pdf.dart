import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'monthly_recap_service.dart';

class MonthlyRecapPdf {
  static Future<Uint8List> generate(MonthlyRecapData data) async {
    final pdf = pw.Document();
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    final fallbackFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansDevanagari-Variable.ttf'),
    );
    final bengaliFallback = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansBengali-Variable.ttf'),
    );
    final theme = pw.ThemeData.withFont(
        base: font, fontFallback: [fallbackFont, bengaliFallback],);

    final monthName = safeDateFormat('MMMM yyyy').format(data.month);
    final now = DateTime.now();
    final c = data.currency;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header(monthName, data.userName),
          pw.SizedBox(height: 20),

          // Summary cards
          _summaryCards(data, c),
          pw.SizedBox(height: 12),

          // Financial Score
          _financialScore(data),
          pw.SizedBox(height: 16),

          // AI Insight
          if (!data.insight.isEmpty) ...[
            _insightSection(data.insight, c),
            pw.SizedBox(height: 16),
          ],

          // Achievements/Warnings
          if (data.achievements.isNotEmpty) ...[
            _achievementsSection(data.achievements),
            pw.SizedBox(height: 16),
          ],

          // Category Change Leaders
          if (data.categoryChanges.isNotEmpty) ...[
            _sectionTitle('Category Changes'),
            pw.SizedBox(height: 8),
            _categoryChangesSection(data.categoryChanges, c),
            pw.SizedBox(height: 16),
          ],

          // Budget Utilization
          if (data.budgetDetails.isNotEmpty) ...[
            _sectionTitle('Budgets That Matter'),
            pw.SizedBox(height: 8),
            _budgetTable(data, c),
            pw.SizedBox(height: 16),
          ],

          // Top Expenses
          if (data.topTransactions.isNotEmpty) ...[
            _sectionTitle('Biggest Expenses'),
            pw.SizedBox(height: 8),
            _transactionTable(data.topTransactions, c),
          ],
        ],
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Mudra Manager • Generated ${safeDateFormat('dd MMM yyyy').format(now)} • Page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ── HEADER ──
  static pw.Widget _header(String monthName, String? userName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo900,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Monthly Recap',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                monthName,
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.indigo200,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MUDRA MANAGER',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo300,
                  letterSpacing: 2,
                ),
              ),
              if (userName != null)
                pw.Text(
                  userName,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.indigo200,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECTION TITLE ──
  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  // ── SUMMARY CARDS ──
  static pw.Widget _summaryCards(MonthlyRecapData data, String c) {
    return pw.Row(
      children: [
        _summaryBox('Income', _fmt(data.totalIncome, c), PdfColors.green700),
        pw.SizedBox(width: 12),
        _summaryBox('Expense', _fmt(data.totalExpense, c), PdfColors.red700),
        pw.SizedBox(width: 12),
        _summaryBox(
          'Savings',
          _fmt(data.netSavings, c),
          data.netSavings >= 0 ? PdfColors.blue700 : PdfColors.red700,
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FINANCIAL SCORE ──
  static pw.Widget _financialScore(MonthlyRecapData data) {
    final delta = data.financialScoreDelta;
    final deltaStr =
        delta != 0 ? ' (${delta > 0 ? "+" : ""}$delta)' : '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Financial Score',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${data.financialScore}/100$deltaStr',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: data.financialScore >= 80
                  ? PdfColors.green700
                  : data.financialScore >= 50
                      ? PdfColors.orange700
                      : PdfColors.red700,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI INSIGHT ──
  static pw.Widget _insightSection(RecapInsight insight, String c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...insight.lines.map((line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '• $line',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),),
          if (insight.suggestedFocus != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Focus next month: ${insight.suggestedFocus}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ACHIEVEMENTS/WARNINGS ──
  static pw.Widget _achievementsSection(List<RecapAchievement> achievements) {
    return pw.Column(
      children: achievements
          .map((a) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 4),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: a.isWarning ? PdfColors.red50 : PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color:
                        a.isWarning ? PdfColors.red200 : PdfColors.green200,
                  ),
                ),
                child: pw.Text(
                  a.text,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color:
                        a.isWarning ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
              ),)
          .toList(),
    );
  }

  // ── CATEGORY CHANGES ──
  static pw.Widget _categoryChangesSection(
      List<CategoryChange> changes, String c,) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Category', 'This Month', 'Change'],
      data: changes
          .map((ch) => [
                ch.name,
                _fmt(ch.currentAmount, c),
                '${ch.increased ? "+" : "-"}${_fmt(ch.delta.abs(), c)}',
              ],)
          .toList(),
    );
  }

  // ── BUDGET TABLE ──
  static pw.Widget _budgetTable(MonthlyRecapData data, String c) {
    return pw.Column(
      children: data.budgetDetails
          .map(
            (b) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        b.name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${_fmt(b.spent, c)} / ${_fmt(b.allocated, c)}  (${b.percentage.toStringAsFixed(0)}%)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: b.overBudget
                              ? PdfColors.red700
                              : PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints?.maxWidth ?? 400;
                      final barW = w * (b.percentage / 100).clamp(0.0, 1.0);
                      return pw.Stack(
                        children: [
                          pw.Container(
                            height: 8,
                            width: w,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.Container(
                            height: 8,
                            width: barW,
                            decoration: pw.BoxDecoration(
                              color: b.overBudget
                                  ? PdfColors.red400
                                  : PdfColors.green400,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── TRANSACTION TABLE ──
  static pw.Widget _transactionTable(
    List<TransactionSummary> transactions,
    String c,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Date', 'Category', 'Description', 'Amount'],
      data: transactions
          .map(
            (t) => [
              safeDateFormat('dd MMM').format(t.date),
              t.category,
              t.description.isEmpty ? '-' : t.description,
              _fmt(t.amount, c),
            ],
          )
          .toList(),
    );
  }

  static String _fmt(double v, String c) =>
      '$c${NumberFormat('#,##0', 'en_IN').format(v.round())}';
}
