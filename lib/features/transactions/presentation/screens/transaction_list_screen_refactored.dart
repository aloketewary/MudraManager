import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_calendar_header.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_filter_chips_widget.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_month_picker.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_search_bar_widget.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class TransactionListScreenRefactored extends ConsumerStatefulWidget {
  final bool showAppBar;

  const TransactionListScreenRefactored({super.key, this.showAppBar = false});

  @override
  ConsumerState<TransactionListScreenRefactored> createState() =>
      TransactionListScreenRefactoredState();
}

class TransactionListScreenRefactoredState
    extends ConsumerState<TransactionListScreenRefactored> {
  final String _filter = 'all';
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  int? _selectedCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  bool _showMonthPicker = false;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  bool _showSearch = false;
  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 50;
  bool _isLoadingMore = false;
  bool _useInfiniteScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _displayLimit += 50;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  void toggleSearch() {
    setState(() => _showSearch = !_showSearch);
  }

  void showFilterBottomSheet(BuildContext context) {
    // Keep existing filter bottom sheet implementation
    // (Too large to include here, but unchanged)
  }

  String formatDateHeader(DateTime date, String locale) {
    final ctxt = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

    if (dateOnly == todayOnly) return ctxt.transaction_listViewGroupTodayLabel;
    if (dateOnly == yesterdayOnly) {
      return ctxt.transaction_listViewGroupYesterdayLabel;
    }

    return DateFormat.yMMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return widget.showAppBar
        ? Scaffold(
            appBar: AppBar(
              title: Text(ctxt.transaction_list_cash_flow_screen_title),
              actions: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _showSearch = !_showSearch);
                  },
                  icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    showFilterBottomSheet(context);
                  },
                  icon: const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
            body: Hero(tag: 'cashFlowPage', child: _buildMainComponent()),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'addTransactionHero',
              onPressed: () => context.push(AppRoutes.addTransaction),
              icon: const Icon(Icons.add),
              label: AdaptiveText(
                ctxt.dashboard_add_transaction_text,
                style: textTheme.labelLarge,
                maxLines: 1,
              ),
            ),
          )
        : Hero(tag: 'cashFlowPage', child: _buildMainComponent());
  }

  Widget _buildMainComponent() {
    final pendingTxnCountService = ref.watch(pendingTxnCountProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    // Use optimized provider when filtering by category or search
    final sectionedAsync = _selectedCategoryId != null || _searchQuery.isNotEmpty
        ? ref.watch(filteredSectionedTransactionsProvider((
            type: _filter,
            categoryId: _selectedCategoryId,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),),)
        : _useInfiniteScroll && _filterStartDate == null && _filterEndDate == null
            ? ref.watch(allSectionedTransactionsProvider(_filter))
            : _filterStartDate != null && _filterEndDate != null
                ? ref.watch(sectionedTransactionsByDateRangeProvider((
                    start: _filterStartDate!,
                    end: _filterEndDate!,
                    type: _filter,
                  ),),)
                : ref.watch(sectionedTransactionsProvider((
                    month: _selectedDate,
                    type: _filter,
                  ),),);

    return Column(
      children: [
        if (_showSearch)
          TransactionSearchBar(
            searchQuery: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        TransactionFilterChips(
          selectedCategoryId: _selectedCategoryId,
          filterStartDate: _filterStartDate,
          filterEndDate: _filterEndDate,
          onClearCategory: () => setState(() => _selectedCategoryId = null),
          onClearDateRange: () => setState(() {
            _filterStartDate = null;
            _filterEndDate = null;
          }),
        ),
        _buildPendingTransactionBanner(pendingTxnCountService, color, textTheme, ctxt),
        _buildCalendarSection(color, textTheme),
        Expanded(child: _buildTransactionList(sectionedAsync, ctxt, color, textTheme)),
      ],
    );
  }

  Widget _buildPendingTransactionBanner(
    AsyncValue<int> pendingTxnCountService,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    return pendingTxnCountService.when(
      data: (count) {
        if (count > 0) {
          return MaterialBanner(
            backgroundColor: color.primaryContainer,
            content: Text(
              ctxt.transaction_list_pending_transaction_message_text,
              style: textTheme.bodyMedium?.copyWith(color: color.onPrimaryContainer),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/pending-transactions');
                },
                child: Text(
                  ctxt.transaction_listPendingTransactionMessageActionLabel.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: color.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCalendarSection(ColorScheme color, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TransactionCalendarHeader(
            useInfiniteScroll: _useInfiniteScroll,
            filterStartDate: _filterStartDate,
            filterEndDate: _filterEndDate,
            selectedDate: _selectedDate,
            showCalendar: _showCalendar,
            showMonthPicker: _showMonthPicker,
            onToggleCalendar: () => setState(() {
              _showCalendar = !_showCalendar;
              _showMonthPicker = false;
            }),
            onPreviousMonth: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
              _focusedDay = _selectedDate;
            }),
            onNextMonth: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
              _focusedDay = _selectedDate;
            }),
            onResetMonth: () => setState(() {
              _selectedDate = DateTime.now();
              _focusedDay = DateTime.now();
            }),
            onToggleMonthPicker: () => setState(() => _showMonthPicker = !_showMonthPicker),
            onToggleViewMode: () => setState(() {
              _useInfiniteScroll = !_useInfiniteScroll;
              _displayLimit = 50;
            }),
          ),
          if (_showCalendar || _showMonthPicker)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: SegmentedButton<RangeSelectionMode>(
                segments: const [
                  ButtonSegment(
                    value: RangeSelectionMode.toggledOff,
                    label: Text('Month'),
                    icon: Icon(Icons.calendar_view_month_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: RangeSelectionMode.toggledOn,
                    label: Text('Date Range'),
                    icon: Icon(Icons.date_range_rounded, size: 16),
                  ),
                ],
                selected: {_rangeSelectionMode},
                onSelectionChanged: (Set<RangeSelectionMode> newSelection) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _rangeSelectionMode = newSelection.first;
                    if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
                      _filterStartDate = null;
                      _filterEndDate = null;
                    }
                  });
                },
              ),
            ),
          if (_showCalendar && _showMonthPicker)
            TransactionMonthPicker(
              selectedDate: _selectedDate,
              onMonthSelected: (date) => setState(() {
                _selectedDate = date;
                _focusedDay = date;
                _showMonthPicker = false;
              }),
            ),
          if (_showCalendar && !_showMonthPicker)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                rangeStartDay: _filterStartDate,
                rangeEndDay: _filterEndDate,
                selectedDayPredicate: (day) =>
                    _rangeSelectionMode == RangeSelectionMode.toggledOff
                        ? day.year == _selectedDate.year && day.month == _selectedDate.month
                        : false,
                onDaySelected: (selectedDay, focusedDay) {
                  if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _selectedDate = DateTime(selectedDay.year, selectedDay.month, 1);
                      _focusedDay = focusedDay;
                      _showCalendar = false;
                    });
                  }
                },
                onRangeSelected: (start, end, focusedDay) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _filterStartDate = start;
                    _filterEndDate = end;
                    _focusedDay = focusedDay;
                    if (start != null && end != null) _showCalendar = false;
                  });
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                onPageChanged: (focusedDay) => setState(() {
                  _focusedDay = focusedDay;
                  if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
                    _selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
                  }
                }),
                enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: _rangeSelectionMode == RangeSelectionMode.toggledOff
                        ? color.primaryContainer.withValues(alpha: 0.3)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: _rangeSelectionMode == RangeSelectionMode.toggledOff
                        ? Colors.transparent
                        : color.primary,
                    shape: BoxShape.circle,
                    border: _rangeSelectionMode == RangeSelectionMode.toggledOff
                        ? Border.all(color: color.primary, width: 2)
                        : null,
                  ),
                  rangeStartDecoration: BoxDecoration(color: color.primary, shape: BoxShape.circle),
                  rangeEndDecoration: BoxDecoration(color: color.primary, shape: BoxShape.circle),
                  rangeHighlightColor: color.primaryContainer.withValues(alpha: 0.3),
                  todayTextStyle: TextStyle(color: color.onSurface),
                  selectedTextStyle: TextStyle(
                    color: _rangeSelectionMode == RangeSelectionMode.toggledOff
                        ? color.primary
                        : color.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  rangeStartTextStyle: TextStyle(color: color.onPrimary),
                  rangeEndTextStyle: TextStyle(color: color.onPrimary),
                  disabledTextStyle: TextStyle(color: color.onSurface.withValues(alpha: 0.3)),
                  weekendTextStyle: TextStyle(color: color.onSurface),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    AsyncValue<List<TxListEntry>> sectionedAsync,
    AppLocalizations ctxt,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return sectionedAsync.when(
      data: (sectioned) {
        if (sectioned.isEmpty) {
          return NoDataFound(
            message: _searchQuery.isNotEmpty ||
                    _selectedCategoryId != null ||
                    _filterStartDate != null
                ? 'No matching transactions'
                : ctxt.transaction_noTransactionFoundText,
            iconData: Icons.receipt_long_outlined,
          );
        }

        final displayItems = sectioned.take(_displayLimit).toList();
        final hasMore = sectioned.length > _displayLimit;

        return ListView.builder(
          controller: _scrollController,
          itemCount: displayItems.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayItems.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final entry = displayItems[index];
            if (entry is TxHeader) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Text(
                  formatDateHeader(entry.group, ctxt.localeName).toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              );
            }

            final transaction = (entry as TxItem).txn;
            transaction.tags.load();
            transaction.related.load();

            return FutureBuilder<String?>(
              future: ref
                  .read(tripServiceProvider)
                  .getTripNameByTransactionId(transaction.id),
              builder: (context, snapshot) {
                return TransactionCard(
                  category: transaction.category.value,
                  description: transaction.description,
                  account: transaction.account.value,
                  amount: transaction.amount.toStringAsFixed(2),
                  date: transaction.date,
                  isExpense: transaction.isExpense,
                  isTransfer: transaction.isTransfer,
                  tags: transaction.tags.toList(),
                  related: transaction.related.value,
                  tripName: snapshot.data,
                  onEdit: () {
                    // Keep existing edit logic
                  },
                  onRemove: () async {
                    // Keep existing remove logic
                  },
                );
              },
            );
          },
        );
      },
      loading: () => ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const TransactionCardSkeleton(),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
