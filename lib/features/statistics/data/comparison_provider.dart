import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:mudra_manager/features/statistics/data/monthly_comparison_service.dart';

DateTime _defaultCompareMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month - 1, 1);
}

/// Selected compare month state. Defaults to previous month.
final compareMonthProvider =
    NotifierProvider.autoDispose<StateValue<DateTime>, DateTime>(
  () => StateValue(_defaultCompareMonth()),
);

/// Produces [ComparisonAnalysis] reactively.
/// Rebuilds on: transaction changes, compare month selection.
final comparisonAnalysisProvider =
    FutureProvider.autoDispose<ComparisonAnalysis>((ref) async {
  ref.watch(transactionChangeProvider);

  final compareMonth = ref.watch(compareMonthProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final service = MonthlyComparisonService(isar);
  return service.analyze(compareMonth: compareMonth);
});
