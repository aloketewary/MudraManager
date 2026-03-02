import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/data/overspend_prediction_service.dart';
import 'package:mudra_manager/features/budget/domain/overspend_prediction.dart';

final overspendPredictionServiceProvider =
    Provider<OverspendPredictionService>((ref) {
  return OverspendPredictionService.instance;
});

final overspendPredictionsProvider =
    FutureProvider<List<OverspendPrediction>>((ref) async {
  final predictionService = ref.watch(overspendPredictionServiceProvider);
  final budgetsWithSpent = await ref.watch(budgetWithProgressProvider.future);
  return await predictionService.getAllPredictions(budgetsWithSpent);
});

final criticalOverspendPredictionsProvider =
    FutureProvider<List<OverspendPrediction>>((ref) async {
  final predictionService = ref.watch(overspendPredictionServiceProvider);
  final predictions = await ref.watch(overspendPredictionsProvider.future);
  return await predictionService.getCriticalPredictions(predictions);
});
