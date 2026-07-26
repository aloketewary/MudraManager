import 'dart:math' as math;
import 'package:equatable/equatable.dart';

// ─── Tax Slab ───────────────────────────────────────────────────────────────

/// Tax slab definition with rate and income range.
class TaxSlab extends Equatable {
  final String label;
  final double rate;
  final double minIncome;
  final double? maxIncome;
  final double taxableAmount;
  final double tax;

  const TaxSlab({
    required this.label,
    required this.rate,
    required this.minIncome,
    this.maxIncome,
    required this.taxableAmount,
    required this.tax,
  });

  @override
  List<Object?> get props => [label, rate, minIncome, maxIncome, taxableAmount, tax];

  double taxFor(double taxableAmount) {
    if (taxableAmount <= minIncome) return 0;
    final slabMax = maxIncome ?? double.infinity;
    final amountInSlab = (math.min(taxableAmount, slabMax) - minIncome).clamp(0, double.infinity);
    return amountInSlab * rate / 100;
  }
}

// ─── Confidence ─────────────────────────────────────────────────────────────

enum ConfidenceTier { low, medium, high }

class ConfidenceFactors extends Equatable {
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
    if (coveragePercent < 0.25 || transactionVolume < 5) {
      return ConfidenceTier.low;
    }
    if (incomeVariance > 0.5) {
      return coveragePercent > 0.75
          ? ConfidenceTier.medium
          : ConfidenceTier.low;
    }
    if (coveragePercent >= 0.75) return ConfidenceTier.high;
    return ConfidenceTier.medium;
  }

  @override
  List<Object?> get props => [coveragePercent, incomeVariance, sourceCount, transactionVolume];
}

// ─── Tax Estimate ───────────────────────────────────────────────────────────

class OldRegimeEstimate extends Equatable {
  final double standardDeduction;
  final double taxableIncome;
  final List<TaxSlab> slabBreakdown;
  final double baseTax;
  final double rebate;
  final double cess;
  final double totalTax;

  const OldRegimeEstimate({
    required this.standardDeduction,
    required this.taxableIncome,
    required this.slabBreakdown,
    required this.baseTax,
    required this.rebate,
    required this.cess,
    required this.totalTax,
  });

  bool get isZeroTax => totalTax <= 0;

  @override
  List<Object?> get props => [
        standardDeduction,
        taxableIncome,
        slabBreakdown,
        baseTax,
        rebate,
        cess,
        totalTax,
      ];
}

class TaxEstimate extends Equatable {
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
  final bool oldRegimeBetter;
  final double regimeSavings;

  const TaxEstimate({
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
    required this.oldRegimeBetter,
    required this.regimeSavings,
  });

  bool get isZeroTax => totalTax <= 0;
  double get projectedSavings => projectedAnnualIncome - totalExpense;
  double get progressPercent => daysElapsed / totalDays;

  ConfidenceTier get confidenceTier => confidence.tier;

  @override
  List<Object?> get props => [
        financialYear,
        totalIncome,
        projectedAnnualIncome,
        isProjected,
        standardDeduction,
        taxableIncome,
        slabBreakdown,
        baseTax,
        rebate,
        cess,
        totalTax,
        monthlyTax,
        effectiveRate,
        totalExpense,
        incomeByCategory,
        expenseByCategory,
        daysElapsed,
        totalDays,
        oldRegimeEstimate,
        confidence,
        assumptions,
        warnings,
        oldRegimeBetter,
        regimeSavings,
      ];
}

// ─── Enums ───────────────────────────────────────────────────────────────────

enum TaxAssumption {
  projectedIncome,
  noDeductionsConsidered,
  noTdsConsidered,
  allIncomeTaxable,
  oldRegimeNoDeductions,
}

enum TaxWarning {
  insufficientData,
  highIncomeVariance,
  singleIncomeSource,
}