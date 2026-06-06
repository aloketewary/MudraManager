import 'dart:math' as math;

import 'package:mudra_manager/core/db/models/tax_deduction_profile.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';

// ─── Domain ─────────────────────────────────────────────────────────────────

enum OpportunityType {
  regime,
  nps,
  section80c,
  hra,
  homeLoan,
  medicalInsurance,
}

enum OpportunityStatus {
  quantified,
  notEvaluated,
}

enum OpportunityEvidence {
  computed,
  missingData,
}

class TaxOpportunity {
  final OpportunityType type;
  final OpportunityStatus status;
  final OpportunityEvidence evidence;
  final double? estimatedSavings;

  const TaxOpportunity({
    required this.type,
    required this.status,
    required this.evidence,
    this.estimatedSavings,
  });
}

/// Input context for opportunity detection.
/// Keeps method signature stable as inputs grow.
class TaxOpportunityContext {
  final TaxEstimate estimate;
  final TaxDeductionProfile? profile;

  const TaxOpportunityContext({
    required this.estimate,
    this.profile,
  });
}

// ─── Service ────────────────────────────────────────────────────────────────

/// Produces qualitative tax-saving opportunities from estimate + user profile.
/// Does NOT prescribe actions — only surfaces what might reduce tax.
/// Separated from TaxEstimationService to prevent responsibility creep.
class TaxOpportunityService {
  const TaxOpportunityService();

  List<TaxOpportunity> detect(TaxOpportunityContext context) {
    if (context.estimate.isZeroTax) return const [];

    return [
      _regimeOpportunity(context),
      _npsOpportunity(context),
      _section80cOpportunity(context),
      _hraOpportunity(context),
      _homeLoanOpportunity(context),
      _medicalInsuranceOpportunity(context),
    ];
  }

  TaxOpportunity _regimeOpportunity(TaxOpportunityContext context) {
    final estimate = context.estimate;
    if (estimate.oldRegimeEstimate == null) {
      return const TaxOpportunity(
        type: OpportunityType.regime,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    return TaxOpportunity(
      type: OpportunityType.regime,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: estimate.regimeSavings,
    );
  }

  TaxOpportunity _npsOpportunity(TaxOpportunityContext context) {
    final profile = context.profile;
    if (profile?.npsContribution == null) {
      return const TaxOpportunity(
        type: OpportunityType.nps,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    // NPS additional deduction: up to ₹50,000 under Section 80CCD(1B)
    // Only beneficial under old regime (new regime doesn't allow)
    // Savings = min(contribution, 50000) * marginal rate
    final contribution = profile!.npsContribution!;
    final deductible = math.min(contribution, 50000.0);
    final savings = deductible * _marginalRate(context.estimate);

    return TaxOpportunity(
      type: OpportunityType.nps,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: savings,
    );
  }

  TaxOpportunity _section80cOpportunity(TaxOpportunityContext context) {
    final profile = context.profile;
    if (profile?.section80cAmount == null) {
      return const TaxOpportunity(
        type: OpportunityType.section80c,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    // 80C deduction: up to ₹1,50,000 (old regime only)
    // Savings = min(amount, 150000) * marginal rate
    final amount = profile!.section80cAmount!;
    final deductible = math.min(amount, 150000.0);
    final savings = deductible * _marginalRate(context.estimate);

    return TaxOpportunity(
      type: OpportunityType.section80c,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: savings,
    );
  }

  TaxOpportunity _hraOpportunity(TaxOpportunityContext context) {
    final profile = context.profile;
    if (profile?.hraMonthly == null || profile?.rentPaid == null) {
      return const TaxOpportunity(
        type: OpportunityType.hra,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    // HRA exemption = min of:
    // 1. Actual HRA received
    // 2. Rent paid - 10% of basic (approximate basic = 50% of income)
    // 3. 50% of basic (metro) or 40% (non-metro) — assume non-metro
    final annualHra = profile!.hraMonthly! * 12;
    final annualRent = profile.rentPaid! * 12;
    final estimatedBasic = context.estimate.projectedAnnualIncome * 0.5;

    final exemption1 = annualHra;
    final exemption2 =
        (annualRent - estimatedBasic * 0.10).clamp(0, double.infinity);
    final exemption3 = estimatedBasic * 0.40;

    final hraExemption = [exemption1, exemption2, exemption3].reduce(math.min);
    final savings = hraExemption * _marginalRate(context.estimate);

    return TaxOpportunity(
      type: OpportunityType.hra,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: savings,
    );
  }

  TaxOpportunity _homeLoanOpportunity(TaxOpportunityContext context) {
    final profile = context.profile;
    if (profile?.homeLoanInterest == null) {
      return const TaxOpportunity(
        type: OpportunityType.homeLoan,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    // Section 24: up to ₹2,00,000 deduction on home loan interest
    final interest = profile!.homeLoanInterest!;
    final deductible = math.min(interest, 200000.0);
    final savings = deductible * _marginalRate(context.estimate);

    return TaxOpportunity(
      type: OpportunityType.homeLoan,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: savings,
    );
  }

  TaxOpportunity _medicalInsuranceOpportunity(TaxOpportunityContext context) {
    final profile = context.profile;
    if (profile?.medicalPremium == null) {
      return const TaxOpportunity(
        type: OpportunityType.medicalInsurance,
        status: OpportunityStatus.notEvaluated,
        evidence: OpportunityEvidence.missingData,
      );
    }

    // Section 80D: up to ₹25,000 (self) + ₹25,000 (parents)
    // We only know self premium — cap at ₹25,000
    final premium = profile!.medicalPremium!;
    final deductible = math.min(premium, 25000.0);
    final savings = deductible * _marginalRate(context.estimate);

    return TaxOpportunity(
      type: OpportunityType.medicalInsurance,
      status: OpportunityStatus.quantified,
      evidence: OpportunityEvidence.computed,
      estimatedSavings: savings,
    );
  }

  /// Approximate marginal tax rate based on taxable income (new regime).
  /// Used to estimate savings: deduction * marginal rate = tax saved.
  double _marginalRate(TaxEstimate estimate) {
    final taxable = estimate.taxableIncome;
    if (taxable <= 400000) return 0.0;
    if (taxable <= 800000) return 0.05;
    if (taxable <= 1200000) return 0.10;
    if (taxable <= 1600000) return 0.15;
    if (taxable <= 2000000) return 0.20;
    if (taxable <= 2400000) return 0.25;
    return 0.30;
  }
}
