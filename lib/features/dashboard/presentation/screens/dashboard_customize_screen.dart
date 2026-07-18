import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_registry.dart';
import 'package:mudra_manager/core/db/models/dashboard_widget_preference.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';

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
    if (entry.visible) {
      ref.read(widgetAnalyticsServiceProvider).recordHide(entry.plugin.id);
    }
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(widgetPreferencesProvider);
    final isPro = ref.watch(hasFullAccessProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.title_dashboardLayout),
        actions: [
          TextButton.icon(
            onPressed: _restoreDefaults,
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text(ctxt.common_reset),
          ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) {
          if (!_initialized) {
            _syncFromPreferences(prefs);
            _initialized = true;
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _DashboardContent(
                    reduceMotion: reduceMotion,
                    isDark: isDark,
                    isPro: isPro,
                    onReorder: _onReorder,
                    onToggle: _toggleVisibility,
                    entries: _entries,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final bool isPro;
  final void Function(int, int) onReorder;
  final void Function(_WidgetEntry) onToggle;
  final List<_WidgetEntry> entries;

  const _DashboardContent({
    required this.reduceMotion,
    required this.isDark,
    required this.isPro,
    required this.onReorder,
    required this.onToggle,
    required this.entries,
  });

  String? _categoryLabel(WidgetCategory category, AppLocalizations ctxt) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    final visibleCount = entries.where((e) => e.visible).length;

    return Column(
      children: [
        _HeroCard(
          reduceMotion: reduceMotion,
          isDark: isDark,
          visibleCount: visibleCount,
          totalCount: entries.length,
          isPro: isPro,
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: Colors.transparent,
                  child: child,
                ),
                child: child,
              );
            },
            itemCount: entries.length,
            onReorderItem: onReorder,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _WidgetTile(
                key: ValueKey(entry.plugin.id),
                entry: entry,
                color: color,
                textTheme: textTheme,
                spacing: spacing,
                categoryLabel: _categoryLabel(entry.plugin.category, ctxt),
                onToggle: () => onToggle(entry),
              );
            },
          ),
        ),
        const AmbientBrandSection(showSignature: false, absorbBottomInset: false),
      ],
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final int visibleCount;
  final int totalCount;
  final bool isPro;

  const _HeroCard({
    required this.reduceMotion,
    required this.isDark,
    required this.visibleCount,
    required this.totalCount,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
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
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Row(
          children: [
            Container(
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
            SizedBox(width: spacing.sectionGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.dashboard_cardsActive(visibleCount, totalCount),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  Text(
                    ctxt.dashboard_dragToReorder,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetTile extends StatelessWidget {
  final _WidgetEntry entry;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final String? categoryLabel;
  final VoidCallback onToggle;

  const _WidgetTile({
    required super.key,
    required this.entry,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.categoryLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {

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
      child: SettingItem(
        icon: entry.plugin.icon,
        title: entry.plugin.title,
        subtitle: categoryLabel ?? '',
        onTap: onToggle,
        selected: entry.visible,
      ),
    );
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