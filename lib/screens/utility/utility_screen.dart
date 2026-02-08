import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/components/responsive_helper.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends State<UtilityScreen> {
  List<String> _visibleUtilities = [];
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
    setState(() {
      _visibleUtilities = saved ?? _allUtilities.map((e) => e.id).toList();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setModalState) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder:
                      (_, controller) => Container(
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: color.onSurfaceVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: color.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.tune,
                                          color: color.onPrimaryContainer,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Customize Utilities',
                                              style: textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Reorder or hide utilities',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        color.onSurfaceVariant,
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
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _allUtilities.length,
                                onReorder: (oldIndex, newIndex) {
                                  setModalState(() {
                                    if (newIndex > oldIndex) newIndex--;
                                    final item = _allUtilities.removeAt(
                                      oldIndex,
                                    );
                                    _allUtilities.insert(newIndex, item);
                                    _visibleUtilities =
                                        _allUtilities
                                            .where(
                                              (u) => _visibleUtilities.contains(
                                                u.id,
                                              ),
                                            )
                                            .map((u) => u.id)
                                            .toList();
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                                itemBuilder: (context, index) {
                                  final utility = _allUtilities[index];
                                  final isVisible = _visibleUtilities.contains(
                                    utility.id,
                                  );

                                  return Card(
                                    key: ValueKey(utility.id),
                                    margin: EdgeInsets.only(bottom: 12),
                                    elevation: 0,
                                    color: color.surfaceContainerHighest,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: color.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          utility.icon,
                                          color: color.primary,
                                          size: 24,
                                        ),
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
                                                  _visibleUtilities.add(
                                                    utility.id,
                                                  );
                                                } else {
                                                  _visibleUtilities.remove(
                                                    utility.id,
                                                  );
                                                }
                                              });
                                              setState(() {});
                                              _savePreferences();
                                            },
                                          ),
                                          SizedBox(width: 8),
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
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    final visibleItems =
        _allUtilities.where((u) => _visibleUtilities.contains(u.id)).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body:
          visibleItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.widgets_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No utilities enabled',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showCustomizeSheet,
                      icon: Icon(Icons.add),
                      label: Text('Add Utilities'),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 110),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(
                    context,
                  ),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: ResponsiveHelper.getGridAspectRatio(
                    context,
                    defaultRatio: 1.0,
                    singleColumnRatio: 2.6,
                  ),
                ),
                itemCount: visibleItems.length,
                itemBuilder:
                    (context, index) => _UtilityCard(item: visibleItems[index]),
              ),

      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
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
                  Spacer(),
                  Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
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
