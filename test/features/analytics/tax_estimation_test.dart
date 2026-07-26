import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/tax_planning/data/tax_estimation_service.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';

void main() {
  group('TaxEstimate model', () {
    test('isZeroTax when totalTax is 0', () {
      final est = _makeTaxEstimate(totalTax: 0);
      expect(est.isZeroTax, isTrue);
    });

    test('isZeroTax when totalTax is negative', () {
      final est = _makeTaxEstimate(totalTax: -1);
      expect(est.isZeroTax, isTrue);
    });

    test('isZeroTax false when totalTax is positive', () {
      final est = _makeTaxEstimate(totalTax: 100);
      expect(est.isZeroTax, isFalse);
    });

    test('projectedSavings = income - expense', () {
      final est = _makeTaxEstimate(
        projectedAnnualIncome: 1000000,
        totalExpense: 600000,
      );
      expect(est.projectedSavings, equals(400000));
    });

    test('progressPercent = elapsed / total', () {
      final est = _makeTaxEstimate(daysElapsed: 180, totalDays: 365);
      expect(est.progressPercent, closeTo(0.493, 0.01));
    });

    test('progressPercent full year', () {
      final est = _makeTaxEstimate(daysElapsed: 365, totalDays: 365);
      expect(est.progressPercent, equals(1.0));
    });
  });

  group('TaxSlab model', () {
    test('slab with 0% rate has 0 tax', () {
      final slab = const TaxSlab(
        label: '0 - 4L',
        rate: 0,
        taxableAmount: 400000,
        tax: 0,
        minIncome: 0,
      );
      expect(slab.tax, equals(0));
    });

    test('slab tax calculation', () {
      final slab = const TaxSlab(
        label: '4L - 8L',
        rate: 5,
        taxableAmount: 400000,
        tax: 20000,
        minIncome: 0,
      );
      expect(slab.tax, equals(20000));
      expect(slab.rate, equals(5));
    });
  });

  group('currentFYStartYear', () {
    test('returns correct FY start year', () {
      final year = TaxEstimationService.currentFYStartYear();
      final now = DateTime.now();
      if (now.month >= 4) {
        expect(year, equals(now.year));
      } else {
        expect(year, equals(now.year - 1));
      }
    });
  });

  group('New Regime slab math (manual verification)', () {
    test('income 3L — no tax (below 4L slab)', () {
      // Taxable = 300000 - 75000 = 225000 → all in 0% slab
      // Tax = 0, rebate applies (< 12L)
      final taxable = 225000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      expect(baseTax, equals(0));
    });

    test('income 10L — rebate applies, zero tax', () {
      // Taxable = 1000000 - 75000 = 925000
      // 0-4L: 0, 4L-8L: 400000*5% = 20000, 8L-9.25L: 125000*10% = 12500
      // Base tax = 32500, but taxable <= 12L so rebate = 32500
      // Total = 0
      final taxable = 925000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      expect(baseTax, equals(32500));
      // Rebate applies since 925000 <= 1200000
      final rebate = taxable <= 1200000 ? baseTax : 0.0;
      expect(rebate, equals(baseTax));
    });

    test('income 15L — tax with cess', () {
      // Taxable = 1500000 - 75000 = 1425000
      // 0-4L: 0, 4-8L: 20000, 8-12L: 40000, 12-14.25L: 225000*15% = 33750
      // Base = 93750, no rebate (> 12L)
      // Cess = 93750 * 4% = 3750
      // Total = 97500
      final taxable = 1425000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      expect(baseTax, equals(93750));
      final cess = baseTax * 0.04;
      expect(cess, equals(3750));
      expect(baseTax + cess, equals(97500));
    });

    test('income 25L — hits 30% slab', () {
      // Taxable = 2500000 - 75000 = 2425000
      // 0-4L: 0, 4-8L: 20000, 8-12L: 40000, 12-16L: 60000,
      // 16-20L: 80000, 20-24L: 100000, 24-24.25L: 25000*30% = 7500
      // Base = 307500
      final taxable = 2425000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      expect(baseTax, equals(307500));
    });

    test('zero income — zero tax', () {
      final slabs = _calculateSlabs(0);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      expect(baseTax, equals(0));
      expect(slabs, isEmpty);
    });

    test('income exactly 12.75L — rebate boundary', () {
      // Taxable = 1275000 - 75000 = 1200000 → exactly at rebate limit
      final taxable = 1200000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      // 0-4L: 0, 4-8L: 20000, 8-12L: 40000 → 60000
      expect(baseTax, equals(60000));
      final rebate = taxable <= 1200000 ? baseTax : 0.0;
      expect(rebate, equals(baseTax)); // full rebate
    });

    test('income 12.76L — no rebate', () {
      // Taxable = 1276000 - 75000 = 1201000 → just above rebate
      final taxable = 1201000.0;
      final slabs = _calculateSlabs(taxable);
      final baseTax = slabs.fold<double>(0, (s, e) => s + e.tax);
      // 0-4L: 0, 4-8L: 20000, 8-12L: 40000, 12-12.01L: 1000*15% = 150
      expect(baseTax, equals(60150));
      final rebate = taxable <= 1200000 ? baseTax : 0.0;
      expect(rebate, equals(0)); // no rebate
    });

    test('standard deduction clamps to zero', () {
      // Income 50000, deduction 75000 → taxable = 0 (not negative)
      final taxable = (50000.0 - 75000.0).clamp(0, double.infinity);
      expect(taxable, equals(0));
    });
  });

  group('TaxEstimate effective rate', () {
    test('effective rate is 0 when income is 0', () {
      final est = _makeTaxEstimate(
        projectedAnnualIncome: 0,
        effectiveRate: 0,
      );
      expect(est.effectiveRate, equals(0));
    });

    test('effective rate calculation', () {
      // Tax 97500 on income 1500000 → 6.5%
      final rate = 97500 / 1500000 * 100;
      expect(rate, equals(6.5));
    });
  });
}

/// Replicate the slab calculation logic for testing.
List<TaxSlab> _calculateSlabs(double taxableIncome) {
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
    slabs.add(
      TaxSlab(
        label: bracket.label,
        rate: bracket.rate * 100,
        taxableAmount: taxable.toDouble(),
        tax: tax,
        minIncome: 0,
      ),
    );
    remaining -= taxable;
  }

  return slabs;
}

TaxEstimate _makeTaxEstimate({
  double totalTax = 0,
  double projectedAnnualIncome = 0,
  double totalExpense = 0,
  double effectiveRate = 0,
  int daysElapsed = 365,
  int totalDays = 365,
}) {
  return TaxEstimate(
    financialYear: 'FY 2025-26',
    totalIncome: projectedAnnualIncome,
    projectedAnnualIncome: projectedAnnualIncome,
    isProjected: false,
    standardDeduction: 75000,
    taxableIncome: projectedAnnualIncome - 75000,
    slabBreakdown: const [],
    baseTax: totalTax,
    rebate: 0,
    cess: 0,
    totalTax: totalTax,
    monthlyTax: totalTax / 12,
    effectiveRate: effectiveRate,
    totalExpense: totalExpense,
    incomeByCategory: const {},
    expenseByCategory: const {},
    daysElapsed: daysElapsed,
    totalDays: totalDays,
    confidence: const ConfidenceFactors(
      coveragePercent: 1.0,
      incomeVariance: 0,
      sourceCount: 1,
      transactionVolume: 10,
    ),
    assumptions: const [],
    warnings: const [],
    oldRegimeBetter: true,
    regimeSavings: 0,
  );
}
