import 'dart:math' as math;

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/transaction_links.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/tax_planning/domain/tax_models.dart';

// ─── Service ────────────────────────────────────────────────────────────────

/// Indian Income Tax estimation based on transaction data.
/// Uses New Tax Regime (default from FY 2024-25) slabs.
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
    final monthlyIncome = <int, double>{};

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
        (projectedIncome - standardDeduction).clamp(0.0, double.infinity).toDouble();

    // Calculate tax using new regime slabs
    final slabBreakdown = _calculateNewRegimeTax(taxableIncome);
    final baseTax =
        slabBreakdown.fold<double>(0.0, (sum, slab) => sum + slab.tax);

    // Rebate u/s 87A
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

    // Calculate regime comparison
    final oldRegimeEst = _estimateOldRegime(projectedIncome);
    final oldRegimeBetter = oldRegimeEst.totalTax < totalTax;
    final regimeSavings = (totalTax - oldRegimeEst.totalTax).abs();

    return TaxEstimate(
      financialYear: 'FY $startYear-${(startYear + 1) % 100}',
      totalIncome: totalIncome,
      projectedAnnualIncome: projectedIncome,
      isProjected: isProjected,
      standardDeduction: standardDeduction,
      taxableIncome: taxableIncome,
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
      oldRegimeEstimate: oldRegimeEst,
      confidence: confidence,
      assumptions: assumptions,
      warnings: warnings,
      oldRegimeBetter: oldRegimeBetter,
      regimeSavings: regimeSavings,
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

    double variance = 0;
    if (monthlyIncome.length >= 2) {
      final values = monthlyIncome.values.toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      if (mean > 0) {
        final sumSquaredDiff =
            values.fold<double>(0, (s, v) => s + math.pow(v - mean, 2));
        final stdDev = math.sqrt(sumSquaredDiff / values.length);
        variance = stdDev / mean;
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
        (grossIncome - oldStdDeduction).clamp(0.0, double.infinity).toDouble();

    final slabs = _calculateOldRegimeTax(taxableIncome);
    final baseTax = slabs.fold<double>(0.0, (sum, slab) => sum + slab.tax);

    final rebate = taxableIncome <= 500000 ? baseTax : 0.0;
    final taxAfterRebate = baseTax - rebate;
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;

    return OldRegimeEstimate(
      standardDeduction: oldStdDeduction,
      taxableIncome: taxableIncome,
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

    final brackets = [
      (minIncome: 0.0, maxIncome: 250000.0, rate: 0.0, label: '0 - 2.5L'),
      (minIncome: 250000.0, maxIncome: 500000.0, rate: 5.0, label: '2.5L - 5L'),
      (minIncome: 500000.0, maxIncome: 1000000.0, rate: 20.0, label: '5L - 10L'),
      (minIncome: 1000000.0, maxIncome: double.infinity, rate: 30.0, label: 'Above 10L'),
    ];

    double remaining = taxableIncome;
    for (final bracket in brackets) {
      if (remaining <= 0) break;
      final taxableInSlab = (remaining < (bracket.maxIncome - bracket.minIncome))
          ? remaining
          : (bracket.maxIncome - bracket.minIncome);
      final tax = taxableInSlab * bracket.rate / 100;
      slabs.add(
        TaxSlab(
          label: bracket.label,
          rate: bracket.rate,
          minIncome: bracket.minIncome,
          maxIncome: bracket.maxIncome,
          taxableAmount: taxableInSlab,
          tax: tax,
        ),
      );
      remaining -= taxableInSlab;
    }

    return slabs;
  }

  /// New Tax Regime slabs (FY 2025-26, Budget 2025)
  List<TaxSlab> _calculateNewRegimeTax(double taxableIncome) {
    final slabs = <TaxSlab>[];

    final brackets = [
      (minIncome: 0.0, maxIncome: 400000.0, rate: 0.0, label: '0 - 4L'),
      (minIncome: 400000.0, maxIncome: 800000.0, rate: 5.0, label: '4L - 8L'),
      (minIncome: 800000.0, maxIncome: 1200000.0, rate: 10.0, label: '8L - 12L'),
      (minIncome: 1200000.0, maxIncome: 1600000.0, rate: 15.0, label: '12L - 16L'),
      (minIncome: 1600000.0, maxIncome: 2000000.0, rate: 20.0, label: '16L - 20L'),
      (minIncome: 2000000.0, maxIncome: 2400000.0, rate: 25.0, label: '20L - 24L'),
      (minIncome: 2400000.0, maxIncome: double.infinity, rate: 30.0, label: 'Above 24L'),
    ];

    double remaining = taxableIncome;
    for (final bracket in brackets) {
      if (remaining <= 0) break;
      final taxableInSlab = (remaining < (bracket.maxIncome - bracket.minIncome))
          ? remaining
          : (bracket.maxIncome - bracket.minIncome);
      final tax = taxableInSlab * bracket.rate / 100;
      slabs.add(
        TaxSlab(
          label: bracket.label,
          rate: bracket.rate,
          minIncome: bracket.minIncome,
          maxIncome: bracket.maxIncome,
          taxableAmount: taxableInSlab,
          tax: tax,
        ),
      );
      remaining -= taxableInSlab;
    }

    return slabs;
  }

  /// Get current FY start year (April-March)
  static int currentFYStartYear() {
    final now = DateTime.now();
    return now.month >= 4 ? now.year : now.year - 1;
  }
}