import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardCustomizeScreen extends StatefulWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  State<DashboardCustomizeScreen> createState() => _DashboardCustomizeScreenState();
}

class _DashboardCustomizeScreenState extends State<DashboardCustomizeScreen> {
  List<_DashboardCard> _allCards = [];
  List<String> _visibleCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCards();
    _loadPreferences();
  }

  void _initializeCards() {
    _allCards = [
      _DashboardCard(
        id: 'accounts',
        title: 'Account Balances',
        icon: Icons.account_balance_wallet,
      ),
      _DashboardCard(
        id: 'action_buttons',
        title: 'Quick Actions',
        icon: Icons.touch_app,
      ),
      _DashboardCard(
        id: 'cash_flow',
        title: 'Cash Flow',
        icon: Icons.trending_up,
      ),
      _DashboardCard(
        id: 'financial_health',
        title: 'Financial Health',
        icon: Icons.favorite,
      ),
      _DashboardCard(
        id: 'net_worth',
        title: 'Net Worth',
        icon: Icons.account_balance,
      ),
      _DashboardCard(
        id: 'spending_prediction',
        title: 'Spending Prediction',
        icon: Icons.insights,
      ),
      _DashboardCard(
        id: 'active_trip',
        title: 'Active Trip',
        icon: Icons.card_travel,
      ),
      _DashboardCard(
        id: 'budget',
        title: 'Budget Overview',
        icon: Icons.pie_chart_outline,
      ),
      _DashboardCard(
        id: 'goal',
        title: 'Goals Progress',
        icon: Icons.emoji_flags_outlined,
      ),
    ];
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('visible_dashboard_cards');
    final order = prefs.getStringList('dashboard_cards_order');

    if (order != null) {
      _allCards.sort((a, b) {
        final aIndex = order.indexOf(a.id);
        final bIndex = order.indexOf(b.id);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
    }

    setState(() {
      _visibleCards = saved ?? _allCards.map((e) => e.id).toList();
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('visible_dashboard_cards', _visibleCards);
    await prefs.setStringList('dashboard_cards_order', _allCards.map((e) => e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: color.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Drag to reorder, toggle to show/hide cards',
                        style: textTheme.bodySmall?.copyWith(color: color.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allCards.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _allCards.removeAt(oldIndex);
                  _allCards.insert(newIndex, item);
                });
                _savePreferences();
              },
              itemBuilder: (context, index) {
                final card = _allCards[index];
                final isVisible = _visibleCards.contains(card.id);

                return Card(
                  key: ValueKey(card.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(card.icon, color: color.primary, size: 24),
                    ),
                    title: Text(
                      card.title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isVisible,
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              if (value) {
                                _visibleCards.add(card.id);
                              } else {
                                _visibleCards.remove(card.id);
                              }
                            });
                            _savePreferences();
                          },
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.drag_handle, color: color.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard {
  final String id;
  final String title;
  final IconData icon;

  _DashboardCard({
    required this.id,
    required this.title,
    required this.icon,
  });
}
