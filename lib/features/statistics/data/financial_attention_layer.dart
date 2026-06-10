import 'package:mudra_manager/features/statistics/data/contextual_scorer.dart';
import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';
import 'package:mudra_manager/features/statistics/data/financial_signal_generator.dart';

/// Phase 4: Financial Attention Layer
/// Determines what deserves user attention using contextual thresholds

class FinancialAttentionLayer {
  final ContextualScorer _scorer;

  FinancialAttentionLayer(this._scorer);

  List<AttentionItem> filterForAttention(
    List<FinancialSignal> signals,
    UserFinancialContext context,
  ) {
    final scored = signals
        .map((s) => _scorer.scoreSignal(s, context))
        .where((s) => s.score >= _threshold(s.signal.type, context))
        .toList();

    final items = scored.map((s) => _toAttentionItem(s, context)).toList()
      ..sort((a, b) {
        final typeCmp = a.type.index.compareTo(b.type.index);
        if (typeCmp != 0) return typeCmp;
        return b.priority.compareTo(a.priority);
      });

    return _applyBudget(items, context);
  }

  bool shouldRemainSilent(
      UserFinancialContext context, List<AttentionItem> items,) {
    if (items.any((i) => i.type == AttentionType.critical)) return false;
    if (context.isStable && items.length <= 1) return true;
    return false;
  }

  double _threshold(SignalType type, UserFinancialContext context) {
    final base = switch (type) {
      SignalType.billOverdue => 0.9,
      SignalType.budgetBreach => 0.7,
      SignalType.billDueSoon => 0.6,
      SignalType.budgetPaceRisk => 0.5,
      SignalType.goalDelay => 0.4,
      SignalType.billAmountAnomaly => 0.6,
      SignalType.categorySpendingSpike => 0.5,
      SignalType.incomeDelay => 0.8,
    };

    return context.isStable
        ? (base * 1.2).clamp(0.0, 0.95)
        : (base * 0.8).clamp(0.1, 1.0);
  }

  AttentionItem _toAttentionItem(
      ScoredSignal scored, UserFinancialContext context,) {
    final signal = scored.signal;

    return AttentionItem(
      id: '${signal.type.name}_${signal.timestamp.millisecondsSinceEpoch}',
      type: _attentionType(signal.type),
      title: _title(signal),
      message: scored.explanation.why,
      priority: scored.score *
          _typeMultiplier(signal.type) *
          (context.liquidityBufferDays < 7 ? 1.4 : 1.0),
      actionLabel: _actionLabel(signal.type),
      actionRoute: _route(signal),
    );
  }

  AttentionType _attentionType(SignalType type) => switch (type) {
        SignalType.billOverdue ||
        SignalType.incomeDelay =>
          AttentionType.critical,
        SignalType.budgetBreach ||
        SignalType.billDueSoon =>
          AttentionType.warning,
        SignalType.categorySpendingSpike => AttentionType.insight,
        _ => AttentionType.info,
      };

  double _typeMultiplier(SignalType type) => switch (type) {
        SignalType.billOverdue => 2.0,
        SignalType.incomeDelay => 1.9,
        SignalType.budgetBreach => 1.8,
        SignalType.billDueSoon => 1.5,
        SignalType.budgetPaceRisk => 1.3,
        SignalType.goalDelay => 1.2,
        SignalType.billAmountAnomaly => 1.1,
        SignalType.categorySpendingSpike => 1.0,
      };

  String _title(FinancialSignal signal) {
    final m = signal.metadata;
    return switch (signal.type) {
      SignalType.billOverdue =>
        '${m['billName']} overdue by ${m['daysOverdue']} days',
      SignalType.budgetBreach =>
        '${m['budgetName']} exceeded by ${(m['overspendPercent'] as num).round()}%',
      SignalType.billDueSoon =>
        '${m['billName']} due ${m['daysTillDue'] == 0 ? 'today' : 'in ${m['daysTillDue']} days'}',
      SignalType.goalDelay => '${m['goalName']} contribution behind',
      SignalType.budgetPaceRisk =>
        '${m['budgetName']} on track to exceed limit',
      SignalType.billAmountAnomaly => '${m['billName']} higher than usual',
      SignalType.categorySpendingSpike =>
        'Spending ${(m['variancePercent'] as num).round()}% above normal this week',
      SignalType.incomeDelay =>
        'Salary expected (${m['daysSinceLastSalary']} days since last)',
    };
  }

  String _actionLabel(SignalType type) => switch (type) {
        SignalType.billOverdue || SignalType.billDueSoon => 'Pay Now',
        SignalType.budgetBreach || SignalType.budgetPaceRisk => 'Review Budget',
        SignalType.goalDelay => 'Add Contribution',
        SignalType.billAmountAnomaly => 'Review Bill',
        SignalType.categorySpendingSpike => 'View Transactions',
        SignalType.incomeDelay => 'Check Income',
      };

  String _route(FinancialSignal signal) => switch (signal.type) {
        SignalType.billOverdue ||
        SignalType.billDueSoon ||
        SignalType.billAmountAnomaly =>
          '/bills',
        SignalType.budgetBreach ||
        SignalType.budgetPaceRisk =>
          '/budgets/${signal.metadata['budgetId']}',
        SignalType.goalDelay => '/goals/${signal.metadata['goalId']}',
        SignalType.categorySpendingSpike ||
        SignalType.incomeDelay =>
          '/transactions',
      };

  List<AttentionItem> _applyBudget(
      List<AttentionItem> items, UserFinancialContext context,) {
    final max = context.isStable ? 2 : 3;
    return items.take(max).toList();
  }
}

/// Attention item for UI rendering
class AttentionItem {
  final String id;
  final AttentionType type;
  final String title;
  final String message;
  final double priority;
  final String actionLabel;
  final String actionRoute;

  const AttentionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.actionLabel,
    required this.actionRoute,
  });
}

enum AttentionType { critical, warning, info, insight }
