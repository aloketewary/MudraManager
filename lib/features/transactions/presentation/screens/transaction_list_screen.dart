import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const TransactionListScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      TransactionListScreenState();
}

class TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with TickerProviderStateMixin {
  String _filter = 'all';
  double rightBoxWidthFactor = 0.3;
  double leftBoxWidthFactor = 0.3;
  double middleBoxWidthFactor = 0.3;
  double tiltAngleDegrees = 20.0;
  double tiltExpenseAngleDegrees = 20.0;
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
  bool _useInfiniteScroll =
      true; // New: toggle between infinite scroll and month view

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

  void _onFabPressed() {
    context.push('/add-transaction');
  }

  List<DateTime> generateCircularMonths({int count = 12}) {
    final now = DateTime.now();
    return List.generate(
      count * 2 + 1,
      (i) => DateTime(now.year, now.month - count + i),
    );
  }

  String formatDateHeader(DateTime date, String locale) {
    final ctxt = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    if (dateOnly == todayOnly) return ctxt.transaction_listViewGroupTodayLabel;
    if (dateOnly == yesterdayOnly) {
      return ctxt.transaction_listViewGroupYesterdayLabel;
    }

    return DateFormat.yMMMMd(locale).format(date); // e.g., May 14, 2025
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  void toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
    });
  }

  String _getDateRangeText() {
    if (_filterStartDate != null && _filterEndDate != null) {
      return '${DateFormat.MMMd().format(_filterStartDate!)} - ${DateFormat.MMMd().format(_filterEndDate!)}';
    }
    return DateFormat.yMMMM().format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
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
                  icon: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  ),
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 500,
              ), // slower and smoother
              switchInCurve: Curves.easeInOutBack,
              switchOutCurve: Curves.easeIn,
              child: FloatingActionButton.extended(
                key: const ValueKey('extended'),
                heroTag: 'addTransactionHeroTransactionList',
                onPressed: _onFabPressed,
                icon: const Icon(Icons.add),
                label: AdaptiveText(
                  ctxt.dashboard_add_transaction_text,
                  style: textTheme.labelLarge,
                  maxLines: 1,
                ),
              ),
            ),
          )
        : Hero(tag: 'cashFlowPage', child: _buildMainComponent());
  }

  Widget _buildMainComponent() {
    final pendingTxnCountService = ref.watch(pendingTxnCountProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    final sectionedAsync =
        _useInfiniteScroll && _filterStartDate == null && _filterEndDate == null
        ? ref.watch(allSectionedTransactionsProvider(_filter))
        : _filterStartDate != null && _filterEndDate != null
        ? ref.watch(
            sectionedTransactionsByDateRangeProvider((
              start: _filterStartDate!,
              end: _filterEndDate!,
              type: _filter,
            )),
          )
        : ref.watch(
            sectionedTransactionsProvider((
              month: _selectedDate,
              type: _filter,
            )),
          );

    return Column(
      children: [
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: color.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: color.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        if (_selectedCategoryId != null || _filterStartDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedCategoryId != null)
                  Chip(
                    avatar: Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: color.primary,
                    ),
                    label: Text('Category', style: textTheme.labelMedium),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    backgroundColor: color.primaryContainer,
                    side: BorderSide.none,
                    onDeleted: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedCategoryId = null);
                    },
                  ),
                if (_filterStartDate != null)
                  Chip(
                    avatar: Icon(
                      Icons.date_range_rounded,
                      size: 18,
                      color: color.primary,
                    ),
                    label: Text('Date Range', style: textTheme.labelMedium),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    backgroundColor: color.primaryContainer,
                    side: BorderSide.none,
                    onDeleted: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        pendingTxnCountService.when(
          data: (count) {
            if (count > 0) {
              return MaterialBanner(
                backgroundColor: color.primaryContainer,
                content: Text(
                  ctxt.transaction_list_pending_transaction_message_text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onPrimaryContainer,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pending-transactions');
                    },
                    child: Text(
                      ctxt.transaction_listPendingTransactionMessageActionLabel
                          .toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: color.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _showCalendar = !_showCalendar;
                      _showMonthPicker = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: color.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _useInfiniteScroll &&
                                            _filterStartDate == null
                                        ? 'All Transactions'
                                        : _getDateRangeText(),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color.onSurface,
                                    ),
                                  ),
                                  if (_rangeSelectionMode ==
                                      RangeSelectionMode.toggledOn)
                                    Text(
                                      'Tap start and end date',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.primary,
                                      ),
                                    )
                                  else if (_useInfiniteScroll &&
                                      _filterStartDate == null)
                                    Text(
                                      'Scroll to load more',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: color.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_useInfiniteScroll ||
                                      _filterStartDate != null) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                        size: 22,
                                      ),
                                      tooltip: 'Previous Month',
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedDate = DateTime(
                                            _selectedDate.year,
                                            _selectedDate.month - 1,
                                          );
                                          _focusedDay = _selectedDate;
                                        });
                                      },
                                    ),
                                    if (!isSameMonth(
                                      _selectedDate,
                                      DateTime.now(),
                                    ))
                                      IconButton(
                                        icon: Icon(
                                          Icons.refresh_rounded,
                                          size: 20,
                                          color: color.primary,
                                        ),
                                        tooltip: 'Reset to Current Month',
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          setState(() {
                                            _selectedDate = DateTime.now();
                                            _focusedDay = DateTime.now();
                                          });
                                        },
                                      )
                                    else
                                      IconButton(
                                        icon: Icon(
                                          Icons.calendar_month_rounded,
                                          size: 20,
                                          color: color.primary,
                                        ),
                                        tooltip: 'Select Month',
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          setState(
                                            () => _showMonthPicker =
                                                !_showMonthPicker,
                                          );
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 22,
                                      ),
                                      tooltip: 'Next Month',
                                      onPressed:
                                          isSameMonth(
                                            _selectedDate,
                                            DateTime.now(),
                                          )
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              setState(() {
                                                _selectedDate = DateTime(
                                                  _selectedDate.year,
                                                  _selectedDate.month + 1,
                                                );
                                                _focusedDay = _selectedDate;
                                              });
                                            },
                                    ),
                                  ],
                                  IconButton(
                                    icon: Icon(
                                      _useInfiniteScroll &&
                                              _filterStartDate == null
                                          ? Icons.view_list_rounded
                                          : Icons.all_inclusive_rounded,
                                      size: 20,
                                      color: color.primary,
                                    ),
                                    tooltip: _useInfiniteScroll
                                        ? 'Month View'
                                        : 'All Transactions',
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        _useInfiniteScroll =
                                            !_useInfiniteScroll;
                                        _displayLimit = 50;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _showCalendar || _showMonthPicker
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: color.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (_showCalendar || _showMonthPicker)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SegmentedButton<RangeSelectionMode>(
                              segments: const [
                                ButtonSegment(
                                  value: RangeSelectionMode.toggledOff,
                                  label: Text('Month'),
                                  icon: Icon(
                                    Icons.calendar_view_month_rounded,
                                    size: 16,
                                  ),
                                ),
                                ButtonSegment(
                                  value: RangeSelectionMode.toggledOn,
                                  label: Text('Date Range'),
                                  icon: Icon(
                                    Icons.date_range_rounded,
                                    size: 16,
                                  ),
                                ),
                              ],
                              selected: {_rangeSelectionMode},
                              onSelectionChanged:
                                  (Set<RangeSelectionMode> newSelection) {
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _rangeSelectionMode = newSelection.first;
                                      if (_rangeSelectionMode ==
                                          RangeSelectionMode.toggledOff) {
                                        _filterStartDate = null;
                                        _filterEndDate = null;
                                      }
                                    });
                                  },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showCalendar && _showMonthPicker)
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final month = index + 1;
                              final monthDate = DateTime(
                                _selectedDate.year,
                                month,
                                1,
                              );
                              final isSelected = _selectedDate.month == month;
                              final isFuture = monthDate.isAfter(
                                DateTime.now(),
                              );
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isFuture
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _selectedDate = DateTime(
                                              _selectedDate.year,
                                              month,
                                              1,
                                            );
                                            _focusedDay = _selectedDate;
                                            _showMonthPicker = false;
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.primaryContainer
                                          : color.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      DateFormat.MMM().format(
                                        DateTime(2000, month),
                                      ),
                                      style: textTheme.titleSmall?.copyWith(
                                        color: isFuture
                                            ? color.onSurface.withValues(
                                                alpha: 0.3,
                                              )
                                            : isSelected
                                            ? color.primary
                                            : color.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedDate = DateTime(
                                        _selectedDate.year - 1,
                                        _selectedDate.month,
                                        1,
                                      );
                                      _focusedDay = _selectedDate;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 18,
                                  ),
                                  label: Text('${_selectedDate.year - 1}'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: color.onSurface,
                                  ),
                                ),
                                Text(
                                  '${_selectedDate.year}',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color.primary,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed:
                                      _selectedDate.year >= DateTime.now().year
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _selectedDate = DateTime(
                                              _selectedDate.year + 1,
                                              _selectedDate.month,
                                              1,
                                            );
                                            _focusedDay = _selectedDate;
                                          });
                                        },
                                  icon: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                  ),
                                  label: Text('${_selectedDate.year + 1}'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        _selectedDate.year >=
                                            DateTime.now().year
                                        ? color.onSurface.withValues(alpha: 0.3)
                                        : color.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showCalendar)
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
                        ? isSameMonth(day, _selectedDate)
                        : false,
                    onDaySelected: (selectedDay, focusedDay) {
                      if (_rangeSelectionMode ==
                          RangeSelectionMode.toggledOff) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedDate = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            1,
                          );
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
                        if (start != null && end != null) {
                          _showCalendar = false;
                        }
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        if (_rangeSelectionMode ==
                            RangeSelectionMode.toggledOff) {
                          _selectedDate = DateTime(
                            focusedDay.year,
                            focusedDay.month,
                            1,
                          );
                        }
                      });
                    },
                    enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color:
                            _rangeSelectionMode == RangeSelectionMode.toggledOff
                            ? color.primaryContainer.withValues(alpha: 0.3)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color:
                            _rangeSelectionMode == RangeSelectionMode.toggledOff
                            ? Colors.transparent
                            : color.primary,
                        shape: BoxShape.circle,
                        border:
                            _rangeSelectionMode == RangeSelectionMode.toggledOff
                            ? Border.all(color: color.primary, width: 2)
                            : null,
                      ),
                      rangeStartDecoration: BoxDecoration(
                        color: color.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: color.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: color.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      todayTextStyle: TextStyle(
                        color:
                            _rangeSelectionMode == RangeSelectionMode.toggledOff
                            ? color.onSurface
                            : color.onSurface,
                      ),
                      selectedTextStyle: TextStyle(
                        color:
                            _rangeSelectionMode == RangeSelectionMode.toggledOff
                            ? color.primary
                            : color.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeStartTextStyle: TextStyle(color: color.onPrimary),
                      rangeEndTextStyle: TextStyle(color: color.onPrimary),
                      disabledTextStyle: TextStyle(
                        color: color.onSurface.withValues(alpha: 0.3),
                      ),
                      weekendTextStyle: TextStyle(color: color.onSurface),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: sectionedAsync.when(
            data: (sectioned) {
              final filtered = _filterTransactions(sectioned);

              if (filtered.isEmpty) {
                return NoDataFound(
                  message:
                      _searchQuery.isNotEmpty ||
                          _selectedCategoryId != null ||
                          _filterStartDate != null
                      ? 'No matching transactions'
                      : ctxt.transaction_noTransactionFoundText,
                  iconData: Icons.receipt_long_outlined,
                );
              }

              final displayItems = filtered.take(_displayLimit).toList();
              final hasMore = filtered.length > _displayLimit;

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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      child: Text(
                        formatDateHeader(
                          entry.group,
                          ctxt.localeName,
                        ).toUpperCase(),
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
                  final tags = transaction.tags.toList();

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
                        tags: tags,
                        related: transaction.related.value,
                        tripName: snapshot.data,
                        onEdit: () {
                          transaction.isTransfer
                              ? context.push(
                                  '/transfer',
                                  extra: {
                                    'amount': transaction.amount
                                        .toStringAsFixed(2),
                                    'note': transaction.description,
                                    'date': transaction.date,
                                    'fromAccount': transaction
                                        .related
                                        .value
                                        ?.account
                                        .value,
                                    'toAccount': transaction.account.value,
                                    'fromId': transaction.related.value?.id,
                                    'toId': transaction.id,
                                  },
                                )
                              : context.push(
                                  '/add-transaction',
                                  extra: {'transaction': transaction},
                                );
                        },
                        onRemove: () async {
                          final confirm =
                              await DialogUtils.showDeleteConfirmation(
                                context,
                                title: ctxt.transaction_deleteAlertTitleText,
                                message: ctxt.transaction_deleteAlertBodyText,
                                cancelText:
                                    ctxt.transaction_cancelButtonActionText,
                                deleteText:
                                    ctxt.transaction_deleteButtonActionText,
                              );

                          if (confirm == true) {
                            await ref
                                .read(tripServiceProvider)
                                .removeTransactionFromTrip(transaction.id);
                            if (transaction.isTransfer) {
                              await ref
                                  .read(transactionProvider)
                                  .deleteTransaction(
                                    transaction.related.value?.id ?? 0,
                                  );
                            }
                            await ref
                                .read(transactionProvider)
                                .deleteTransaction(transaction.id);
                            ref.invalidate(transactionProvider);
                            ref.invalidate(allTripsProvider);
                          }
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
          ),
        ),
      ],
    );
  }

  List<TxListEntry> _filterTransactions(List<TxListEntry> sectioned) {
    if (_searchQuery.isEmpty && _selectedCategoryId == null) {
      return sectioned;
    }

    final filtered = <TxListEntry>[];
    DateTime? currentDate;

    for (var entry in sectioned) {
      if (entry is TxHeader) {
        currentDate = entry.group;
        continue;
      }

      final txItem = entry as TxItem;
      final tx = txItem.txn;

      bool matches = true;

      if (_searchQuery.isNotEmpty) {
        final desc = tx.description?.toLowerCase() ?? '';
        matches = matches && desc.contains(_searchQuery);
      }

      if (_selectedCategoryId != null) {
        matches = matches && tx.category.value?.id == _selectedCategoryId;
      }

      if (matches && currentDate != null) {
        if (filtered.isEmpty || filtered.last is! TxHeader) {
          filtered.add(TxHeader(currentDate));
        } else {
          final lastHeader = filtered.last as TxHeader;
          if (lastHeader.group.year != currentDate.year ||
              lastHeader.group.month != currentDate.month ||
              lastHeader.group.day != currentDate.day) {
            filtered.add(TxHeader(currentDate));
          }
        }
        filtered.add(txItem);
      }
    }

    return filtered;
  }

  void showFilterBottomSheet(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isar = await ref.read(isarServiceProvider).getInstance();
    final allCategories = await isar.categorys.where().findAll();
    for (final cat in allCategories) {
      await cat.parentCategory.load();
    }
    final parentCategories = allCategories
        .where((c) => c.parentCategory.value == null)
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Filter Options',
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Transaction Type',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadioListTile<String>(
                          value: 'all',
                          groupValue: _filter,
                          title: Text(
                            ctxt.transaction_list_filter_all.toUpperCase(),
                          ),
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() => _filter = value!);
                            setModalState(() {});
                          },
                        ),
                        RadioListTile<String>(
                          value: 'income',
                          groupValue: _filter,
                          title: Text(
                            ctxt.transaction_list_filter_income.toUpperCase(),
                          ),
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() => _filter = value!);
                            setModalState(() {});
                          },
                        ),
                        RadioListTile<String>(
                          value: 'expense',
                          groupValue: _filter,
                          title: Text(
                            ctxt.transaction_list_filter_expense.toUpperCase(),
                          ),
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() => _filter = value!);
                            setModalState(() {});
                          },
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Category',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadioListTile<int?>(
                          value: null,
                          groupValue: _selectedCategoryId,
                          title: const Text('All Categories'),
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() => _selectedCategoryId = null);
                            setModalState(() {});
                          },
                        ),
                        ...parentCategories.map((parent) {
                          final subcategories = allCategories
                              .where(
                                (c) => c.parentCategory.value?.id == parent.id,
                              )
                              .toList();
                          final hasSubcategories = subcategories.isNotEmpty;

                          return Column(
                            children: [
                              RadioListTile<int?>(
                                value: parent.id,
                                groupValue: _selectedCategoryId,
                                title: Row(
                                  children: [
                                    Icon(
                                      IconHelper.getIconData(parent.iconName),
                                      size: 20,
                                      color: Color(
                                        parent.colorValue ?? 0xFF9E9E9E,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(parent.name)),
                                    if (hasSubcategories)
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: color.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                                onChanged: (value) {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _selectedCategoryId = value);
                                  setModalState(() {});
                                },
                              ),
                              if (hasSubcategories)
                                ...subcategories.map(
                                  (sub) => Padding(
                                    padding: const EdgeInsets.only(left: 32),
                                    child: RadioListTile<int?>(
                                      value: sub.id,
                                      groupValue: _selectedCategoryId,
                                      title: Row(
                                        children: [
                                          Icon(
                                            IconHelper.getIconData(
                                              sub.iconName,
                                            ),
                                            size: 18,
                                            color: Color(
                                              sub.colorValue ?? 0xFF9E9E9E,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            sub.name,
                                            style: textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      onChanged: (value) {
                                        HapticFeedback.mediumImpact();
                                        setState(
                                          () => _selectedCategoryId = value,
                                        );
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Date Range',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.date_range, color: color.primary),
                          title: Text(
                            _filterStartDate != null && _filterEndDate != null
                                ? '${DateFormat.yMMMd().format(_filterStartDate!)} - ${DateFormat.yMMMd().format(_filterEndDate!)}'
                                : 'Select Date Range',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange:
                                  _filterStartDate != null &&
                                      _filterEndDate != null
                                  ? DateTimeRange(
                                      start: _filterStartDate!,
                                      end: _filterEndDate!,
                                    )
                                  : null,
                            );
                            if (picked != null) {
                              setState(() {
                                _filterStartDate = picked.start;
                                _filterEndDate = picked.end;
                              });
                              setModalState(() {});
                            }
                          },
                        ),
                        if (_filterStartDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _filterStartDate = null;
                                  _filterEndDate = null;
                                });
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Date Range'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('APPLY FILTERS'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
