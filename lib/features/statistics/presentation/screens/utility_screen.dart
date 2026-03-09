import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/responsive_helper.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilityScreen extends ConsumerStatefulWidget {
  const UtilityScreen({super.key});

  @override
  ConsumerState<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends ConsumerState<UtilityScreen> {
  List<String> _visibleUtilities = [];
  List<String> _seenUtilities = [];
  bool _isLoading = true;

  final List<_UtilityItem> _allUtilities = [
    _UtilityItem(
      id: 'trips',
      title: 'Trips & Split',
      subtitle: 'Group expenses & settlements',
      icon: LucideIcons.plane,
      route: '/trips',
      pluginId: 'com.mudra.split_bills',
    ),
    _UtilityItem(
      id: 'monthly_comparison',
      title: 'Monthly Comparison',
      subtitle: 'Current vs last month',
      icon: LucideIcons.arrowLeftRight,
      route: '/monthly-comparison',
    ),
    _UtilityItem(
      id: 'recurring',
      title: 'Bill Control Center',
      subtitle: 'Auto-create transactions',
      icon: LucideIcons.repeat,
      route: '/recurring-transactions',
    ),
    _UtilityItem(
      id: 'budgets',
      title: 'Budgets',
      subtitle: 'Manage spending limits',
      icon: LucideIcons.chartPie,
      route: '/budget-dashboard',
    ),
    _UtilityItem(
      id: 'goals',
      title: 'Goals',
      subtitle: 'Track savings progress',
      icon: LucideIcons.target,
      route: '/goal-screen',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('visible_utilities');
    final seen = prefs.getStringList('seen_utilities') ?? [];

    // Filter utilities based on plugin status
    final marketplace = MarketplaceService();
    final filteredUtilities = <_UtilityItem>[];
    for (final utility in _allUtilities) {
      if (utility.pluginId == null ||
          await marketplace.isPluginEnabled(utility.pluginId!)) {
        filteredUtilities.add(utility);
      }
    }

    if (mounted) {
      setState(() {
        _allUtilities.clear();
        _allUtilities.addAll(filteredUtilities);
        _visibleUtilities = saved ?? ['monthly_comparison', 'recurring'];
        _seenUtilities = seen;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('visible_utilities', _visibleUtilities);
  }

  Future<void> _restoreDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('visible_utilities');
    setState(() {
      _visibleUtilities = ['monthly_comparison', 'recurring'];
    });
    await _savePreferences();
  }

  void showCustomizeSheet() {
    _showCustomizeSheet();
  }

  void _showCustomizeSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Mark all utilities as seen when opening customize sheet
    final allIds = _allUtilities.map((e) => e.id).toList();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('seen_utilities', allIds);
    });
    setState(() {
      _seenUtilities = allIds;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.settings2,
                              color: color.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customize Utilities',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reorder or hide utilities',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _restoreDefaults();
                              Navigator.pop(context);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Restored to defaults')),
                                );
                              }
                            },
                            icon: Icon(LucideIcons.rotateCcw,
                                color: color.primary),
                            tooltip: 'Reset',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _allUtilities.length,
                    onReorder: (oldIndex, newIndex) {
                      setModalState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _allUtilities.removeAt(oldIndex);
                        _allUtilities.insert(newIndex, item);
                        _visibleUtilities = _allUtilities
                            .where((u) => _visibleUtilities.contains(u.id))
                            .map((u) => u.id)
                            .toList();
                      });
                      setState(() {});
                      _savePreferences();
                    },
                    itemBuilder: (context, index) {
                      final utility = _allUtilities[index];
                      final isVisible = _visibleUtilities.contains(utility.id);

                      return Card(
                        key: ValueKey(utility.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: color.surfaceContainerHighest,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  utility.icon,
                                  color: color.primary,
                                  size: 24,
                                ),
                              ),
                              if (!_seenUtilities.contains(utility.id))
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            utility.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            utility.subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isVisible,
                                onChanged: (value) {
                                  HapticFeedback.mediumImpact();
                                  setModalState(() {
                                    if (value) {
                                      _visibleUtilities.add(utility.id);
                                    } else {
                                      _visibleUtilities.remove(utility.id);
                                    }
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.gripVertical,
                                color: color.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ResponsiveHelper.getGridAspectRatio(
            context,
            defaultRatio: 1.0,
            singleColumnRatio: 2.6,
          ),
        ),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLoader(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 20,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: 150,
                  height: 14,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleItems =
        _allUtilities.where((u) => _visibleUtilities.contains(u.id)).toList();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: visibleItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 64,
                    color: color.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No utilities enabled',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showCustomizeSheet,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Utilities'),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Priority Alert Zone
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final alertAsync = ref.watch(priorityAlertProvider);
                      return alertAsync.when(
                        data: (alert) {
                          if (alert == null) return const SizedBox();

                          final alertColor = alert.type == AlertType.urgent
                              ? const Color(0xFFFFAB91)
                              : alert.type == AlertType.warning
                                  ? const Color(0xFFFFD54F)
                                  : color.primary;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push(alert.route);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    alertColor.withValues(alpha: 0.2),
                                    alertColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: alertColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: alertColor.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      alert.type == AlertType.urgent
                                          ? LucideIcons.circleAlert
                                          : alert.type == AlertType.warning
                                              ? LucideIcons.triangleAlert
                                              : LucideIcons.info,
                                      color: alertColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.title,
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: alertColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          alert.message,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.chevronRight,
                                    color: color.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: SkeletonLoader(
                            width: double.infinity,
                            height: 100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                ),

                // Core Tools Grid (2x2)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _UtilityCard(item: visibleItems[index]),
                      childCount:
                          visibleItems.length > 4 ? 4 : visibleItems.length,
                    ),
                  ),
                ),

                // Quick Actions Section
                if (visibleItems.length > 4)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'More Tools',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (visibleItems.length > 4)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _UtilityListCard(item: visibleItems[index + 4]),
                      ),
                      childCount: visibleItems.length - 4,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}

class _UtilityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? pluginId;

  _UtilityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.pluginId,
  });
}

class _UtilityCard extends StatelessWidget {
  final _UtilityItem item;

  const _UtilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                item.icon,
                size: 100,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      item.subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _UtilityListCard extends StatelessWidget {
  final _UtilityItem item;

  const _UtilityListCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
