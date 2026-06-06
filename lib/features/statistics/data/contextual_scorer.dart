import 'package:mudra_manager/core/db/models/transaction.dart';

/// Phase 3: Context-Aware Scoring System
/// Converts financial signals into contextual significance scores

class ContextualScorer {
  /// Core scoring function with explainability
  ScoredSignal scoreSignal(FinancialSignal signal, UserFinancialContext context) {
    final anomalyScore = _calculateAnomalyScore(signal, context);
    final impactScore = _calculateFinancialImpact(signal, context);
    final riskScore = _calculateRiskExposure(signal, context);
    final noveltyScore = _calculateNovelty(signal, context);
    final liquidityScore = _calculateLiquiditySensitivity(signal, context);

    final totalScore = _weightedScore(
      anomalyScore: anomalyScore,
      impactScore: impactScore,
      riskScore: riskScore,
      noveltyScore: noveltyScore,
      liquidityScore: liquidityScore,
      context: context,
    );

    return ScoredSignal(
      signal: signal,
      score: totalScore,
      explanation: _generateExplanation(signal, context, {
        'anomaly': anomalyScore,
        'impact': impactScore,
        'risk': riskScore,
        'novelty': noveltyScore,
        'liquidity': liquidityScore,
      }),
    );
  }

  /// Calculate anomaly relative to user's historical patterns
  double _calculateAnomalyScore(FinancialSignal signal, UserFinancialContext context) {
    switch (signal.type) {
      case SignalType.billAmount:
        return (signal.relativeToBaseline - 1.0).abs().clamp(0.0, 1.0);
      case SignalType.categorySpending:
        return (signal.relativeToBaseline - 1.0).abs().clamp(0.0, 1.0);
      case SignalType.budgetBreach:
        return signal.relativeToBaseline.clamp(0.0, 1.0);
      case SignalType.goalDelay:
        return (signal.metadata['daysDelayed'] as double / 30.0).clamp(0.0, 1.0);
      default:
        return 0.5;
    }
  }

  /// Calculate financial impact relative to user's capacity
  double _calculateFinancialImpact(FinancialSignal signal, UserFinancialContext context) {
    final impactRatio = signal.absoluteValue / context.avgMonthlyExpenses;
    
    // High-impact thresholds are context-dependent
    if (context.liquidityBufferDays < 7) {
      // Tight budget - smaller amounts matter more
      return (impactRatio * 2.0).clamp(0.0, 1.0);
    } else if (context.liquidityBufferDays > 30) {
      // Comfortable buffer - need larger amounts to matter
      return (impactRatio * 0.5).clamp(0.0, 1.0);
    } else {
      // Normal range
      return impactRatio.clamp(0.0, 1.0);
    }
  }

  /// Calculate risk exposure based on user's financial stability
  double _calculateRiskExposure(FinancialSignal signal, UserFinancialContext context) {
    final baseRisk = signal.type == SignalType.budgetBreach ? 0.8 :
                     signal.type == SignalType.billOverdue ? 0.9 :
                     signal.type == SignalType.goalDelay ? 0.3 : 0.5;

    // Amplify risk for unstable users
    if (context.stabilityScore < 0.5) {
      return (baseRisk * 1.5).clamp(0.0, 1.0);
    } else if (context.stabilityScore > 0.8) {
      return (baseRisk * 0.7).clamp(0.0, 1.0);
    }
    
    return baseRisk;
  }

  /// Calculate novelty - expected events score lower
  double _calculateNovelty(FinancialSignal signal, UserFinancialContext context) {
    final metadata = signal.metadata;
    
    // Recurring payments have low novelty
    if (metadata['isRecurring'] == true) return 0.1;
    
    // First-time occurrences have high novelty
    if (metadata['isFirstTime'] == true) return 0.9;
    
    // Deviation from pattern has medium-high novelty
    if (signal.relativeToBaseline > 1.3 || signal.relativeToBaseline < 0.7) {
      return 0.7;
    }
    
    return 0.3; // Default novelty for normal variations
  }

