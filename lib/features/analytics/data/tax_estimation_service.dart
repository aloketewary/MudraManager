import 'dart:math' as math;

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/transaction_links.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

// ─── Confidence & Assumptions ───────────────────────────────────────────────

/// Modeling decisions that affect the estimate.
enum TaxAssumption {
  projectedIncome,
  noDeductionsConsidered,
  noTdsConsidered,
  allIncomeTaxable,
  oldRegimeNoDeductions,
}

/// Data quality issues that affect reliability.
enum TaxWarning {
  insufficientData,
  highIncomeVariance,
  singleIncomeSource,
}

enum ConfidenceTier { low, medium, high }

class ConfidenceFactors {
  final double coveragePercent;
  final double incomeVariance;
  final int sourceCount;
  final int transactionVolume;

  const ConfidenceFactors({
    required this.coveragePercent,
    required this.incomeVariance,
    required this.sourceCount,
    required this.transactionVolume,
  });

  ConfidenceTier get tier {
    // Variance-weighted confidence: high variance degrades confidence
    // even with good coverage
    if (coveragePercent < 0.25 || transactionVolume < 5) {
      return ConfidenceTier.low;
    }
    if (incomeVariance > 0.5) {
      // CV > 50% = highly irregular income
      return coveragePercent > 0.75
          ? ConfidenceTier.medium
          : ConfidenceTier.low;
    }
    if (coveragePercent >= 0.75) return ConfidenceTier.high;
    return ConfidenceTier.medium;
  }
}

// ─── Service ────────────────────────────────────────────────────────────────

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
    final monthlyIncome = <int, double>{}; // month index → income

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
        // Track monthly income for variance
        final monthIdx = (txn.date.year - fyStart.year) * 12 +
            txn.date.month -
            fyStart.month;
        monthlyIncome[monthIdx] =
            (monthlyIncome[monthIdx] ?? 0) + txn.baseAmount;
      }
    }

    // Project to full year if mid-FY
    final daysElapsed = now.isBefore(fyEnd)
        ? now.difference(fyStart).inDays + 1
        : fyEnd.difference(fyStart).inDays + 1;
    final totalDays = fyEnd.difference(fyStart).inDays + 1;
    final projectionFactor = daysElapsed > 0 ? totalDays / daysElapsed : 1.0;

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

    // Compute confidence factors
    final confidence = _computeConfidence(
      daysElapsed: daysElapsed,
      totalDays: totalDays,
      monthlyIncome: monthlyIncome,
      incomeByCategory: incomeByCategory,
      incomeTxnCount: txns.where((t) => !t.isExpense).length,
    );

    // Derive assumptions & warnings
    final assumptions = _deriveAssumptions(isProjected: isProjected);
    final warnings = _deriveWarnings(confidence);

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
      oldRegimeEstimate: _estimateOldRegime(projectedIncome),
      confidence: confidence,
      assumptions: assumptions,
      warnings: warnings,
    );
  }

  ConfidenceFactors _computeConfidence({
    required int daysElapsed,
    required int totalDays,
    required Map<int, double> monthlyIncome,
    required Map<String, double> incomeByCategory,
    required int incomeTxnCount,
  }) {
    final coverage = daysElapsed / totalDays;

    // Coefficient of variation for monthly income
    double variance = 0;
    if (monthlyIncome.length >= 2) {
      final values = monthlyIncome.values.toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      if (mean > 0) {
        final sumSquaredDiff =
            values.fold<double>(0, (s, v) => s + math.pow(v - mean, 2));
        final stdDev = math.sqrt(sumSquaredDiff / values.length);
        variance = stdDev / mean; // CV
      }
    }

    return ConfidenceFactors(
      coveragePercent: coverage,
      incomeVariance: variance,
      sourceCount: incomeByCategory.length,
      transactionVolume: incomeTxnCount,
    );
  }

  List<TaxAssumption> _deriveAssumptions({required bool isProjected}) {
    return [
      if (isProjected) TaxAssumption.projectedIncome,
      TaxAssumption.noDeductionsConsidered,
      TaxAssumption.noTdsConsidered,
      TaxAssumption.allIncomeTaxable,
      TaxAssumption.oldRegimeNoDeductions,
    ];
  }

  List<TaxWarning> _deriveWarnings(ConfidenceFactors confidence) {
    return [
      if (confidence.transactionVolume < 5) TaxWarning.insufficientData,
      if (confidence.incomeVariance > 0.5) TaxWarning.highIncomeVariance,
      if (confidence.sourceCount <= 1) TaxWarning.singleIncomeSource,
    ];
  }

  /// Old Tax Regime estimation (simplified — no HRA/80C/80D input yet).
  OldRegimeEstimate _estimateOldRegime(double grossIncome) {
    const oldStdDeduction = 50000.0;
    final taxableIncome =
        (grossIncome - oldStdDeduction).clamp(0, double.infinity);

    final slabs = _calculateOldRegimeTax(taxableIncome.toDouble());
    final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);

    final rebate = taxableIncome <= 500000 ? baseTax : 0.0;
    final taxAfterRebate = baseTax - rebate;
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;

    return OldRegimeEstimate(
      standardDeduction: oldStdDeduction,
      taxableIncome: taxableIncome.toDouble(),
      slabBreakdown: slabs,
      baseTax: baseTax,
      rebate: rebate,
      cess: cess,
      totalTax: totalTax,
    );
  }

  /// Old Tax Regime slabs (unchanged since FY 2020-21)
  List<TaxSlab> _calculateOldRegimeTax(double taxableIncome) {
    final slabs = <TaxSlab>[];
    var remaining = taxableIncome;

    final brackets = [
      (limit: 250000.0, rate: 0.0, label: '0 - 2.5L'),
      (limit: 250000.0, rate: 0.05, label: '2.5L - 5L'),
      (limit: 500000.0, rate: 0.20, label: '5L - 10L'),
      (limit: double.infinity, rate: 0.30, label: 'Above 10L'),
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

// ─── Models ─────────────────────────────────────────────────────────────────

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
  final OldRegimeEstimate? oldRegimeEstimate;
  final ConfidenceFactors confidence;
  final List<TaxAssumption> assumptions;
  final List<TaxWarning> warnings;

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
    this.oldRegimeEstimate,
    required this.confidence,
    required this.assumptions,
    required this.warnings,
  });

  bool get isZeroTax => totalTax <= 0;
  double get projectedSavings => projectedAnnualIncome - totalExpense;
  double get progressPercent => daysElapsed / totalDays;

  ConfidenceTier get confidenceTier => confidence.tier;

  bool get oldRegimeBetter =>
      oldRegimeEstimate != null && oldRegimeEstimate!.totalTax < totalTax;
  double get regimeSavings => oldRegimeEstimate != null
      ? (totalTax - oldRegimeEstimate!.totalTax).abs()
      : 0;
}

class OldRegimeEstimate {
  final double standardDeduction;
  final double taxableIncome;
  final List<TaxSlab> slabBreakdown;
  final double baseTax;
  final double rebate;
  final double cess;
  final double totalTax;

  OldRegimeEstimate({
    required this.standardDeduction,
    required this.taxableIncome,
    required this.slabBreakdown,
    required this.baseTax,
    required this.rebate,
    required this.cess,
    required this.totalTax,
  });

  bool get isZeroTax => totalTax <= 0;
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
