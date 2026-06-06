import 'package:isar_community/isar.dart';

part 'tax_deduction_profile.g.dart';

/// User-declared tax deduction/investment profile.
/// Each field is nullable: null = not provided, 0 = explicitly none.
/// Used by TaxOpportunityService to produce quantified savings.
@collection
class TaxDeductionProfile {
  Id id = Isar.autoIncrement;

  /// Section 80C total (PPF, ELSS, LIC, etc.) — max ₹1.5L under old regime
  double? section80cAmount;

  /// NPS contribution (employee) — additional ₹50K deduction under old regime
  double? npsContribution;

  /// Employer NPS contribution — up to 10% of basic (both regimes)
  double? employerNps;

  /// Monthly HRA received from employer
  double? hraMonthly;

  /// Monthly rent paid (for HRA exemption calculation)
  double? rentPaid;

  /// Home loan interest paid per year — Section 24
  double? homeLoanInterest;

  /// Medical insurance premium (self + family) — Section 80D
  double? medicalPremium;

  /// When the profile was last updated
  late DateTime updatedAt;

  /// Financial year this profile applies to (e.g., 2025 for FY 2025-26)
  late int financialYear;
}
