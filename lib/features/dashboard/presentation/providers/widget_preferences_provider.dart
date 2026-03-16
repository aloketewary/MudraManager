import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/dashboard_widget_preference.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_registry.dart';

/// Service for managing widget preferences
class WidgetPreferencesService {
  final IsarService isarService;
  bool _initialized = false;

  WidgetPreferencesService(this.isarService);

  /// Get all widget preferences
  Future<List<DashboardWidgetPreference>> getAll() async {
    final isar = await isarService.getInstance();
    return await isar.dashboardWidgetPreferences.where().findAll();
  }

  /// Get preference for specific widget
  Future<DashboardWidgetPreference?> getPreference(String widgetId) async {
    final isar = await isarService.getInstance();
    return await isar.dashboardWidgetPreferences
        .filter()
        .widgetIdEqualTo(widgetId)
        .findFirst();
  }

  /// Save widget preference
  Future<void> savePreference(DashboardWidgetPreference pref) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.dashboardWidgetPreferences.put(pref);
    });
  }

  /// Update widget order
  Future<void> updateOrder(String widgetId, int newOrder) async {
    final pref = await getPreference(widgetId);
    if (pref != null) {
      pref.order = newOrder;
      await savePreference(pref);
    }
  }

  /// Toggle widget visibility
  Future<void> toggleVisibility(String widgetId) async {
    final pref = await getPreference(widgetId);
    if (pref != null) {
      pref.visible = !pref.visible;
      await savePreference(pref);
    }
  }

  /// Pin/unpin widget
  Future<void> togglePin(String widgetId) async {
    final pref = await getPreference(widgetId);
    if (pref != null) {
      pref.pinned = !pref.pinned;
      await savePreference(pref);
    }
  }

  /// Initialize default preferences for all widgets (only once)
  Future<void> initializeDefaults() async {
    if (_initialized) return;

    try {
      final isar = await isarService.getInstance();
      final existing = await getAll();
      final existingIds = existing.map((e) => e.widgetId).toSet();

      final newPreferences = <DashboardWidgetPreference>[];

      for (final widget in DashboardWidgetRegistry.widgets) {
        if (!existingIds.contains(widget.id)) {
          newPreferences.add(
            DashboardWidgetPreference.create(
              widgetId: widget.id,
              order: widget.defaultOrder,
              visible: widget.defaultVisible,
              size: widget.defaultSize,
            ),
          );
        }
      }

      if (newPreferences.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.dashboardWidgetPreferences.putAll(newPreferences);
        });
      }

      _initialized = true;
    } catch (e) {
      // Silently handle unique constraint violations
      print('Widget preferences initialization: $e');
    }
  }

  // Add to WidgetPreferencesService:
  Future<void> resetToDefaults() async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.dashboardWidgetPreferences.clear();
    });
    _initialized = false;
    await initializeDefaults();
  }
}

/// Provider for widget preferences service
final widgetPreferencesServiceProvider =
    Provider<WidgetPreferencesService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return WidgetPreferencesService(isarService);
});

/// Initialize defaults once on app start
final _initializeDefaultsProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(widgetPreferencesServiceProvider);
  await service.initializeDefaults();
});

/// Stream provider for widget preferences - with debouncing
final widgetPreferencesProvider =
    StreamProvider<List<DashboardWidgetPreference>>((ref) async* {
  // Wait for initialization to complete
  await ref.watch(_initializeDefaultsProvider.future);

  final isar = await ref.watch(isarServiceProvider).getInstance();

  // Watch for changes but skip the first immediate emission during init
  await for (final prefs
      in isar.dashboardWidgetPreferences.where().watch(fireImmediately: true)) {
    yield prefs;
  }
});

/// Cached provider for ordered widgets - prevents unnecessary rebuilds
final orderedDashboardWidgetsProvider =
    Provider<List<DashboardWidgetPlugin>>((ref) {
  final preferencesAsync = ref.watch(widgetPreferencesProvider);

  return preferencesAsync.when(
    data: (preferences) {
      // Create a map of preferences
      final prefMap = {for (var pref in preferences) pref.widgetId: pref};

      // Get all widgets
      final widgets = DashboardWidgetRegistry.widgets;

      // Filter visible widgets
      final visibleWidgets = widgets.where((widget) {
        final pref = prefMap[widget.id];
        final isVisible = pref?.visible ?? widget.defaultVisible;
        return isVisible;
      }).toList();

      // Sort by order (pinned first, then by order)
      visibleWidgets.sort((a, b) {
        final prefA = prefMap[a.id];
        final prefB = prefMap[b.id];

        // Pinned widgets first
        final pinnedA = prefA?.pinned ?? false;
        final pinnedB = prefB?.pinned ?? false;

        if (pinnedA && !pinnedB) return -1;
        if (!pinnedA && pinnedB) return 1;

        // Then by order
        final orderA = prefA?.order ?? a.defaultOrder;
        final orderB = prefB?.order ?? b.defaultOrder;

        return orderA.compareTo(orderB);
      });

      return visibleWidgets;
    },
    loading: () {
      // Return default order while loading
      final widgets = DashboardWidgetRegistry.widgets
          .where((w) => w.defaultVisible)
          .toList();
      widgets.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
      return widgets;
    },
    error: (_, __) => [],
  );
});
