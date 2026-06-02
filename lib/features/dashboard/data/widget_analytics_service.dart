import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/widget_metrics.dart';

class WidgetAnalyticsService {
  final IsarService _isarService;

  WidgetAnalyticsService(this._isarService);

  Future<void> recordImpression(String widgetId) async {
    final isar = await _isarService.getInstance();
    await isar.writeTxn(() async {
      final metrics = await _getOrCreate(isar, widgetId);
      metrics.impressions++;
      await isar.widgetMetrics.put(metrics);
    });
  }

  Future<void> recordClick(String widgetId) async {
    final isar = await _isarService.getInstance();
    await isar.writeTxn(() async {
      final metrics = await _getOrCreate(isar, widgetId);
      metrics.clicks++;
      await isar.widgetMetrics.put(metrics);
    });
  }

  Future<void> recordHide(String widgetId) async {
    final isar = await _isarService.getInstance();
    await isar.writeTxn(() async {
      final metrics = await _getOrCreate(isar, widgetId);
      metrics.hides++;
      await isar.widgetMetrics.put(metrics);
    });
  }

  Future<List<WidgetMetrics>> getAll() async {
    final isar = await _isarService.getInstance();
    return isar.widgetMetrics.where().findAll();
  }

  Future<void> resetAll() async {
    final isar = await _isarService.getInstance();
    await isar.writeTxn(() => isar.widgetMetrics.clear());
  }

  Future<WidgetMetrics> _getOrCreate(Isar isar, String widgetId) async {
    final existing = await isar.widgetMetrics
        .filter()
        .widgetIdEqualTo(widgetId)
        .findFirst();
    return existing ?? WidgetMetrics.create(widgetId: widgetId);
  }
}
