import 'package:mudra_manager/features/statistics/data/contextual_scorer.dart';
import 'package:mudra_manager/features/statistics/data/financial_signal_generator.dart';
import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';

/// Phase 4: Financial Attention Layer
/// Determines what deserves user attention using contextual thresholds

class FinancialAttentionLayer {
  final ContextualScorer _scorer;

  FinancialAttentionLayer(this._scorer);

  /// Filter signals into attention-worthy items
  List<AttentionItem> filterForAttention(
    List<FinancialSignal> signals,
    UserFinancialContext context,
  ) {
    // Score all signals
    final scoredSignals = signals
        .map((signal) => _scorer.scoreSignal(signal, context))
        .toList();

    // Apply contextual thresholds
    final significantSignals = scoredSignals
        .where((scored) => _meetsSignificanceThreshold(scored, context))
        .toList();

    // Convert to attention items
    final attentionItems = significantSignals
        .map((scored) => _createAttentionItem(scored, context))
        .toList();

    // Sort by urgency and impact
    attentionItems.sort((a, b) => _compareUrgency(a, b, context));

    // Apply attention budget constraints
    return _applyAttentionBudget(attentionItems, context);
  }

  /// Determine if signal meets significance threshold
  bool _meetsSignificanceThreshold(ScoredSignal scored, UserFinancialContext context) {
    final signal = scored.signal;
    final score = scored.score;

    // Dynamic thresholds based on signal type and user context
    final threshold = _calculateDynamicThreshold(signal.type, context);

    return score >= threshold;
  }

  /// Calculate dynamic threshold based on context
  double _calculateDynamicThreshold(SignalType signalType, UserFinancialContext context) {
    // Base thresholds by signal type
    final baseThresholds = {
      SignalType.billOverdue: 0.9,
      SignalType.budgetBreach: 0.7,
      SignalType.billDueSoon: 0.6,
      SignalType.goalDelay: 0.4,
      SignalType.budgetPaceRisk: 0.5,
      SignalType.billAmountAnomaly: 0.6,
      SignalType.categorySpendingSpike: 0.5,
      SignalType.incomeDelay: 0.8,
    };

    final baseThreshold = baseThresholds[signalType] ?? 0.5;

    // Adjust threshold based on user's financial stability
    if (context.isStable) {
      // Stable users get higher thresholds (less noise)
      return (baseThreshold * 1.2).clamp(0.0, 0.95);
    } else {
      // Unstable users get lower thresholds (more sensitivity) 
      return (baseThreshold * 0.8).clamp(0.1, 1.0);
    }
  }

  /// Create attention item from scored signal
  AttentionItem _createAttentionItem(ScoredSignal scored, UserFinancialContext context) {
    final signal = scored.signal;
    final explanation = scored.explanation;

    return AttentionItem(
      id: '${signal.type}_${signal.timestamp.millisecondsSinceEpoch}',
      type: _mapToAttentionType(signal.type),
      title: _generateTitle(signal),
      description: explanation.why,
      priority: _calculatePriority(scored, context),
      actionLabel: _generateActionLabel(signal),
      actionRoute: _getActionRoute(signal),
      metadata: signal.metadata,
      timestamp: signal.timestamp,
      canDismiss: _canDismiss(signal.type),
    );
  }

  /// Generate human-readable title for attention item
  String _generateTitle(FinancialSignal signal) {
    switch (signal.type) {
      case SignalType.billOverdue:
        final billName = signal.metadata['billName'] as String? ?? 'Bill';
        final daysOverdue = signal.metadata['daysOverdue'] as int? ?? 0;
        return '$billName overdue by $daysOverdue days';

      case SignalType.budgetBreach:
        final budgetName = signal.metadata['budgetName'] as String? ?? 'Budget';
        final overspend = signal.metadata['overspendPercent'] as double? ?? 0;
        return '$budgetName exceeded by ${overspend.round()}%';

      case SignalType.billDueSoon:
        final billName = signal.metadata['billName'] as String? ?? 'Bill';
        final daysTillDue = signal.metadata['daysTillDue'] as int? ?? 0;
        return '$billName due ${daysTillDue == 0 ? 'today' : 'in $daysTillDue days'}';

      case SignalType.goalDelay:
        final goalName = signal.metadata['goalName'] as String? ?? 'Goal';
        final daysDelayed = signal.metadata['daysDelayed'] as int? ?? 0;
        return '$goalName contribution ${daysDelayed}+ days behind';

      case SignalType.budgetPaceRisk:
        final budgetName = signal.metadata['budgetName'] as String? ?? 'Budget';
        return '$budgetName on track to exceed limit';

      case SignalType.billAmountAnomaly:
        final billName = signal.metadata['billName'] as String? ?? 'Bill';
        final variancePercent = signal.metadata['variancePercent'] as double? ?? 0;
        return '$billName ${variancePercent > 0 ? 'higher' : 'lower'} than usual';

      case SignalType.categorySpendingSpike:
        final categoryId = signal.metadata['categoryId'] as int? ?? 0;
        final variancePercent = signal.metadata['variancePercent'] as double? ?? 0;
        return 'Spending spike: ${variancePercent.round()}% above normal';

      case SignalType.incomeDelay:
        final daysSince = signal.metadata['daysSinceLastSalary'] as int? ?? 0;
        return 'Salary expected ($daysSince days since last)';

      default:
        return 'Financial event needs attention';
    }
  }

