import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/settlement_card.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int? _filterParticipantId;
  String? _filterCategory;
  Set<String> _settledKeys = {};
  Map<String, DateTime> _settledDates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettledData();
  }

  void _updateTabController(bool isActive) {
    final newLength = isActive ? 2 : 3;
    if (_tabController.length != newLength) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
      if (oldIndex < newLength) {
        _tabController.index = oldIndex;
      }
    }
  }

  Future<void> _loadSettledData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'settled_${widget.tripId}';
    final data = prefs.getString(key);
    if (data != null && data.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = Map<String, dynamic>.from(
          json.decode(data) as Map,
        );
        final Map<String, DateTime> dates = {};
        for (final entry in decoded.entries) {
          try {
            dates[entry.key] = DateTime.parse(entry.value as String);
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _settledKeys = dates.keys.toSet();
            _settledDates = dates;
          });
        }
      } catch (_) {
        // Migrate from old delimiter format
        final items = data.split('|');
        final Map<String, DateTime> dates = {};
        for (var item in items) {
          final parts = item.split(':');
          if (parts.length >= 2) {
            final settlementKey = parts[0];
            final dateStr = parts.sublist(1).join(':');
            try {
              dates[settlementKey] = DateTime.parse(dateStr);
            } catch (_) {}
          }
        }
        if (mounted) {
          setState(() {
            _settledKeys = dates.keys.toSet();
            _settledDates = dates;
          });
          // Re-save in JSON format
          _saveSettledData();
        }
      }
    }
  }

  Future<void> _saveSettledData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'settled_${widget.tripId}';
    final data = _settledDates.map(
      (k, v) => MapEntry(k, v.toIso8601String()),
    );
    await prefs.setString(key, json.encode(data));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Not Found')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        final duration = trip.endDate.difference(trip.startDate).inDays + 1;
        _updateTabController(trip.isActive);

        final transactionsList = trip.transactions.toList();
        double totalSpent = 0;
        for (var tripTxn in transactionsList) {
          final amount = tripTxn.resolvedAmount;
          if (amount != null) totalSpent += amount;
        }
        final budget =
            trip.budget ?? (totalSpent > 0 ? totalSpent * 1.2 : 10000);
        final budgetUsed = totalSpent / budget;

        return Scaffold(
          floatingActionButton: !trip.isTrip && trip.isActive
              ? FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(
                      AppRoutes.addTripTransaction,
                      extra: trip.id,
                    );
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Split Expense'),
                )
              : null,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: color.surface,
                  leading: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.pop();
                    },
                  ),
                  title: Text(
                    trip.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    PopupMenuButton(
                      icon: const Icon(LucideIcons.ellipsisVertical),
                      onSelected: (value) async {
                        HapticFeedback.mediumImpact();
                        if (value == 'edit') {
                          context.push('/edit-trip/${trip.id}');
                        } else if (value == 'end') {
                          final confirm = await DialogUtils.showConfirmation(
                            context,
                            title: trip.isTrip ? 'End Trip' : 'End Group',
                            message: trip.isTrip
                                ? 'Mark this trip as completed?'
                                : 'Mark this group as completed?',
                            confirmText: trip.isTrip ? 'End Trip' : 'End Group',
                            icon: LucideIcons.circleCheck,
                          );
                          if (confirm == true) {
                            await ref
                                .read(tripServiceProvider)
                                .markTripInactive(widget.tripId);
                            ref.invalidate(allTripsProvider);
                            ref.invalidate(activeTripsProvider);
                            ref.invalidate(tripByIdProvider(widget.tripId));
                          }
                        } else if (value == 'delete') {
                          final confirm =
                              await DialogUtils.showDeleteConfirmation(
                            context,
                            title: trip.isTrip ? 'Delete Trip' : 'Delete Group',
                            message: trip.isTrip
                                ? 'This will delete all trip data. Continue?'
                                : 'This will delete all group data. Continue?',
                          );
                          if (confirm == true) {
                            await ref
                                .read(tripServiceProvider)
                                .deleteTrip(widget.tripId);
                            ref.invalidate(allTripsProvider);
                            ref.invalidate(activeTripsProvider);
                            if (mounted) {
                              context.pop();
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(LucideIcons.pencil, size: 18),
                              const SizedBox(width: 12),
                              Text(trip.isTrip ? 'Edit Trip' : 'Edit Group'),
                            ],
                          ),
                        ),
                        if (trip.isActive)
                          PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.circleCheck, size: 18),
                                const SizedBox(width: 12),
                                Text(trip.isTrip ? 'End Trip' : 'End Group'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: color.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                trip.isTrip ? 'Delete Trip' : 'Delete Group',
                                style: TextStyle(color: color.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final expandRatio =
                          (constraints.maxHeight - kToolbarHeight) /
                              (220 - kToolbarHeight);
                      return FlexibleSpaceBar(
                        titlePadding:
                            EdgeInsets.only(bottom: spacing.sectionGap),
                        centerTitle: false,
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
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 12),
                                    if (trip.isTrip)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          // Added: Prevent overflow
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.calendar,
                                                size: 16,
                                                color: color.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                // Added: Prevent overflow
                                                child: Text(
                                                  '${DateFormat.MMMd().format(trip.startDate)} - ${DateFormat.MMMd().format(trip.endDate)}',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color:
                                                        color.onSurfaceVariant,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: color.onSurfaceVariant,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$duration ${duration == 1 ? 'day' : 'days'}',
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: color.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (trip.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.primary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                spacing.radiusSmall,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: color.onPrimary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'LIVE',
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: color.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (!trip.isTrip && trip.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.primary,
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusSmall,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: color.onPrimary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'ACTIVE',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                color: color.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Spent',
                                                style: textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: color.onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${(totalSpent / 1000).toStringAsFixed(1)}k',
                                                style: textTheme.displaySmall
                                                    ?.copyWith(
                                                  color: color.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: budgetUsed > 0.9
                                                ? color.errorContainer
                                                : color.tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              spacing.radiusMedium,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${(budgetUsed * 100).toStringAsFixed(0)}%',
                                                style: textTheme.titleLarge
                                                    ?.copyWith(
                                                  color: budgetUsed > 0.9
                                                      ? color.onErrorContainer
                                                      : color
                                                          .onTertiaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'of budget',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: budgetUsed > 0.9
                                                      ? color.onErrorContainer
                                                      : color
                                                          .onTertiaryContainer,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: spacing.sectionGap * 2,
                                      ),
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
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: [
                      const Tab(text: 'Expenses'),
                      const Tab(text: 'Settlements'),
                      if (!trip.isActive) const Tab(text: 'Report'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(
                  trip,
                  isGuestMode,
                  spacing,
                  color,
                  textTheme,
                ),
                _buildSettlementsTab(
                  trip,
                  isGuestMode,
                  spacing,
                  color,
                  textTheme,
                ),
                if (!trip.isActive)
                  _buildReportTab(trip, isGuestMode, spacing, color, textTheme),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SkeletonLoader(width: 48, height: 48),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(width: double.infinity, height: 16),
                          SizedBox(height: 8),
                          SkeletonLoader(width: 150, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(BuddyMessages.genericError)),
        body: Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildTransactionsTab(
    Trip trip,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final transactionsList = trip.transactions.toList();
    final participants = trip.participants.toList();

    final filteredTransactions = transactionsList.where((tripTxn) {
      if (_filterParticipantId != null &&
          tripTxn.paidBy.value?.id != _filterParticipantId) {
        return false;
      }
      if (_filterCategory != null) {
        final catName = tripTxn.transaction.value?.category.value?.name
            ?? tripTxn.splitExpense.value?.description;
        if (catName != _filterCategory) return false;
      }
      return true;
    }).toList();

    final categories = transactionsList
        .map((t) => t.transaction.value?.category.value?.name)
        .where((c) => c != null)
        .toSet()
        .toList();

    if (transactionsList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
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
                  LucideIcons.receiptText,
                  size: 64,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                BuddyMessages.noTransactions,
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        // Filter chips
        if (participants.isNotEmpty || categories.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (participants.isNotEmpty)
                  PopupMenuButton<int?>(
                    child: Chip(
                      avatar: Icon(
                        LucideIcons.user,
                        size: 16,
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
                          ? const Icon(LucideIcons.x, size: 16)
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
                        (p) => PopupMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                  ),
                if (participants.isNotEmpty && categories.isNotEmpty)
                  const SizedBox(width: 8),
                if (categories.isNotEmpty)
                  PopupMenuButton<String?>(
                    child: Chip(
                      avatar: Icon(
                        LucideIcons.tag,
                        size: 16,
                        color: _filterCategory != null
                            ? color.secondary
                            : color.onSurfaceVariant,
                      ),
                      label: Text(_filterCategory ?? 'All Categories'),
                      deleteIcon: _filterCategory != null
                          ? const Icon(LucideIcons.x, size: 16)
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
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: color.error),
                  ),
                ],
              ],
            ),
          ),
        if (participants.isNotEmpty || categories.isNotEmpty)
          const SizedBox(height: 16),
        // Transactions list
        if (filteredTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.listFilter,
                    size: 48,
                    color: color.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    BuddyMessages.noFilterResults('filter'),
                    style: textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredTransactions.map((tripTxn) {
            final txn = tripTxn.transaction.value;
            final splitExp = tripTxn.splitExpense.value;
            final paidBy = tripTxn.paidBy.value;
            final displayTitle = txn?.category.value?.name
                ?? splitExp?.description
                ?? 'Uncategorized';
            final displayDesc = tripTxn.resolvedDescription;
            final displayAmount = tripTxn.resolvedAmount ?? 0;

            return Dismissible(
              key: Key('trip_txn_${tripTxn.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: color.error,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(LucideIcons.trash2, color: color.onError),
              ),
              confirmDismiss: (direction) async {
                HapticFeedback.mediumImpact();
                final confirmed = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: 'Remove Expense',
                  message: trip.isTrip
                      ? 'Remove this expense from the trip?'
                      : 'Remove this expense from the group?',
                  deleteText: 'Remove',
                );
                if (confirmed == true) {
                  await ref
                      .read(tripServiceProvider)
                      .removeTripTransaction(widget.tripId, tripTxn.id);
                  ref.invalidate(tripByIdProvider(widget.tripId));
                }
                return false;
              },
              child: Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                margin: EdgeInsets.only(bottom: spacing.cardVertical),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      AppRoutes.expenseDetail,
                      extra: {
                        'expenseId': tripTxn.id,
                        'tripId': widget.tripId,
                      },
                    );
                  },
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipOval(
                      child: BoringAvatar(
                        name: paidBy?.name ?? 'Unknown',
                        palette: BoringAvatarPalette([
                          color.primary,
                          color.tertiary,
                          color.primaryContainer,
                          color.tertiaryContainer,
                        ]),
                        type: BoringAvatarType.beam,
                      ),
                    ),
                  ),
                  title: Text(
                    displayTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Paid by ${paidBy?.name ?? "Unknown"}',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      if (displayDesc != null && displayDesc.isNotEmpty && displayDesc != displayTitle)
                        Text(
                          displayDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  trailing: CurrencyText(
                    amount: GuestModeUtil.applyGuestMode(
                      displayAmount,
                      isGuestMode,
                    ),
                    fixedLength: 0,
                    showSign: true,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSettlementsTab(
    Trip trip,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final settlementsAsync = ref.watch(tripSettlementsProvider(widget.tripId));

    return settlementsAsync.when(
      data: (settlements) {
        if (settlements.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(spacing.cardHorizontalMax),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 64,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
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
            ),
          );
        }

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
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
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
              spacing: spacing,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleAlert, size: 48, color: color.error),
            const SizedBox(height: 16),
            Text(
              'Error calculating settlements',
              style: textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab(
    Trip? trip,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final data = _computeReportData(trip);
    if (data == null) {
      return _buildEmptyReport(spacing, color, textTheme);
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _buildTotalCostCard(data, isGuestMode, spacing, color, textTheme, trip),
        SizedBox(height: spacing.cardHorizontalMax),
        _buildPerPersonCard(data, isGuestMode, spacing, color, textTheme),
        SizedBox(height: spacing.cardHorizontalMax),
        _buildCategoryBreakdownCard(
          data,
          isGuestMode,
          spacing,
          color,
          textTheme,
        ),
        // Inside _buildReportTab, at the top of ListView children: []
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _exportTripReport(
                data: data,
                tripName: trip?.name ?? '',
                startDate: trip?.startDate ?? DateTime.now(),
                endDate: trip?.endDate ?? DateTime.now(),
                context: context,
                color: color,
              ),
              icon: const Icon(LucideIcons.download, size: 18),
              label: const Text('Export as PDF'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _ReportData? _computeReportData(Trip? trip) {
    final transactionsList = trip?.transactions.toList() ?? List.empty();
    final participants = trip?.participants.toList() ?? List.empty();
    if (transactionsList.isEmpty) return null;

    double totalCost = 0;
    final Map<String, double> categoryTotals = {};
    final Map<int, double> participantSpending = {};

    for (var tripTxn in transactionsList) {
      final amount = tripTxn.resolvedAmount;
      if (amount != null) {
        totalCost += amount;
        final categoryName = tripTxn.transaction.value?.category.value?.name
            ?? tripTxn.splitExpense.value?.description
            ?? 'Uncategorized';
        categoryTotals[categoryName] =
            (categoryTotals[categoryName] ?? 0) + amount;
        final paidById = tripTxn.paidBy.value?.id;
        if (paidById != null) {
          participantSpending[paidById] =
              (participantSpending[paidById] ?? 0) + amount;
        }
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ReportData(
      totalCost: totalCost,
      transactionCount: transactionsList.length,
      categoryTotals: sortedCategories,
      participantSpending: participantSpending,
      participants: participants,
      perPersonAverage:
          participants.isNotEmpty ? totalCost / participants.length : 0,
    );
  }

  Widget _buildEmptyReport(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardHorizontalMax),
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
                LucideIcons.chartBar,
                size: 64,
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              BuddyMessages.noData,
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
      ),
    );
  }

  Widget _buildTotalCostCard(
    _ReportData data,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    Trip? trip,
  ) {
    final dailyAvg = data.transactionCount > 0
        ? data.totalCost / data.transactionCount
        : 0.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
      ),
      child: Stack(
        children: [
          // Ambient glow blobs
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.primary.withValues(alpha: 0.15),
                    color.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.tertiary.withValues(alpha: 0.12),
                    color.tertiary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              children: [
                // Animated ring with icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CustomPaint(
                            painter: _RingPainter(
                              progress: value,
                              color: color.primary,
                              bgColor: color.primary.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.wallet,
                          color: color.primary,
                          size: 28,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  trip?.isTrip == true ? 'Total Trip Cost' : 'Total Group Cost',
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  tween: Tween(
                    begin: 0.0,
                    end: GuestModeUtil.applyGuestMode(
                      data.totalCost,
                      isGuestMode,
                    ),
                  ),
                  builder: (context, value, child) {
                    return CurrencyText(
                      amount: value,
                      compact: false,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color.onPrimaryContainer,
                      ),
                    );
                  },
                ),
                SizedBox(height: spacing.sectionGap),
                // Bento stat pills
                Row(
                  children: [
                    Expanded(
                      child: _buildStatPill(
                        icon: LucideIcons.receiptText,
                        label: 'Transactions',
                        value: '${data.transactionCount}',
                        color: color,
                        textTheme: textTheme,
                        spacing: spacing,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildStatPill(
                        icon: LucideIcons.users,
                        label: 'Per Person',
                        value:
                            '₹${GuestModeUtil.applyGuestMode(data.perPersonAverage.toDouble(), isGuestMode).toStringAsFixed(0)}',
                        color: color,
                        textTheme: textTheme,
                        spacing: spacing,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildStatPill(
                        icon: LucideIcons.trendingUp,
                        label: 'Avg/Txn',
                        value:
                            '₹${GuestModeUtil.applyGuestMode(dailyAvg, isGuestMode).toStringAsFixed(0)}',
                        color: color,
                        textTheme: textTheme,
                        spacing: spacing,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacing.cardVertical,
        horizontal: spacing.cardHorizontal,
      ),
      decoration: BoxDecoration(
        color: color.onPrimaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color.onPrimaryContainer.withValues(alpha: 0.6),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.onPrimaryContainer,
            ),
          ),
          SizedBox(height: spacing.cardVerticalMin),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color.onPrimaryContainer.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerPersonCard(
    _ReportData data,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final topSpenderId = data.participantSpending.entries.isEmpty
        ? null
        : (data.participantSpending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.users, color: color.secondary, size: 20),
                SizedBox(width: spacing.sectionGap),
                Text(
                  'Per Person Summary',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              decoration: BoxDecoration(
                color: color.secondaryContainer,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Average per person',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CurrencyText(
                    amount: GuestModeUtil.applyGuestMode(
                      data.perPersonAverage.toDouble(),
                      isGuestMode,
                    ),
                    compact: false,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...data.participants.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final spent = data.participantSpending[p.id] ?? 0;
              final percentage =
                  data.totalCost > 0 ? (spent / data.totalCost * 100) : 0;
              final isTopSpender = p.id == topSpenderId;
              final barColor =
                  _chartColors(color)[i % _chartColors(color).length];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipOval(
                        child: BoringAvatar(
                          name: p.name,
                          palette: BoringAvatarPalette([
                            color.primary,
                            color.tertiary,
                            color.primaryContainer,
                            color.tertiaryContainer,
                          ]),
                          type: BoringAvatarType.beam,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.cardHorizontal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isTopSpender) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    '👑 Top',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 6,
                              backgroundColor: color.surface,
                              valueColor: AlwaysStoppedAnimation(barColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CurrencyText(
                          amount: GuestModeUtil.applyGuestMode(
                            spent,
                            isGuestMode,
                          ),
                          compact: false,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: barColor,
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(
    _ReportData data,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final colors = _chartColors(color);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.chartPie, color: color.primary, size: 20),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Category Breakdown',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: data.categoryTotals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final percentage = cat.value / data.totalCost * 100;
                    return PieChartSectionData(
                      value: cat.value,
                      color: colors[i % colors.length],
                      radius: 50,
                      title: '${percentage.toStringAsFixed(0)}%',
                      titleStyle: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...data.categoryTotals.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final percentage = cat.value / data.totalCost * 100;
              final catColor = colors[i % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: spacing.sectionGap),
                    Expanded(
                      child: Text(
                        cat.key,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CurrencyText(
                      amount: GuestModeUtil.applyGuestMode(
                        cat.value,
                        isGuestMode,
                      ),
                      compact: false,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                    SizedBox(width: spacing.sectionGap),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Color> _chartColors(ColorScheme color) => [
        color.primary,
        color.tertiary,
        color.secondary,
        color.error,
        color.primaryContainer,
        color.tertiaryContainer,
        color.secondaryContainer,
        color.errorContainer,
      ];

  Future<void> _exportTripReport({
    required _ReportData data,
    required String tripName,
    required DateTime startDate,
    required DateTime endDate,
    required BuildContext context,
    required ColorScheme color,
  }) async {
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final fontData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final font = pw.Font.ttf(fontData);
      final now = DateTime.now();
      final pdf = pw.Document();

      final totalCost = data.totalCost;
      final perPerson = data.perPersonAverage.toDouble();
      final participantRows = data.participants.map((p) {
        final spent = data.participantSpending[p.id] ?? 0.0;
        final pct = totalCost > 0 ? (spent / totalCost * 100) : 0.0;
        return [
          p.name,
          '₹${spent.toStringAsFixed(2)}',
          '${pct.toStringAsFixed(1)}%',
        ];
      }).toList();

      final categoryRows = data.categoryTotals.map((e) {
        final pct = totalCost > 0 ? (e.value / totalCost * 100) : 0.0;
        return [
          e.key,
          '₹${e.value.toStringAsFixed(2)}',
          '${pct.toStringAsFixed(1)}%',
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: font),
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tripName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Trip Report',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            // Trip info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _pdfInfoRow(
                    'Period',
                    '${DateFormat('dd MMM yyyy').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}',
                    font,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfInfoRow(
                    'Generated',
                    DateFormat('dd MMM yyyy, hh:mm a').format(now),
                    font,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _pdfSummaryRow(
                    'Total Cost',
                    '₹${totalCost.toStringAsFixed(2)}',
                    PdfColors.blue900,
                    bold: true,
                  ),
                  pw.SizedBox(height: 8),
                  _pdfSummaryRow(
                    'Transactions',
                    '${data.transactionCount}',
                    PdfColors.grey800,
                  ),
                  pw.SizedBox(height: 8),
                  _pdfSummaryRow(
                    'Participants',
                    '${data.participants.length}',
                    PdfColors.grey800,
                  ),
                  pw.SizedBox(height: 8),
                  _pdfSummaryRow(
                    'Avg Per Person',
                    '₹${perPerson.toStringAsFixed(2)}',
                    PdfColors.blue900,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Participant breakdown
            pw.Text(
              'Participant Breakdown',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Name', 'Amount', 'Share'],
              data: participantRows,
            ),
            pw.SizedBox(height: 20),
            // Category breakdown
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Category', 'Amount', 'Share'],
              data: categoryRows,
            ),
          ],
          footer: (ctx) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount} • Mudra Manager',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'Trip_${tripName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(now)}.pdf';
      await saveExportedFile(bytes, fileName, askUser: true);

      messenger.showSnackBar(
        const SnackBar(content: Text('Report exported successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  pw.Widget _pdfInfoRow(String label, String value, pw.Font font) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _pdfSummaryRow(
    String label,
    String value,
    PdfColor pdfColor, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: bold ? 14 : 12,
            color: pdfColor,
          ),
        ),
      ],
    );
  }
}

class _ReportData {
  final double totalCost;
  final int transactionCount;
  final List<MapEntry<String, double>> categoryTotals;
  final Map<int, double> participantSpending;
  final List<dynamic> participants;
  final num perPersonAverage;

  const _ReportData({
    required this.totalCost,
    required this.transactionCount,
    required this.categoryTotals,
    required this.participantSpending,
    required this.participants,
    required this.perPersonAverage,
  });
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [color, color.withValues(alpha: 0.5), color],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-3.14159 / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
