import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/shared/widgets/responsive_helper.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

import 'package:shared_preferences/shared_preferences.dart';

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends State<UtilityScreen> {
  List<String> _visibleUtilities = [];
  List<String> _seenUtilities = [];
  bool _isLoading = true;

  final List<_UtilityItem> _allUtilities = [
    _UtilityItem(
      id: 'trips',
      title: 'Trips & Split',
      subtitle: 'Group expenses & settlements',
      icon: Icons.card_travel,
      route: '/trips',
    ),
    _UtilityItem(
      id: 'monthly_comparison',
      title: 'Monthly Comparison',
      subtitle: 'Current vs last month',
      icon: Icons.compare_arrows,
      route: '/monthly-comparison',
    ),
    _UtilityItem(
      id: 'recurring',
      title: 'Recurring Transactions',
      subtitle: 'Auto-create transactions',
      icon: Icons.repeat,
      route: '/recurring-transactions',
    ),
    _UtilityItem(
      id: 'budgets',
      title: 'Budgets',
      subtitle: 'Manage spending limits',
      icon: Icons.pie_chart_outline,
      route: '/budget-dashboard',
    ),
    _UtilityItem(
      id: 'goals',
      title: 'Goals',
      subtitle: 'Track savings progress',
      icon: Icons.emoji_flags_outlined,
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
    
    setState(() {
      _visibleUtilities = saved ?? ['monthly_comparison', 'recurring'];
      _seenUtilities = seen;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('visible_utilities', _visibleUtilities);
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
                              Icons.tune,
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
                                Icons.drag_handle,
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
                SkeletonLoader(
                  width: double.infinity,
                  height: 20,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 150,
                  height: 14,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleItems = _allUtilities
        .where((u) => _visibleUtilities.contains(u.id))
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: visibleItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.widgets_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No utilities enabled',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showCustomizeSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Utilities'),
                  ),
                ],
              ),
            )
          : GridView.builder(
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
              itemCount: visibleItems.length,
              itemBuilder: (context, index) => _AnimatedCard(
                delay: index * 50,
                child: _UtilityCard(item: visibleItems[index]),
              ),
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

  _UtilityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
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
