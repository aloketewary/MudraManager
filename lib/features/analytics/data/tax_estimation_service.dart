import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/transaction_links.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Indian Income Tax estimation based on transaction data.
/// Uses New Tax Regime (default from FY 2024-25) slabs.
/// This is an ESTIMATE — not a substitute for professional tax advice.
class TaxEstimationService {
  final IsarService _isarService;

  TaxEstimationService(this._isarService);

  /// Estimate tax for a financial year (April to March).
  Future<TaxEstimate> estimateForFY(int startYear) async {
    final fyStart = DateTime(startYear, 4, 1);
    final fyEnd = DateTime(startYear + 1, 3, 31, 23, 59, 59);
    final now = DateTime.now();

    final isar = await _isarService.getInstance();

    // Fetch all transactions in the FY
    final txns = await isar.transactions
        .filter()
        .isTransferEqualTo(false)
        .dateBetween(fyStart, fyEnd)
        .findAll()
        .withLinks();

    double totalIncome = 0;
    double totalExpense = 0;
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};

    for (final txn in txns) {
      final catName = txn.category.value?.name ?? 'Other';
      if (txn.isExpense) {
        totalExpense += txn.baseAmount;
        expenseByCategory[catName] =
            (expenseByCategory[catName] ?? 0) + txn.baseAmount;
      } else {
        totalIncome += txn.baseAmount;
        incomeByCategory[catName] =
            (incomeByCategory[catName] ?? 0) + txn.baseAmount;
      }
    }

    // Project to full year if mid-FY
    final daysElapsed = now.isBefore(fyEnd)
        ? now.difference(fyStart).inDays + 1
        : fyEnd.difference(fyStart).inDays + 1;
    final totalDays = fyEnd.difference(fyStart).inDays + 1;
    final projectionFactor =
        daysElapsed > 0 ? totalDays / daysElapsed : 1.0;

    final projectedIncome = totalIncome * projectionFactor;
    final isProjected = now.isBefore(fyEnd);

    // Standard deduction (New Regime FY 2025-26)
    const standardDeduction = 75000.0;
    final taxableIncome =
        (projectedIncome - standardDeduction).clamp(0, double.infinity);

    // Calculate tax using new regime slabs
    final slabBreakdown = _calculateNewRegimeTax(taxableIncome.toDouble());
    final baseTax = slabBreakdown.fold<double>(0, (s, e) => s + e.tax);

    // Rebate u/s 87A: No tax if taxable income <= 12,00,000
    // (effective: income up to 12,75,000 with standard deduction)
    final rebate = taxableIncome <= 1200000 ? baseTax : 0.0;
    final taxAfterRebate = baseTax - rebate;

    // Health & Education Cess: 4%
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;

    // Monthly breakdown
    final monthlyTax = totalTax / 12;

    // Effective tax rate
    final effectiveRate =
        projectedIncome > 0 ? totalTax / projectedIncome * 100 : 0.0;

    return TaxEstimate(
      financialYear: 'FY $startYear-${(startYear + 1) % 100}',
      totalIncome: totalIncome,
      projectedAnnualIncome: projectedIncome,
      isProjected: isProjected,
      standardDeduction: standardDeduction,
      taxableIncome: taxableIncome.toDouble(),
      slabBreakdown: slabBreakdown,
      baseTax: baseTax,
      rebate: rebate,
      cess: cess,
      totalTax: totalTax,
      monthlyTax: monthlyTax,
      effectiveRate: effectiveRate,
      totalExpense: totalExpense * projectionFactor,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      daysElapsed: daysElapsed,
      totalDays: totalDays,
    );
  }

  /// New Tax Regime slabs (FY 2025-26, Budget 2025)
  List<TaxSlab> _calculateNewRegimeTax(double taxableIncome) {
    final slabs = <TaxSlab>[];
    var remaining = taxableIncome;

    final brackets = [
      (limit: 400000.0, rate: 0.0, label: '0 - 4L'),
      (limit: 400000.0, rate: 0.05, label: '4L - 8L'),
      (limit: 400000.0, rate: 0.10, label: '8L - 12L'),
      (limit: 400000.0, rate: 0.15, label: '12L - 16L'),
      (limit: 400000.0, rate: 0.20, label: '16L - 20L'),
      (limit: 400000.0, rate: 0.25, label: '20L - 24L'),
      (limit: double.infinity, rate: 0.30, label: 'Above 24L'),
    ];

    for (final bracket in brackets) {
      if (remaining <= 0) break;
      final taxable = remaining.clamp(0, bracket.limit);
      final tax = taxable * bracket.rate;
      slabs.add(TaxSlab(
        label: bracket.label,
        rate: bracket.rate * 100,
        taxableAmount: taxable.toDouble(),
        tax: tax,
      ));
      remaining -= taxable;
    }

    return slabs;
  }

  /// Get current FY start year (April-March)
  static int currentFYStartYear() {
    final now = DateTime.now();
    return now.month >= 4 ? now.year : now.year - 1;
  }
}

class TaxEstimate {
  final String financialYear;
  final double totalIncome;
  final double projectedAnnualIncome;
  final bool isProjected;
  final double standardDeduction;
  final double taxableIncome;
  final List<TaxSlab> slabBreakdown;
  final double baseTax;
  final double rebate;
  final double cess;
  final double totalTax;
  final double monthlyTax;
  final double effectiveRate;
  final double totalExpense;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final int daysElapsed;
  final int totalDays;

  TaxEstimate({
    required this.financialYear,
    required this.totalIncome,
    required this.projectedAnnualIncome,
    required this.isProjected,
    required this.standardDeduction,
    required this.taxableIncome,
    required this.slabBreakdown,
    required this.baseTax,
    required this.rebate,
    required this.cess,
    required this.totalTax,
    required this.monthlyTax,
    required this.effectiveRate,
    required this.totalExpense,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.daysElapsed,
    required this.totalDays,
  });

  bool get isZeroTax => totalTax <= 0;
  double get projectedSavings => projectedAnnualIncome - totalExpense;
  double get progressPercent => daysElapsed / totalDays;
}

class TaxSlab {
  final String label;
  final double rate;
  final double taxableAmount;
  final double tax;

  TaxSlab({
    required this.label,
    required this.rate,
    required this.taxableAmount,
    required this.tax,
  });
}
