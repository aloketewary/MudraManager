import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
// lib/features/dashboard/presentation/screens/dashboard_customize_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_registry.dart';
import 'package:mudra_manager/core/db/models/dashboard_widget_preference.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';

class DashboardCustomizeScreen extends ConsumerStatefulWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  ConsumerState<DashboardCustomizeScreen> createState() =>
      _DashboardCustomizeScreenState();
}

class _DashboardCustomizeScreenState
    extends ConsumerState<DashboardCustomizeScreen> {
  List<_WidgetEntry> _entries = [];
  bool _initialized = false;
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  void _syncFromPreferences(List<DashboardWidgetPreference> prefs) {
    final prefMap = {for (var p in prefs) p.widgetId: p};
    final plugins = DashboardWidgetRegistry.widgets;

    final entries = <_WidgetEntry>[];
    for (final plugin in plugins) {
      final pref = prefMap[plugin.id];
      entries.add(
        _WidgetEntry(
          plugin: plugin,
          visible: pref?.visible ?? plugin.defaultVisible,
          pinned: pref?.pinned ?? false,
          order: pref?.order ?? plugin.defaultOrder,
        ),
      );
    }

    // Sort: pinned first, then by order
    entries.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return a.order.compareTo(b.order);
    });

    _entries = entries;
  }

  Future<void> _toggleVisibility(_WidgetEntry entry) async {
    HapticFeedback.mediumImpact();
    final service = ref.read(widgetPreferencesServiceProvider);
    await service.toggleVisibility(entry.plugin.id);
    setState(() => entry.visible = !entry.visible);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, item);
    });

    final service = ref.read(widgetPreferencesServiceProvider);
    for (var i = 0; i < _entries.length; i++) {
      _entries[i].order = i;
      await service.updateOrder(_entries[i].plugin.id, i);
    }
  }

  Future<void> _restoreDefaults() async {
    HapticFeedback.mediumImpact();
    final service = ref.read(widgetPreferencesServiceProvider);
    await service.resetToDefaults();
    ref.invalidate(widgetPreferencesProvider);
    setState(() => _initialized = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(widgetPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title_dashboardLayout),
        actions: [
          TextButton.icon(
            onPressed: _restoreDefaults,
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text(AppLocalizations.of(context)!.common_reset),
          ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => ListView(children: List.generate(4, (_) => const DashboardCardSkeleton())),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
        data: (prefs) {
          if (!_initialized) {
            _syncFromPreferences(prefs);
            _initialized = true;
          }

          final visibleCount = _entries.where((e) => e.visible).length;

          return Column(
            children: [
              // ── HERO STATUS CARD ──
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: _buildHeroCard(
                  color,
                  textTheme,
                  spacing,
                  isDark,
                  visibleCount,
                ),
              ),

              // ── REORDERABLE LIST ──
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                  ),
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        elevation: 4,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        color: Colors.transparent,
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  itemCount: _entries.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _buildWidgetTile(
                      key: ValueKey(entry.plugin.id),
                      entry: entry,
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                      isLast: index == _entries.length - 1,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    int visibleCount,
  ) {
    final accent = color.primary;
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.2 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.layoutDashboard,
                color: accent,
                size: 28,
              ),
            ),
          ),
          SizedBox(width: spacing.sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctxt.dashboard_cardsActive(visibleCount, _entries.length),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Text(
                  ctxt.dashboard_dragToReorder,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Consumer(
                  builder: (context, ref, _) {
                    final isPro = ref.watch(hasFullAccessProvider).value ?? false;
                    return Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: accent),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          ctxt.dashboard_smartOrdering,
                          style: textTheme.labelMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        if (!isPro) ...[
                          SizedBox(width: spacing.elementGapMin),
                          const ProBadge(),
                        ],
                        const Spacer(),
                        Switch(
                          value: isPro && ref.watch(smartOrderEnabledProvider),
                          onChanged: isPro
                              ? (v) {
                                  SharedPrefsUtil.instance.setString(
                                    'smart_order_enabled',
                                    v.toString(),
                                  );
                                  ref.invalidate(smartOrderEnabledProvider);
                                }
                              : (_) => context.push(AppRoutes.upgrade),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetTile({
    required Key key,
    required _WidgetEntry entry,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required bool isLast,
  }) {
    final alpha = entry.visible ? 1.0 : 0.45;
    final categoryLabel = _categoryLabel(entry.plugin.category);

    return Card(
      key: key,
      elevation: 0,
      margin: EdgeInsets.only(bottom: spacing.elementGap),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.cardInner, vertical: spacing.elementGap),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(spacing.elementGap),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12 * alpha),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Icon(
                entry.plugin.icon,
                color: color.primary.withValues(alpha: alpha),
                size: 20,
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),

            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.plugin.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color.onSurface.withValues(alpha: alpha),
                    ),
                  ),
                  if (categoryLabel != null)
                    Text(
                      categoryLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: alpha),
                      ),
                    ),
                ],
              ),
            ),

            // Toggle
            Switch(
              value: entry.visible,
              onChanged: entry.plugin.canBeDisabled
                  ? (_) => _toggleVisibility(entry)
                  : null,
            ),
            SizedBox(width: spacing.elementGapMin),

            // Drag handle
            Icon(
              LucideIcons.gripVertical,
              color: color.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String? _categoryLabel(WidgetCategory category) {
    switch (category) {
      case WidgetCategory.essential:
        return ctxt.dashboard_catEssential;
      case WidgetCategory.finance:
        return ctxt.dashboard_catFinance;
      case WidgetCategory.analytics:
        return ctxt.dashboard_catAnalytics;
      case WidgetCategory.actions:
        return ctxt.dashboard_catActions;
      case WidgetCategory.ai:
        return ctxt.dashboard_catAI;
      case WidgetCategory.contextual:
        return ctxt.dashboard_catContextual;
      case WidgetCategory.custom:
        return null;
    }
  }
}

class _WidgetEntry {
  final DashboardWidgetPlugin plugin;
  bool visible;
  bool pinned;
  int order;

  _WidgetEntry({
    required this.plugin,
    required this.visible,
    required this.pinned,
    required this.order,
  });
}
