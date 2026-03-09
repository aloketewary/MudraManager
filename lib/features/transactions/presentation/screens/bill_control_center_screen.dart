import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:table_calendar/table_calendar.dart';

class BillControlCenterScreen extends ConsumerStatefulWidget {
  const BillControlCenterScreen({super.key});

  @override
  ConsumerState<BillControlCenterScreen> createState() => _BillControlCenterScreenState();
}

class _BillControlCenterScreenState extends ConsumerState<BillControlCenterScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Control Center'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-recurring');
            },
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return const NoDataFound(
              message: 'No bills yet',
              iconData: Icons.receipt_long,
            );
          }

          final activeBills = bills.where((b) => b.isActive).toList();
          final upcomingBills = _getUpcomingBills(activeBills);
          final alerts = _generateAlerts(activeBills);

          return accountsAsync.when(
            data: (accounts) {
              final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.initialBalance);
              final upcomingTotal = upcomingBills.fold(0.0, (sum, b) => sum + b.amount);
              final safeToSpend = totalBalance - upcomingTotal;

              return CustomScrollView(
                slivers: [
                  // Cash-Flow Forecast
                  SliverToBoxAdapter(
                    child: _buildCashFlowForecast(safeToSpend, upcomingTotal, totalBalance, color, textTheme),
                  ),

                  // Priority Alerts
                  if (alerts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildPriorityAlerts(alerts, color, textTheme),
                    ),

                  // Calendar View
                  SliverToBoxAdapter(
                    child: _buildCalendarView(activeBills, color, textTheme),
                  ),

                  // Upcoming Bills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Upcoming Bills',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBillCard(upcomingBills[index], color, textTheme),
                      childCount: upcomingBills.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading accounts')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading bills')),
      ),
    );
  }

  Widget _buildCashFlowForecast(double safeToSpend, double upcomingTotal, double balance, ColorScheme color, TextTheme textTheme) {
    final forecastColor = safeToSpend < upcomingTotal * 0.2 ? color.error : color.tertiary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [forecastColor.withValues(alpha: 0.15), forecastColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: forecastColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, color: forecastColor, size: 24),
              const SizedBox(width: 12),
              Text('Cash-Flow Forecast', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${safeToSpend.toStringAsFixed(0)}',
            style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: forecastColor),
          ),
          Text('Safe to Spend', style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Balance', balance, color.primary, textTheme, color),
              _buildMetric('Upcoming', upcomingTotal, color.error, textTheme, color, prefix: '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, Color valueColor, TextTheme textTheme, ColorScheme color, {String prefix = ''}) {
    return Column(
      children: [
        Text(
          '$prefix₹${value.toStringAsFixed(0)}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
        ),
        Text(label, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildPriorityAlerts(List<_Alert> alerts, ColorScheme color, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.triangleAlert, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Action Needed',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...alerts.map((alert) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: alert.color.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(alert.icon, color: alert.color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: alert.color,
                              ),
                            ),
                            Text(
                              alert.message,
                              style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCalendarView(List<RecurringTransaction> bills, ColorScheme color, TextTheme textTheme) {
    final billDates = <DateTime, List<RecurringTransaction>>{};
    for (final bill in bills) {
      final date = DateTime(bill.nextDueDate.year, bill.nextDueDate.month, bill.nextDueDate.day);
      (billDates[date] ??= []).add(bill);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: color.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: color.error,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: color.error),
          outsideDaysVisible: false,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: TextStyle(color: color.error, fontWeight: FontWeight.bold),
        ),
        eventLoader: (day) {
          final date = DateTime(day.year, day.month, day.day);
          return billDates[date] ?? [];
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(),
        ),
      ),
    );
  }

  Widget _buildBillCard(RecurringTransaction bill, ColorScheme color, TextTheme textTheme) {
    final daysUntil = bill.nextDueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 3;
    final cardColor = isUrgent ? color.errorContainer : color.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: cardColor,
      child: InkWell(
        onTap: () => context.push('/add-recurring', extra: {'recurring': bill}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconHelper.iconFromName(bill.category.value?.iconName ?? 'category'),
                      color: color.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.category.value?.name ?? 'Unknown',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Due ${DateFormat('MMM d').format(bill.nextDueDate)} • ${_getFrequencyText(bill.frequency)}',
                          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.amount.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.error,
                        ),
                      ),
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$daysUntil days',
                            style: textTheme.labelSmall?.copyWith(
                              color: color.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/add-recurring', extra: {'recurring': bill}),
                      icon: const Icon(LucideIcons.settings, size: 16),
                      label: const Text('Manage'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // TODO: Mark as paid
                      },
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Mark Paid'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RecurringTransaction> _getUpcomingBills(List<RecurringTransaction> bills) {
    final now = DateTime.now();
    final upcoming = bills.where((b) => b.nextDueDate.isAfter(now)).toList();
    upcoming.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return upcoming.take(10).toList();
  }

  List<_Alert> _generateAlerts(List<RecurringTransaction> bills) {
    final dueSoon = bills.where((b) => b.nextDueDate.difference(DateTime.now()).inDays <= 3).length;
    return dueSoon > 0
        ? [_Alert(
            title: '$dueSoon Bills Due Soon',
            message: 'Review and prepare payments',
            icon: LucideIcons.clock,
            color: Colors.orange,
          )]
        : [];
  }

  String _getFrequencyText(Frequency freq) => switch (freq) {
    Frequency.daily => 'Daily',
    Frequency.weekly => 'Weekly',
    Frequency.monthly => 'Monthly',
    Frequency.yearly => 'Yearly',
  };
}

class _Alert {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  _Alert({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}
