import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Evaluation-date seam for deterministic budget providers and tests.
final budgetEvaluationDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
