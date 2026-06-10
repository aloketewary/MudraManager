import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/statistics/data/contextual_scorer.dart';
import 'package:mudra_manager/features/statistics/data/financial_attention_layer.dart';
import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';
import 'package:mudra_manager/features/statistics/data/financial_signal_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:mudra_manager/features/statistics/data/financial_attention_layer.dart'
    show AttentionItem, AttentionType;

/// Orchestrator provider that combines all context engine phases
final adaptiveUtilityProvider =
    FutureProvider.autoDispose<AdaptiveUtilityState>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();

  // Phase 1: Compute financial context
  final context = await FinancialContextService(isar).computeContext();

  if (!context.isContextFresh || context.monthlyIncomeEstimate == 0) {
    return AdaptiveUtilityState.insufficient(context);
  }

  // Get recent data
  final last30Days = DateTime.now().subtract(const Duration(days: 30));
  final transactions =
      await isar.transactions.filter().dateGreaterThan(last30Days).findAll();

  final budgets =
      await isar.budgets.filter().isArchivedEqualTo(false).findAll();

  final goals = await isar.goals.filter().isActiveEqualTo(true).findAll();

  final bills =
      await isar.recurringTransactions.filter().isActiveEqualTo(true).findAll();

  // Phase 2: Generate signals
  final signals = FinancialSignalGenerator().generateSignals(
    recentTransactions: transactions,
    budgets: budgets,
    goals: goals,
    bills: bills,
    context: context,
  );

  // Phase 3+4: Score and filter
  final attentionLayer = FinancialAttentionLayer(ContextualScorer());
  final attentionItems = attentionLayer.filterForAttention(signals, context);
  final silent = attentionLayer.shouldRemainSilent(context, attentionItems);

  final usagePatterns = await _getUsagePatterns();

  return AdaptiveUtilityState.ready(
    context: context,
    attentionItems: attentionItems,
    shouldShowAdvisory: !silent,
    usagePatterns: usagePatterns,
  );
});

/// Track utility usage for adaptive learning
final utilityTrackerProvider =
    Provider<UtilityTracker>((ref) => UtilityTracker());

// ─── Usage tracking ──────────────────────────────────────────────────────────

class UtilityTracker {
  Future<void> trackUtilityOpen(String utilityId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('utility_opens_$utilityId') ?? 0;
    await prefs.setInt('utility_opens_$utilityId', count + 1);
    await prefs.setInt(
      'utility_last_opened_$utilityId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> trackTaskCompletion(String attentionItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final completions = prefs.getStringList('completed_tasks') ?? [];
    completions
        .add('${attentionItemId}_${DateTime.now().millisecondsSinceEpoch}');
    if (completions.length > 50) completions.removeAt(0);
    await prefs.setStringList('completed_tasks', completions);
  }
}

// ─── State model ─────────────────────────────────────────────────────────────

class AdaptiveUtilityState {
  final UserFinancialContext context;
  final List<AttentionItem> attentionItems;
  final bool shouldShowAdvisory;
  final Map<String, UtilityUsage> usagePatterns;
  final AdaptiveMode mode;

  const AdaptiveUtilityState._({
    required this.context,
    required this.attentionItems,
    required this.shouldShowAdvisory,
    required this.usagePatterns,
    required this.mode,
  });

  factory AdaptiveUtilityState.ready({
    required UserFinancialContext context,
    required List<AttentionItem> attentionItems,
    required bool shouldShowAdvisory,
    required Map<String, UtilityUsage> usagePatterns,
  }) =>
      AdaptiveUtilityState._(
        context: context,
        attentionItems: attentionItems,
        shouldShowAdvisory: shouldShowAdvisory,
        usagePatterns: usagePatterns,
        mode: AdaptiveMode.ready,
      );

  factory AdaptiveUtilityState.insufficient(UserFinancialContext context) =>
      AdaptiveUtilityState._(
        context: context,
        attentionItems: const [],
        shouldShowAdvisory: false,
        usagePatterns: const {},
        mode: AdaptiveMode.insufficient,
      );

  List<String> getRecommendedUtilities() {
    final recs = _allUtilityIds.map((id) {
      final usage = usagePatterns[id] ?? UtilityUsage.empty(id);
      final contextScore = _contextRelevance(id);
      final usageScore = _usageScore(usage);
      return (id: id, score: contextScore * 0.7 + usageScore * 0.3);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return recs.map((r) => r.id).toList();
  }

  double _contextRelevance(String id) => switch (id) {
        'recurring' => context.liquidityBufferDays < 15
            ? 0.9
            : context.autopayCoverage < 0.5
                ? 0.8
                : 0.6,
        'budgets' => context.spendingVolatilityIndex > 0.4
            ? 0.9
            : context.liquidityBufferDays < 30
                ? 0.8
                : 0.5,
        'goals' => context.isStable ? 0.8 : 0.4,
        'credit_cards' => context.debtRatio > 0.3
            ? 0.9
            : context.debtRatio > 0.1
                ? 0.7
                : 0.3,
        'tax_estimation' => _isTaxSeason() ? 0.8 : 0.3,
        _ => 0.5,
      };

  bool _isTaxSeason() {
    final month = DateTime.now().month;
    return month >= 1 && month <= 3 && context.monthlyIncomeEstimate > 50000;
  }

  double _usageScore(UtilityUsage usage) {
    if (usage.openCount == 0) return 0.1;
    final recency = usage.recentlyUsed ? 0.8 : 0.2;
    final frequency = (usage.openCount / 20.0).clamp(0.0, 1.0);
    return recency * 0.6 + frequency * 0.4;
  }
}

class UtilityUsage {
  final String utilityId;
  final int openCount;
  final DateTime? lastOpened;
  final bool recentlyUsed;

  const UtilityUsage({
    required this.utilityId,
    required this.openCount,
    this.lastOpened,
    required this.recentlyUsed,
  });

  factory UtilityUsage.empty(String id) => UtilityUsage(
        utilityId: id,
        openCount: 0,
        recentlyUsed: false,
      );
}

enum AdaptiveMode { ready, insufficient }

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _allUtilityIds = [
  'recurring',
  'trips',
  'credit_cards',
  'budgets',
  'goals',
  'monthly_recap',
  'monthly_comparison',
  'tax_estimation',
];

Future<Map<String, UtilityUsage>> _getUsagePatterns() async {
  final prefs = await SharedPreferences.getInstance();
  final patterns = <String, UtilityUsage>{};

  for (final id in _allUtilityIds) {
    final count = prefs.getInt('utility_opens_$id') ?? 0;
    final lastMs = prefs.getInt('utility_last_opened_$id') ?? 0;
    final lastDate =
        lastMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

    patterns[id] = UtilityUsage(
      utilityId: id,
      openCount: count,
      lastOpened: lastDate,
      recentlyUsed:
          lastDate != null && DateTime.now().difference(lastDate).inDays <= 7,
    );
  }

  return patterns;
}
