import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class DailySummaryPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.daily_summary';

  @override
  String get name => 'Daily Summary';

  @override
  String get version => '1.2.0';

  @override
  void onDailySummary(DailySummaryEvent event) {
    _buildAndShowSummary();
  }

  Future<void> _buildAndShowSummary() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = start.add(const Duration(days: 1));

    final transactions = await api.getTransactions(from: start, to: end);

    if (transactions.isEmpty) {
      api.showNotification(
        '📊 Quiet day yesterday — zero-spend win or time to catch up!',
      );
      return;
    }

    double spent = 0;
    double earned = 0;
    final categorySpend = <String, double>{};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.isExpense) {
        spent += tx.amount;
        final cat = tx.category ?? 'Other';
        categorySpend[cat] = (categorySpend[cat] ?? 0) + tx.amount;
      } else {
        earned += tx.amount;
      }
    }

    final topCategory = categorySpend.isNotEmpty
        ? categorySpend.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    api.showNotification(
      '📊 Spent ₹${spent.toStringAsFixed(0)} · Earned ₹${earned.toStringAsFixed(0)} · Most: $topCategory',
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  @override
  Set<PluginPermission> get permissions => {
        PluginPermission.notifications,
        PluginPermission.readTransactions,
      };
}
