import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/tax_planning/data/tax_opportunity_service.dart';
import 'package:mudra_manager/features/tax_planning/domain/index.dart';

void main() {
  const service = TaxOpportunityService();

  group('TaxOpportunityService', () {
    test('returns empty list when zero tax', () {
      final ctx = _makeContext(totalTax: 0);
      final result = service.detect(ctx);
      expect(result, isEmpty);
    });

    test('returns 6 opportunities when tax > 0', () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);
      expect(result, hasLength(6));
    });

    test('regime is the only quantified opportunity without profile', () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);

      final quantified =
          result.where((o) => o.status == OpportunityStatus.quantified);
      expect(quantified, hasLength(1));
      expect(quantified.first.type, OpportunityType.regime);
    });

    test('regime has computed evidence', () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);

      final regime =
          result.singleWhere((o) => o.type == OpportunityType.regime);
      expect(regime.evidence, OpportunityEvidence.computed);
    });

    test('non-regime opportunities have no estimatedSavings without profile',
        () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);

      final nonRegime =
          result.where((o) => o.type != OpportunityType.regime);
      expect(
        nonRegime.every((o) => o.estimatedSavings == null),
        true,
      );
    });

    test('non-regime opportunities have missingData evidence without profile',
        () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);

      final nonRegime =
          result.where((o) => o.type != OpportunityType.regime);
      expect(
        nonRegime.every((o) => o.evidence == OpportunityEvidence.missingData),
        true,
      );
    });

    test('regime savings matches estimate.regimeSavings', () {
      final ctx = _makeContext(totalTax: 50000, regimeSavings: 12000);
      final result = service.detect(ctx);

      final regime =
          result.singleWhere((o) => o.type == OpportunityType.regime);
      expect(regime.estimatedSavings, 12000);
    });

    test('regime without oldRegimeEstimate is notEvaluated', () {
      final ctx = _makeContext(totalTax: 50000, hasOldRegime: false);
      final result = service.detect(ctx);

      final regime =
          result.singleWhere((o) => o.type == OpportunityType.regime);
      expect(regime.status, OpportunityStatus.notEvaluated);
      expect(regime.evidence, OpportunityEvidence.missingData);
      expect(regime.estimatedSavings, isNull);
    });

    test('all opportunity types are represented', () {
      final ctx = _makeContext(totalTax: 50000);
      final result = service.detect(ctx);

      final types = result.map((o) => o.type).toSet();
      expect(types, containsAll(OpportunityType.values));
    });
  });
}

TaxOpportunityContext _makeContext({
  double totalTax = 0,
  double regimeSavings = 18000,
  bool hasOldRegime = true,
}) {
  final estimate = TaxEstimate(
    financialYear: 'FY 2025-26',
    projectedAnnualIncome: 1500000,
    isProjected: false,
    standardDeduction: 75000,
    taxableIncome: 1425000,
    slabBreakdown: const [],
    baseTax: totalTax,
    rebate: 0,
    cess: 0,
    totalTax: totalTax,
    monthlyTax: totalTax / 12,
    effectiveRate: totalTax / 1500000 * 100,
    totalExpense: 800000,
    incomeByCategory: const {'Salary': 1500000},
    expenseByCategory: const {},
    daysElapsed: 365,
    totalDays: 365,
    oldRegimeEstimate: hasOldRegime
        ? OldRegimeEstimate(
            standardDeduction: 50000,
            taxableIncome: 1450000,
            slabBreakdown: const [],
            baseTax: totalTax + regimeSavings,
            rebate: 0,
            cess: 0,
            totalTax: totalTax + regimeSavings,
          )
        : null,
    confidence: const ConfidenceFactors(
      coveragePercent: 1.0,
      incomeVariance: 0,
      sourceCount: 1,
      transactionVolume: 12,
    ),
    assumptions: const [],
    warnings: const [], 
    oldRegimeBetter: true, 
    regimeSavings: regimeSavings, 
    totalIncome: 0,
  );
  return TaxOpportunityContext(estimate: estimate);
}
