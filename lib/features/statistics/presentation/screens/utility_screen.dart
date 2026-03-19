import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
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
      route: AppRoutes.trips,
      color: const Color(0xFF6366F1),
    ),
    _UtilityItem(
      id: 'monthly_comparison',
      title: 'Monthly Comparison',
      subtitle: 'Current vs last month',
      icon: LucideIcons.arrowLeftRight,
      route: AppRoutes.monthlyComparison,
      color: const Color(0xFF8B5CF6),
    ),
    _UtilityItem(
      id: 'recurring',
      title: 'Bill Control Center',
      subtitle: 'Auto-create transactions',
      icon: LucideIcons.repeat,
      route: AppRoutes.recurringTransactions,
      color: const Color(0xFF10B981),
    ),
    _UtilityItem(
      id: 'budgets',
      title: 'Budgets',
      subtitle: 'Manage spending limits',
      icon: LucideIcons.chartPie,
      route: AppRoutes.budgetDashboard,
      color: const Color(0xFFEC4899),
    ),
    _UtilityItem(
      id: 'goals',
      title: 'Goals',
      subtitle: 'Track savings progress',
      icon: LucideIcons.target,
      route: AppRoutes.goalScreen,
      color: const Color(0xFFF59E0B),
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
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.only(bottom: 16),
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
                            SnackbarService.info('Restored to defaults');
                            if (mounted) {
                              context.pop();
                            }
                          },
                          icon:
                              Icon(LucideIcons.rotateCcw, color: color.primary),
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
                                color: utility.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                utility.icon,
                                color: utility.color,
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: color.surface,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final expandRatio = (constraints.maxHeight - kToolbarHeight) /
                    (280 - kToolbarHeight);
                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  centerTitle: false,
                  title: Opacity(
                    opacity: 1 - expandRatio.clamp(0.0, 1.0),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16, bottom: 16),
                      child: Text(
                        'Utilities',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.primaryContainer,
                          color.secondaryContainer,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Opacity(
                        opacity: expandRatio.clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.primary,
                                            color.primary
                                                .withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        LucideIcons.layoutGrid,
                                        color: color.onPrimary,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Utilities',
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: color.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Powerful tools for your finances',
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color: color.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              SkeletonLoader(
                                width: 200,
                                height: 32,
                                borderRadius:
                                    BorderRadius.circular(spacing.radiusMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(spacing.cardHorizontalMax),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Card(
                  color: color.surfaceContainerHighest,
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
                        const Spacer(),
                        const SkeletonLoader(
                          width: double.infinity,
                          height: 16,
                        ),
                        const SizedBox(height: 8),
                        const SkeletonLoader(
                          width: 100,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                childCount: 4,
              ),
            ),
          ),
        ],
      );
    }

    final visibleItems =
        _allUtilities.where((u) => _visibleUtilities.contains(u.id)).toList();

    return Scaffold(
      body: visibleItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.package,
                      size: 64,
                      color: color.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Text(
                    'No utilities enabled',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Text(
                    'Add utilities to get started',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  FilledButton.icon(
                    onPressed: _showCustomizeSheet,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Utilities'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                Consumer(
                  builder: (context, ref, child) {
                    final alertAsync = ref.watch(priorityAlertProvider);
                    return alertAsync.when(
                      data: (alert) {
                        if (alert == null) {
                          return const SliverToBoxAdapter(child: SizedBox());
                        }

                        final alertColor = alert.type == AlertType.urgent
                            ? const Color(0xFFFFAB91)
                            : alert.type == AlertType.warning
                                ? const Color(0xFFFFD54F)
                                : color.primary;

                        return SliverToBoxAdapter(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push(alert.route);
                            },
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: spacing.cardHorizontal,
                                vertical: spacing.cardVertical,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.cardHorizontal,
                                vertical: spacing.cardVertical,
                              ),
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
                                      color: color.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: spacing.elementGap),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.title,
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: color.onSurfaceVariant,
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
                          ),
                        );
                      },
                      loading: () => SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
                          ),
                          child: SkeletonLoader(
                            width: double.infinity,
                            height: 100,
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                        ),
                      ),
                      error: (_, __) =>
                          const SliverToBoxAdapter(child: SizedBox()),
                    );
                  },
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: spacing.cardHorizontal,
                      mainAxisSpacing: spacing.cardVertical,
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
                if (visibleItems.length > 4)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
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
                        margin: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontal,
                          vertical: spacing.cardVertical,
                        ),
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
  final Color color;

  _UtilityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.pluginId,
    required this.color,
  });
}

class _UtilityCard extends ConsumerWidget {
  final _UtilityItem item;

  const _UtilityCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                item.icon,
                size: 100,
                color: item.color.withValues(alpha: 0.08),
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
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
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
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
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
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
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
