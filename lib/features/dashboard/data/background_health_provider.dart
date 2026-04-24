import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/services/background_task_manager.dart';

/// True when background tasks have failed [failureThreshold]+ times consecutively.
final backgroundTaskUnhealthyProvider = FutureProvider.autoDispose<bool>((ref) async {
  final failures = await BackgroundTaskManager.getConsecutiveFailures();
  return failures >= BackgroundTaskManager.failureThreshold;
});
