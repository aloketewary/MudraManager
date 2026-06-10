import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';
import 'package:mudra_manager/features/statistics/data/financial_signal_generator.dart';

/// Phase 3: Context-Aware Scoring System
/// Converts financial signals into contextual significance scores

class ContextualScorer {
  ScoredSignal scoreSignal(
      FinancialSignal signal, UserFinancialContext context,) {
    final anomaly = _anomalyScore(signal);
    final impact = _impactScore(signal, context);
    final risk = _riskScore(signal, context);
    final novelty = _noveltyScore(signal);
    final liquidity = _liquidityMultiplier(context);

    final weights = context.isStable ? _stableWeights : _unstableWeights;

    final total = (anomaly * weights[0] +
            impact * weights[1] +
            risk * weights[2] +
            novelty * weights[3]) *
        liquidity;

    return ScoredSignal(
      signal: signal,
      score: total.clamp(0.0, 1.0),
      explanation: _explain(signal, context, anomaly, impact, novelty),
    );
  }

  // Stable: anomaly-weighted. Unstable: impact-weighted.
  static const _stableWeights = [0.4, 0.2, 0.2, 0.2];
  static const _unstableWeights = [0.2, 0.4, 0.3, 0.1];

  double _anomalyScore(FinancialSignal signal) {
    switch (signal.type) {
      case SignalType.budgetBreach:
        return signal.relativeToBaseline.clamp(0.0, 1.0);
      case SignalType.goalDelay:
        return ((signal.metadata['daysDelayed'] as num?)?.toDouble() ?? 0.0)
                .clamp(0.0, 30.0) /
            30.0;
      case SignalType.billAmountAnomaly:
      case SignalType.categorySpendingSpike:
        return (signal.relativeToBaseline - 1.0).abs().clamp(0.0, 1.0);
      default:
        return 0.5;
    }
  }

  double _impactScore(FinancialSignal signal, UserFinancialContext context) {
    if (context.avgMonthlyExpenses <= 0) return 0.5;
    final ratio = signal.absoluteValue / context.avgMonthlyExpenses;

    if (context.liquidityBufferDays < 7) return (ratio * 2.0).clamp(0.0, 1.0);
    if (context.liquidityBufferDays > 30) return (ratio * 0.5).clamp(0.0, 1.0);
    return ratio.clamp(0.0, 1.0);
  }

  double _riskScore(FinancialSignal signal, UserFinancialContext context) {
    final base = switch (signal.type) {
      SignalType.billOverdue => 0.9,
      SignalType.budgetBreach => 0.8,
      SignalType.incomeDelay => 0.85,
      SignalType.budgetPaceRisk => 0.6,
      SignalType.goalDelay => 0.3,
      _ => 0.5,
    };

    if (context.stabilityScore < 0.5) return (base * 1.5).clamp(0.0, 1.0);
    if (context.stabilityScore > 0.8) return (base * 0.7).clamp(0.0, 1.0);
    return base;
  }

  double _noveltyScore(FinancialSignal signal) {
    if (signal.metadata['isRecurring'] == true) return 0.1;
    if (signal.metadata['isFirstTime'] == true) return 0.9;
    if (signal.relativeToBaseline > 1.3 || signal.relativeToBaseline < 0.7) {
      return 0.7;
    }
    return 0.3;
  }

  double _liquidityMultiplier(UserFinancialContext context) {
    if (context.liquidityBufferDays < 3) return 1.0;
    if (context.liquidityBufferDays < 7) return 0.8;
    if (context.liquidityBufferDays < 15) return 0.6;
    if (context.liquidityBufferDays > 30) return 0.2;
    return 0.4;
  }

  SignalExplanation _explain(
    FinancialSignal signal,
    UserFinancialContext context,
    double anomaly,
    double impact,
    double novelty,
  ) {
    final factors = <String>[];

    if (anomaly > 0.6) {
      final pct = ((signal.relativeToBaseline - 1.0) * 100).abs().round();
      factors.add(
          '$pct% ${signal.relativeToBaseline > 1 ? 'above' : 'below'} normal',);
    }
    if (impact > 0.5 && context.liquidityBufferDays < 15) {
      factors.add('significant given current liquidity');
    }
    if (novelty > 0.7) {
      factors.add('unusual pattern');
    }

    return SignalExplanation(
      why: factors.isEmpty ? 'Normal variation' : factors.join(', '),
      contributingFactors: factors,
      confidence: (factors.length / 3.0).clamp(0.3, 0.95),
    );
  }
}

/// Scored signal with explanation
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

/// Human-readable explanation
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
