import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/widget_metrics.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_service.dart';

final widgetAnalyticsServiceProvider = Provider<WidgetAnalyticsService>((ref) {
  return WidgetAnalyticsService(ref.watch(isarServiceProvider));
});

final widgetMetricsProvider = FutureProvider<List<WidgetMetrics>>((ref) {
  return ref.watch(widgetAnalyticsServiceProvider).getAll();
});
