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
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final fallbackFont = pw.Font.ttf(
      await rootBundle
          .load('assets/fonts/NotoSansDevanagari-VariableFont_wdth,wght.ttf'),
    );
    final theme =
        pw.ThemeData.withFont(base: font, fontFallback: [fallbackFont]);

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
          _summaryCards(data, c),
          pw.SizedBox(height: 16),

          // Month-over-month
          if (data.prevMonthIncome > 0 || data.prevMonthExpense > 0) ...[
            _momSection(data, c),
            pw.SizedBox(height: 16),
          ],

          _highlights(data, c),
          pw.SizedBox(height: 16),

          // Daily spending bar chart
          if (data.dailySpending.isNotEmpty) ...[
            _sectionTitle('Daily Spending'),
            pw.SizedBox(height: 8),
            _dailyChart(data),
            pw.SizedBox(height: 16),
          ],

          // Spending velocity
          _sectionTitle('Spending Pace'),
          pw.SizedBox(height: 8),
          _velocityBar(data, c),
          pw.SizedBox(height: 16),

          // Recurring vs one-time
          if (data.recurringExpense > 0 || data.oneTimeExpense > 0) ...[
            _sectionTitle('Recurring vs One-time'),
            pw.SizedBox(height: 8),
            _recurringSection(data, c),
            pw.SizedBox(height: 16),
          ],

          // Category breakdown
          if (data.topCategories.isNotEmpty) ...[
            _sectionTitle('Category Breakdown'),
            pw.SizedBox(height: 8),
            _categoryBreakdown(data.topCategories, c, PdfColors.indigo400),
            pw.SizedBox(height: 16),
          ],

          // Category frequency
          if (data.categoryByFrequency.isNotEmpty) ...[
            _sectionTitle('Most Frequent Categories'),
            pw.SizedBox(height: 8),
            _categoryFrequencyTable(data, c),
            pw.SizedBox(height: 16),
          ],

          // Income sources
          if (data.incomeCategories.isNotEmpty) ...[
            _sectionTitle('Income Sources'),
            pw.SizedBox(height: 8),
            _categoryBreakdown(data.incomeCategories, c, PdfColors.green400),
            pw.SizedBox(height: 16),
          ],

          // Account breakdown
          if (data.accountBreakdown.isNotEmpty) ...[
            _sectionTitle('Spending by Account'),
            pw.SizedBox(height: 8),
            _accountTable(data, c),
            pw.SizedBox(height: 16),
          ],

          // Budget utilization
          if (data.budgetDetails.isNotEmpty) ...[
            _sectionTitle('Budget Health'),
            pw.SizedBox(height: 8),
            _budgetTable(data, c),
            pw.SizedBox(height: 16),
          ],

          // Top expenses
          if (data.topTransactions.isNotEmpty) ...[
            _sectionTitle('Top Expenses'),
            pw.SizedBox(height: 8),
            _transactionTable(data.topTransactions, c),
            pw.SizedBox(height: 16),
          ],

          // Top income
          if (data.topIncomeTransactions.isNotEmpty) ...[
            _sectionTitle('Top Income'),
            pw.SizedBox(height: 8),
            _transactionTable(data.topIncomeTransactions, c),
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

  // ── MONTH-OVER-MONTH ──
  static pw.Widget _momSection(MonthlyRecapData data, String c) {
    String delta(double pct) =>
        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'vs Previous Month',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _momItem(
                'Income',
                _fmt(data.totalIncome, c),
                _fmt(data.prevMonthIncome, c),
                delta(data.incomeChange),
              ),
              pw.SizedBox(width: 12),
              _momItem(
                'Expense',
                _fmt(data.totalExpense, c),
                _fmt(data.prevMonthExpense, c),
                delta(data.expenseChange),
              ),
              pw.SizedBox(width: 12),
              _momItem(
                'Savings',
                _fmt(data.netSavings, c),
                _fmt(data.prevMonthSavings, c),
                delta(
                  data.prevMonthSavings != 0
                      ? (data.netSavings - data.prevMonthSavings) /
                          data.prevMonthSavings.abs() *
                          100
                      : 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _momItem(
    String label,
    String current,
    String prev,
    String change,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            current,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'was $prev  ($change)',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── HIGHLIGHTS ──
  static pw.Widget _highlights(MonthlyRecapData data, String c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Highlights',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _highlightItem('Transactions', '${data.transactionCount}'),
              _highlightItem('Avg Daily', _fmt(data.avgDailySpend, c)),
              _highlightItem(
                'Savings Rate',
                '${data.savingsRate.toStringAsFixed(1)}%',
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _highlightItem('Weekday Avg', _fmt(data.weekdayAvg, c)),
              _highlightItem('Weekend Avg', _fmt(data.weekendAvg, c)),
              _highlightItem(
                'Budgets Kept',
                '${data.budgetsKept}/${data.budgetsTotal}',
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _highlightItem(
                'Achievements',
                '${data.achievementsUnlocked} unlocked',
              ),
              _highlightItem('Streak', '${data.currentStreak} days'),
              _highlightItem('Best Streak', '${data.longestStreak} days'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _highlightItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── DAILY SPENDING CHART ──
  static pw.Widget _dailyChart(MonthlyRecapData data) {
    final daysInMonth = DateTime(data.month.year, data.month.month + 1, 0).day;
    final maxSpend =
        data.dailySpending.values.fold<double>(0, (a, b) => a > b ? a : b);

    return pw.Container(
      height: 60,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(daysInMonth, (i) {
          final day = i + 1;
          final amount = data.dailySpending[day] ?? 0;
          final fraction = maxSpend > 0 ? amount / maxSpend : 0.0;
          final isHigh = amount > data.avgDailySpend;
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 0.3),
              child: pw.Container(
                height: (fraction.clamp(0.02, 1.0) * 60),
                decoration: pw.BoxDecoration(
                  color: isHigh ? PdfColors.red300 : PdfColors.indigo300,
                  borderRadius: pw.BorderRadius.circular(1),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── SPENDING VELOCITY ──
  static pw.Widget _velocityBar(MonthlyRecapData data, String c) {
    final total = data.firstHalfSpend + data.secondHalfSpend;
    final firstPct = total > 0 ? (data.firstHalfSpend / total * 100) : 50;

    return pw.Column(
      children: [
        pw.LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints?.maxWidth ?? 400;
            final firstW = w * firstPct / 100;
            return pw.Row(
              children: [
                pw.Container(
                  height: 14,
                  width: firstW,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo400,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(3),
                      bottomLeft: pw.Radius.circular(3),
                    ),
                  ),
                ),
                pw.Container(
                  height: 14,
                  width: w - firstW,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal300,
                    borderRadius: pw.BorderRadius.only(
                      topRight: pw.Radius.circular(3),
                      bottomRight: pw.Radius.circular(3),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '1st Half: ${_fmt(data.firstHalfSpend, c)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              '2nd Half: ${_fmt(data.secondHalfSpend, c)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  // ── RECURRING VS ONE-TIME ──
  static pw.Widget _recurringSection(MonthlyRecapData data, String c) {
    final total = data.recurringExpense + data.oneTimeExpense;
    final recurPct = total > 0
        ? (data.recurringExpense / total * 100).toStringAsFixed(0)
        : '0';
    final onePct = total > 0
        ? (data.oneTimeExpense / total * 100).toStringAsFixed(0)
        : '0';

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Recurring',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _fmt(data.recurringExpense, c),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '$recurPct%',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'One-time',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _fmt(data.oneTimeExpense, c),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '$onePct%',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CATEGORY BREAKDOWN (reused for expense & income) ──
  static pw.Widget _categoryBreakdown(
    List<CategorySpend> categories,
    String c,
    PdfColor barColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: categories
          .map(
            (cat) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      cat.name,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = (constraints?.maxWidth ?? 200) *
                            (cat.percentage / 100).clamp(0.0, 1.0);
                        return pw.Stack(
                          children: [
                            pw.Container(
                              height: 14,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                            pw.Container(
                              height: 14,
                              width: barWidth,
                              decoration: pw.BoxDecoration(
                                color: barColor,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      _fmt(cat.amount, c),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '${cat.percentage.toStringAsFixed(1)}%',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── CATEGORY FREQUENCY TABLE ──
  static pw.Widget _categoryFrequencyTable(MonthlyRecapData data, String c) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Category', 'Transactions', 'Total'],
      data: data.categoryByFrequency
          .map((cat) => [cat.name, '${cat.count}x', _fmt(cat.totalAmount, c)])
          .toList(),
    );
  }

  // ── ACCOUNT TABLE ──
  static pw.Widget _accountTable(MonthlyRecapData data, String c) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Account', 'Spent', 'Share'],
      data: data.accountBreakdown
          .map(
            (a) => [
              a.name,
              _fmt(a.amount, c),
              '${a.percentage.toStringAsFixed(1)}%',
            ],
          )
          .toList(),
    );
  }

  // ── BUDGET UTILIZATION TABLE ──
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

  // ── TRANSACTION TABLE (reused for expense & income) ──
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
