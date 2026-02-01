import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  List<String> _visibleUtilities = [];
  bool _isLoading = true;

  final List<_UtilityItem> _allUtilities = [
    _UtilityItem(id: 'trips', title: 'Trips & Split', subtitle: 'Group expenses & settlements', icon: Icons.card_travel, color: Color(0xFF06B6D4), route: '/trips'),
    _UtilityItem(id: 'monthly_comparison', title: 'Monthly Comparison', subtitle: 'Current vs last month', icon: Icons.compare_arrows, color: Color(0xFF6366F1), route: '/monthly-comparison'),
    _UtilityItem(id: 'recurring', title: 'Recurring Transactions', subtitle: 'Auto-create transactions', icon: Icons.repeat, color: AppColors.netWorth, route: '/recurring-transactions'),
    _UtilityItem(id: 'budgets', title: 'Budgets', subtitle: 'Manage spending limits', icon: Icons.pie_chart_outline, color: Color(0xFFF59E0B), route: '/budget-dashboard'),
    _UtilityItem(id: 'goals', title: 'Goals', subtitle: 'Track savings progress', icon: Icons.emoji_flags_outlined, color: AppColors.transfer, route: '/goal-screen'),
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

  void _showCustomizeSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                          color: color.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.glassGradient(color.primary, isDark),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: AppColors.glassShadow(color.primary, isDark),
                            ),
                            child: Icon(Icons.tune, color: color.primary, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customize Utilities', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Reorder or hide utilities', style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
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
                        final item = _allUtilities.removeAt(oldIndex);
                        _allUtilities.insert(newIndex, item);
                        _visibleUtilities = _allUtilities.where((u) => _visibleUtilities.contains(u.id)).map((u) => u.id).toList();
                      });
                      setState(() {});
                      _savePreferences();
                    },
                    itemBuilder: (context, index) {
                      final utility = _allUtilities[index];
                      final isVisible = _visibleUtilities.contains(utility.id);
                      final utilityGradient = AppColors.glassGradient(utility.color, isDark);
                      
                      return Container(
                        key: ValueKey(utility.id),
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: utilityGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: utility.color.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: AppColors.glassShadow(utility.color, isDark),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: utility.color.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: Icon(utility.icon, color: utility.color, size: 24),
                          ),
                          title: Text(utility.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: utility.color, letterSpacing: -0.2)),
                          subtitle: Text(utility.subtitle, style: textTheme.bodySmall?.copyWith(color: utility.color.withValues(alpha: 0.75))),
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
                              SizedBox(width: 8),
                              Icon(Icons.drag_handle, color: utility.color.withValues(alpha: 0.5)),
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

    final visibleItems = _allUtilities.where((u) => _visibleUtilities.contains(u.id)).toList();

    return Scaffold(
      body: visibleItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.widgets_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No utilities enabled', style: Theme.of(context).textTheme.titleMedium),
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
              padding: EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) => _UtilityCard(item: visibleItems[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCustomizeSheet();
        },
        child: Icon(Icons.tune),
      ),
    );
  }
}

class _UtilityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  _UtilityItem({required this.id, required this.title, required this.subtitle, required this.icon, required this.color, required this.route});
}

class _UtilityCard extends StatelessWidget {
  final _UtilityItem item;

  const _UtilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.glassGradient(item.color, isDark),
        ),
        border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppColors.glassShadow(item.color, isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(item.route);
          },
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(item.icon, size: 120, color: item.color.withValues(alpha: 0.08)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.color, size: 32),
                    ),
                    Spacer(),
                    Text(item.title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: item.color, letterSpacing: -0.5)),
                    SizedBox(height: 4),
                    Text(item.subtitle, style: textTheme.labelMedium?.copyWith(color: item.color.withValues(alpha: 0.7), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
