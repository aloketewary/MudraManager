import 'package:equatable/equatable.dart';

/// Tax-saving opportunity detected from user profile.
class TaxOpportunity extends Equatable {
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

  @override
  List<Object?> get props => [type, status, evidence, estimatedSavings];
}

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