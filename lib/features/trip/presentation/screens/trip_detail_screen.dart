import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/settlement_card.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;
  int? _filterParticipantId;
  String? _filterCategory;
  Set<String> _settledKeys = {};
  Map<String, DateTime> _settledDates = {};

  String _getTripStatus(DateTime startDate, DateTime endDate, bool isActive) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (!isActive) return 'Completed';
    if (today.isBefore(start)) return 'Upcoming';
    if (today.isAfter(end)) return 'Past';
    return 'Active';
  }

  Color _getStatusColor(String status, ColorScheme color) {
    switch (status) {
      case 'Active':
        return color.primary;
      case 'Upcoming':
        return Colors.blue;
      case 'Past':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettledData();
  }

  Future<void> _loadSettledData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'settled_${widget.tripId}';
    final data = prefs.getString(key);
    if (data != null && data.isNotEmpty) {
      final items = data.split('|');
      final Map<String, DateTime> dates = {};
      for (var item in items) {
        final parts = item.split(':');
        if (parts.length >= 2) {
          final settlementKey = parts[0];
          final dateStr = parts.sublist(1).join(':');
          try {
            dates[settlementKey] = DateTime.parse(dateStr);
          } catch (e) {
            // Ignore parse errors
          }
        }
      }
      if (mounted) {
        setState(() {
          _settledKeys = dates.keys.toSet();
          _settledDates = dates;
        });
      }
    }
  }

  Future<void> _saveSettledData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'settled_${widget.tripId}';
    final data = _settledDates.entries
        .map((e) => '${e.key}:${e.value.toIso8601String()}')
        .join('|');
    await prefs.setString(key, data);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }

        final participants = trip.participants.toList();
        final duration = trip.endDate.difference(trip.startDate).inDays + 1;
        final status = _getTripStatus(
          trip.startDate,
          trip.endDate,
          trip.isActive,
        );
        final statusColor = _getStatusColor(status, color);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              trip.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/edit-trip', extra: trip.id);
                },
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Trip',
                style: IconButton.styleFrom(
                  backgroundColor: color.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  foregroundColor: color.primary,
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                style: IconButton.styleFrom(
                  backgroundColor: color.surfaceContainerHighest,
                ),
                onSelected: (value) async {
                  HapticFeedback.mediumImpact();
                  if (value == 'end') {
                    final confirm = await DialogUtils.showConfirmation(
                      context,
                      title: 'End Trip',
                      message: 'Mark this trip as completed?',
                      confirmText: 'End Trip',
                      icon: Icons.check_circle_outline,
                    );
                    if (confirm == true) {
                      await ref
                          .read(tripServiceProvider)
                          .markTripInactive(widget.tripId);
                      ref.invalidate(allTripsProvider);
                      ref.invalidate(tripByIdProvider(widget.tripId));
                    }
                  } else if (value == 'delete') {
                    final confirm = await DialogUtils.showDeleteConfirmation(
                      context,
                      title: 'Delete Trip',
                      message: 'This will delete all trip data. Continue?',
                    );
                    if (confirm == true) {
                      await ref
                          .read(tripServiceProvider)
                          .deleteTrip(widget.tripId);
                      ref.invalidate(allTripsProvider);
                      if (mounted) {
                        context.pop();
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  if (trip.isActive)
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('End Trip'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Trip',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Settlements'),
                Tab(text: 'Report'),
              ],
            ),
          ),
          body: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                color: color.surfaceContainerHighest,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat.MMMd().format(trip.startDate)} - ${DateFormat.MMMd().format(trip.endDate)}',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: color.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$duration days',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              status,
                              style: textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (trip.description != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        trip.description!,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: color.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${participants.length} Participants',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: participants
                                        .map(
                                          (p) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: statusColor,
                                                  child: Text(
                                                    p.name[0].toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  p.name,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isExpanded ? 'Hide Details' : 'Show Details',
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: color.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(trip, isGuestMode),
                    _buildSettlementsTab(trip, isGuestMode),
                    _buildReportTab(trip, isGuestMode),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: trip.isActive
              ? FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/add-trip-transaction', extra: widget.tripId);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                )
              : null,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildTransactionsTab(trip, bool isGuestMode) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final transactionsList = trip.transactions.toList();
    final participants = trip.participants.toList();

    // Apply filters
    final filteredTransactions = transactionsList.where((tripTxn) {
      if (_filterParticipantId != null &&
          tripTxn.paidBy.value?.id != _filterParticipantId) {
        return false;
      }
      if (_filterCategory != null &&
          tripTxn.transaction.value?.category.value?.name != _filterCategory) {
        return false;
      }
      return true;
    }).toList();

    // Get unique categories
    final categories = transactionsList
        .map((t) => t.transaction.value?.category.value?.name)
        .where((c) => c != null)
        .toSet()
        .toList();

    if (transactionsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: color.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No expenses yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses to split with participants',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            if (trip.isActive) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/add-trip-transaction', extra: widget.tripId),
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Participant filter
                PopupMenuButton<int?>(
                  child: Chip(
                    avatar: Icon(
                      Icons.person,
                      size: 18,
                      color: _filterParticipantId != null
                          ? color.primary
                          : color.onSurfaceVariant,
                    ),
                    label: Text(
                      _filterParticipantId != null
                          ? participants
                                .firstWhere((p) => p.id == _filterParticipantId)
                                .name
                          : 'All People',
                    ),
                    deleteIcon: _filterParticipantId != null
                        ? const Icon(Icons.close, size: 18)
                        : null,
                    onDeleted: _filterParticipantId != null
                        ? () {
                            HapticFeedback.lightImpact();
                            setState(() => _filterParticipantId = null);
                          }
                        : null,
                    backgroundColor: _filterParticipantId != null
                        ? color.primaryContainer
                        : color.surfaceContainerHighest,
                  ),
                  onSelected: (id) {
                    HapticFeedback.selectionClick();
                    setState(() => _filterParticipantId = id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<int?>(
                      value: null,
                      child: Text('All People'),
                    ),
                    ...participants.map(
                      (p) =>
                          PopupMenuItem<int?>(value: p.id, child: Text(p.name)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Category filter
                if (categories.isNotEmpty)
                  PopupMenuButton<String?>(
                    child: Chip(
                      avatar: Icon(
                        Icons.category,
                        size: 18,
                        color: _filterCategory != null
                            ? color.secondary
                            : color.onSurfaceVariant,
                      ),
                      label: Text(_filterCategory ?? 'All Categories'),
                      deleteIcon: _filterCategory != null
                          ? const Icon(Icons.close, size: 18)
                          : null,
                      onDeleted: _filterCategory != null
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(() => _filterCategory = null);
                            }
                          : null,
                      backgroundColor: _filterCategory != null
                          ? color.secondaryContainer
                          : color.surfaceContainerHighest,
                    ),
                    onSelected: (cat) {
                      HapticFeedback.selectionClick();
                      setState(() => _filterCategory = cat);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map(
                        (c) =>
                            PopupMenuItem<String?>(value: c, child: Text(c!)),
                      ),
                    ],
                  ),
                if (_filterParticipantId != null ||
                    _filterCategory != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _filterParticipantId = null;
                        _filterCategory = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: color.error),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Transactions list
        Expanded(
          child: filteredTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 48,
                        color: color.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses match filters',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final tripTxn = filteredTransactions[index];
                    final txn = tripTxn.transaction.value;
                    final paidBy = tripTxn.paidBy.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onLongPress: () async {
                          HapticFeedback.mediumImpact();
                          final confirm =
                              await DialogUtils.showDeleteConfirmation(
                                context,
                                title: 'Remove Expense',
                                message: 'Remove this expense from the trip?',
                                deleteText: 'Remove',
                              );
                          if (confirm == true) {
                            await ref
                                .read(tripServiceProvider)
                                .removeTripTransaction(
                                  widget.tripId,
                                  tripTxn.id,
                                );
                            ref.invalidate(tripByIdProvider(widget.tripId));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: color.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  paidBy?.name[0].toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Paid by ${paidBy?.name ?? "Unknown"}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      txn?.description ?? 'Expense',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (txn?.category.value?.name != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          txn!.category.value!.name,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: color.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${GuestModeUtil.applyGuestMode(txn?.amount ?? 0, isGuestMode).toStringAsFixed(2)}',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettlementsTab(trip, bool isGuestMode) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settlementsAsync = ref.watch(tripSettlementsProvider(widget.tripId));

    return settlementsAsync.when(
      data: (settlements) {
        if (settlements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'All settled up!',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No pending settlements',
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Flatten settlements into list
        final List<Map<String, dynamic>> settlementList = [];
        settlements.forEach((from, toMap) {
          toMap.forEach((to, amount) {
            final key = '${from}_TO_$to';
            settlementList.add({
              'from': from,
              'to': to,
              'amount': amount,
              'key': key,
              'isPaid': _settledKeys.contains(key),
              'settledDate': _settledDates[key],
            });
          });
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settlementList.length,
          itemBuilder: (context, index) {
            final settlement = settlementList[index];
            return SettlementCard(
              fromPerson: settlement['from'],
              toPerson: settlement['to'],
              amount: settlement['amount'],
              isPaid: settlement['isPaid'],
              settledDate: settlement['settledDate'],
              onMarkPaid: settlement['isPaid']
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _settledKeys.add(settlement['key']);
                        _settledDates[settlement['key']] = DateTime.now();
                      });
                      await _saveSettledData();
                    },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const Center(child: Text('Error calculating settlements')),
    );
  }

  Widget _buildReportTab(trip, bool isGuestMode) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final transactionsList = trip.transactions.toList();
    final participants = trip.participants.toList();

    if (transactionsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart, size: 48, color: color.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No data yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses to see report',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    double totalCost = 0;
    final Map<String, double> categoryTotals = {};
    final Map<int, double> participantSpending = {};

    for (var tripTxn in transactionsList) {
      final txn = tripTxn.transaction.value;
      if (txn != null) {
        totalCost += txn.amount;
        final categoryName = txn.category.value?.name ?? 'Uncategorized';
        categoryTotals[categoryName] =
            (categoryTotals[categoryName] ?? 0) + txn.amount;

        // Track spending by participant
        final paidById = tripTxn.paidBy.value?.id;
        if (paidById != null) {
          participantSpending[paidById] =
              (participantSpending[paidById] ?? 0) + txn.amount;
        }
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final perPersonAverage = participants.isNotEmpty
        ? totalCost / participants.length
        : 0;
    final displayTotalCost = GuestModeUtil.applyGuestMode(totalCost, isGuestMode);
    final displayPerPersonAverage = GuestModeUtil.applyGuestMode(perPersonAverage.toDouble(), isGuestMode);
    final displayCategoryValues = <String, double>{};
    for (var entry in sortedCategories) {
      displayCategoryValues[entry.key] = GuestModeUtil.applyGuestMode(entry.value, isGuestMode);
    }
    final displayParticipantSpending = <int, double>{};
    for (var entry in participantSpending.entries) {
      displayParticipantSpending[entry.key] = GuestModeUtil.applyGuestMode(entry.value, isGuestMode);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Cost Card
        Card(
          elevation: 0,
          color: color.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: color.primary,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Trip Cost',
                  style: textTheme.titleSmall?.copyWith(
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${displayTotalCost.toStringAsFixed(2)}',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactionsList.length} transactions',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Per Person Summary
        Card(
          elevation: 0,
          color: color.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: color.secondary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Per Person Summary',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Average per person',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${displayPerPersonAverage.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...participants.map((p) {
                  final spent = participantSpending[p.id] ?? 0;
                  final percentage = totalCost > 0
                      ? (spent / totalCost * 100)
                      : 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.primaryContainer,
                          child: Text(
                            p.name[0].toUpperCase(),
                            style: TextStyle(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 6,
                                  backgroundColor:
                                      color.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    color.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${displayParticipantSpending[p.id]?.toStringAsFixed(2) ?? "0.00"}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Category Breakdown',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...sortedCategories.map((entry) {
          final percentage = (entry.value / totalCost * 100);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 20,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${displayCategoryValues[entry.key]?.toStringAsFixed(2) ?? "0.00"}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: color.surface,
                      valueColor: AlwaysStoppedAnimation(color.primary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