  /// Calculate liquidity sensitivity - tight budgets amplify all signals
  double _calculateLiquiditySensitivity(FinancialSignal signal, UserFinancialContext context) {
    if (context.liquidityBufferDays < 3) return 1.0; // Crisis mode
    if (context.liquidityBufferDays < 7) return 0.8; // Tight
    if (context.liquidityBufferDays < 15) return 0.6; // Cautious
    if (context.liquidityBufferDays > 30) return 0.2; // Comfortable
    return 0.4; // Normal
  }

  /// Weighted scoring with context-dependent weights
  double _weightedScore({
    required double anomalyScore,
    required double impactScore,
    required double riskScore,
    required double noveltyScore,
    required double liquidityScore,
    required UserFinancialContext context,
  }) {
    // Adjust weights based on user's financial state
    final weights = context.isStable 
        ? _StableUserWeights() 
        : _UnstableUserWeights();

    return (anomalyScore * weights.anomaly +
            impactScore * weights.impact +
            riskScore * weights.risk +
            noveltyScore * weights.novelty) * liquidityScore;
  }

  /// Generate human-readable explanation
  SignalExplanation _generateExplanation(
    FinancialSignal signal,
    UserFinancialContext context,
    Map<String, double> scores,
  ) {
    final primaryFactors = <String>[];
    final confidence = _calculateConfidence(scores);

    // Identify primary contributing factors
    if (scores['anomaly']! > 0.6) {
      final deviation = ((signal.relativeToBaseline - 1.0) * 100).abs().round();
      primaryFactors.add('${deviation}% ${deviation > 0 ? 'above' : 'below'} normal');
    }

    if (scores['impact']! > 0.5 && context.liquidityBufferDays < 15) {
      primaryFactors.add('significant given current liquidity buffer');
    }

    if (scores['novelty']! > 0.7) {
      primaryFactors.add('unusual pattern detected');
    }

    final why = primaryFactors.isEmpty 
        ? 'Normal variation within expected range'
        : primaryFactors.join(', ');

    return SignalExplanation(
      why: why,
      contributingFactors: primaryFactors,
      confidence: confidence,
    );
  }

  double _calculateConfidence(Map<String, double> scores) {
    // Higher confidence when multiple factors align
    final activeFactors = scores.values.where((s) => s > 0.4).length;
    return (activeFactors / scores.length).clamp(0.3, 0.95);
  }
}

/// Scoring weights for financially stable users
class _StableUserWeights {
  final double anomaly = 0.4;
  final double impact = 0.2;
  final double risk = 0.2;
  final double novelty = 0.2;
}

/// Scoring weights for financially unstable users
class _UnstableUserWeights {
  final double anomaly = 0.2;
  final double impact = 0.4;
  final double risk = 0.3;
  final double novelty = 0.1;
}

/// Financial signal with computed score and explanation
class ScoredSignal {
  final FinancialSignal signal;
  final double score;
  final SignalExplanation explanation;

  const ScoredSignal({
    required this.signal,
    required this.score,
    required this.explanation,
  });
}

/// Human-readable explanation for scoring decision
class SignalExplanation {
  final String why;
  final List<String> contributingFactors;
  final double confidence;

  const SignalExplanation({
    required this.why,
    required this.contributingFactors,
    required this.confidence,
  });
}

/// Base financial signal (Phase 2 - to be implemented)
class FinancialSignal {
  final SignalType type;
  final double absoluteValue;
  final double relativeToBaseline;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const FinancialSignal({
    required this.type,
    required this.absoluteValue,
    required this.relativeToBaseline,
    required this.timestamp,
    required this.metadata,
  });
}

enum SignalType {
  billAmount,
  budgetBreach,
  categorySpending,
  goalDelay,
  billOverdue,
  unusualTransaction,
  incomeVariation,
  subscriptionRenewal,
}

/// User financial context (Phase 1 - to be implemented)  
class UserFinancialContext {
  final double monthlyIncomeEstimate;
  final double avgMonthlyExpenses;
  final double liquidityBufferDays;
  final double spendingVolatilityIndex;
  final double debtRatio;
  final double autopayCoverage;
  final double stabilityScore;
  final bool isStable;

  const UserFinancialContext({
    required this.monthlyIncomeEstimate,
    required this.avgMonthlyExpenses,
    required this.liquidityBufferDays,
    required this.spendingVolatilityIndex,
    required this.debtRatio,
    required this.autopayCoverage,
    required this.stabilityScore,
    required this.isStable,
  });
}