  /// Generate contextual action label
  String _generateActionLabel(FinancialSignal signal) {
    switch (signal.type) {
      case SignalType.billOverdue:
      case SignalType.billDueSoon:
        return 'Pay Now';
      case SignalType.budgetBreach:
      case SignalType.budgetPaceRisk:
        return 'Review Budget';
      case SignalType.goalDelay:
        return 'Add Contribution';
      case SignalType.billAmountAnomaly:
        return 'Review Bill';
      case SignalType.categorySpendingSpike:
        return 'View Transactions';
      case SignalType.incomeDelay:
        return 'Check Income';
      default:
        return 'Review';
    }
  }

  /// Get appropriate route for action
  String _getActionRoute(FinancialSignal signal) {
    switch (signal.type) {
      case SignalType.billOverdue:
      case SignalType.billDueSoon:
        return '/bills'; // AppRoutes.recurringTransactions
      case SignalType.budgetBreach:
      case SignalType.budgetPaceRisk:
        final budgetId = signal.metadata['budgetId'];
        return '/budgets/$budgetId';
      case SignalType.goalDelay:
        final goalId = signal.metadata['goalId'];
        return '/goals/$goalId';
      case SignalType.billAmountAnomaly:
        return '/bills';
      case SignalType.categorySpendingSpike:
        return '/transactions';
      case SignalType.incomeDelay:
        return '/transactions';
      default:
        return '/dashboard';
    }
  }

  /// Map signal type to attention type for UI styling
  AttentionType _mapToAttentionType(SignalType signalType) {
    switch (signalType) {
      case SignalType.billOverdue:
      case SignalType.incomeDelay:
        return AttentionType.critical;
      case SignalType.budgetBreach:
      case SignalType.billDueSoon:
        return AttentionType.warning;
      case SignalType.goalDelay:
      case SignalType.budgetPaceRisk:
      case SignalType.billAmountAnomaly:
        return AttentionType.info;
      case SignalType.categorySpendingSpike:
        return AttentionType.insight;
      default:
        return AttentionType.info;
    }
  }

  /// Calculate priority score for sorting
  double _calculatePriority(ScoredSignal scored, UserFinancialContext context) {
    final baseScore = scored.score;
    final signalType = scored.signal.type;

    // Amplify priority for critical signal types
    final typeMultiplier = {
      SignalType.billOverdue: 2.0,
      SignalType.budgetBreach: 1.8,
      SignalType.incomeDelay: 1.9,
      SignalType.billDueSoon: 1.5,
      SignalType.goalDelay: 1.2,
      SignalType.budgetPaceRisk: 1.3,
      SignalType.billAmountAnomaly: 1.1,
      SignalType.categorySpendingSpike: 1.0,
    };

    final multiplier = typeMultiplier[signalType] ?? 1.0;
    
    // Apply liquidity pressure amplification
    final liquidityMultiplier = context.liquidityBufferDays < 7 ? 1.4 : 1.0;

    return baseScore * multiplier * liquidityMultiplier;
  }

  /// Compare attention items for sorting by urgency
  int _compareUrgency(AttentionItem a, AttentionItem b, UserFinancialContext context) {
    // Primary sort: by attention type (critical > warning > info > insight)
    final typeComparison = a.type.index.compareTo(b.type.index);
    if (typeComparison != 0) return typeComparison;

    // Secondary sort: by priority score
    return b.priority.compareTo(a.priority);
  }

  /// Apply attention budget to prevent overwhelming user
  List<AttentionItem> _applyAttentionBudget(
    List<AttentionItem> items,
    UserFinancialContext context,
  ) {
    if (items.isEmpty) return items;

    // Dynamic attention budget based on user state
    final maxDaily = context.isStable ? 2 : 3;
    final maxCritical = 2;
    final maxWarning = 3;

    var criticalCount = 0;
    var warningCount = 0;
    var totalCount = 0;

    final filteredItems = <AttentionItem>[];

    for (final item in items) {
      if (totalCount >= maxDaily) break;

      switch (item.type) {
        case AttentionType.critical:
          if (criticalCount < maxCritical) {
            filteredItems.add(item);
            criticalCount++;
            totalCount++;
          }
          break;
        case AttentionType.warning:
          if (warningCount < maxWarning) {
            filteredItems.add(item);
            warningCount++;
            totalCount++;
          }
          break;
        case AttentionType.info:
        case AttentionType.insight:
          if (totalCount < maxDaily) {
            filteredItems.add(item);
            totalCount++;
          }
          break;
      }
    }

    return filteredItems;
  }

  /// Check if signal type can be dismissed by user
  bool _canDismiss(SignalType signalType) {
    // Critical financial obligations cannot be dismissed
    return signalType != SignalType.billOverdue && 
           signalType != SignalType.incomeDelay;
  }

  /// Check if system should remain silent (no attention items)
  bool shouldRemainSilent(UserFinancialContext context, List<AttentionItem> items) {
    // Always surface critical items
    final hasCritical = items.any((item) => item.type == AttentionType.critical);
    if (hasCritical) return false;

    // For stable users, be more conservative about attention
    if (context.isStable && items.length <= 1) return true;

    // For unstable users, surface more information
    return false;
  }
}

/// User attention item with contextual information
class AttentionItem {
  final String id;
  final AttentionType type;
  final String title;
  final String description;
  final double priority;
  final String actionLabel;
  final String actionRoute;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool canDismiss;

  const AttentionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionLabel,
    required this.actionRoute,
    required this.metadata,
    required this.timestamp,
    required this.canDismiss,
  });

  @override
  String toString() {
    return 'AttentionItem(type: $type, title: $title, priority: $priority)';
  }
}

enum AttentionType { critical, warning, info, insight }