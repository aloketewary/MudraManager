import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/speed_dial_fab.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

final _dateHeaderFormatter = DateFormat.yMMMMd();

class TransactionListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final Function(bool isScrollingDown)? onScrollChanged;
  final bool isTabActive;

  const TransactionListScreen({
    super.key,
    this.showAppBar = false,
    this.onScrollChanged,
    this.isTabActive = true,
  });

  @override
  ConsumerState<TransactionListScreen> createState() =>
      TransactionListScreenState();
}

class TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _filter = 'all';
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  int? _selectedCategoryId;
  int? _selectedTagId;
  String? _selectedTagName;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  bool _showMonthPicker = false;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  bool _showSearch = false;
  late final ScrollController _scrollController;
  int _displayLimit = 50;
  bool _isLoadingMore = false;
  bool _useInfiniteScroll = true;
  List<TxListEntry>? _cachedFiltered;
  String _lastFilterKey = '';
  double _lastScrollOffset = 0;
  Timer? _searchDebounce;

  // Trip names caching
  List<int>? _lastTxIds;
  Future<Map<int, String>>? _tripNamesFuture;
  AnimationController? _fabController;
  final _speedDialKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(keepScrollOffset: true);
    _scrollController.addListener(_onScroll);
    if (widget.showAppBar) {
      _fabController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: 1.0,
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _fabController?.dispose();
    super.dispose();
  }

  void _clearCache() {
    _cachedFiltered = null;
    _lastFilterKey = '';
    _lastTxIds = null;
    _tripNamesFuture = null;
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    if (widget.onScrollChanged != null &&
        (currentOffset - _lastScrollOffset).abs() > 10) {
      widget.onScrollChanged!(
        currentOffset > _lastScrollOffset && currentOffset > 100,
      );
      _lastScrollOffset = currentOffset;
    }

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      setState(() => _displayLimit += 50);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isLoadingMore = false;
      });
    }
  }

  String formatDateHeader(DateTime date, String locale) {
    final ctxt = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly =
        DateTime(yesterday.year, yesterday.month, yesterday.day);

    final isViewingCurrentMonth = _useInfiniteScroll ||
        (_selectedDate.year == today.year &&
            _selectedDate.month == today.month);

    if (isViewingCurrentMonth) {
      if (dateOnly == todayOnly) {
        return ctxt.transaction_listViewGroupTodayLabel;
      }
      if (dateOnly == yesterdayOnly) {
        return ctxt.transaction_listViewGroupYesterdayLabel;
      }
    }

    return _dateHeaderFormatter.format(date);
  }

  bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  void toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) _searchQuery = '';
    });
  }

  String _getDateRangeText() {
    if (_filterStartDate != null && _filterEndDate != null) {
      return '${DateFormat.MMMd().format(_filterStartDate!)} - ${DateFormat.MMMd().format(_filterEndDate!)}';
    }
    return DateFormat.yMMMM().format(_selectedDate);
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return widget.showAppBar
        ? Scaffold(
            appBar: AppBar(
              title: Text(ctxt.transaction_list_cash_flow_screen_title),
              actions: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    toggleSearch();
                  },
                  icon: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showTagFilterSheet(context);
                  },
                  icon: Icon(
                    Icons.label_rounded,
                    color: _selectedTagId != null
                        ? Theme.of(context).colorScheme.tertiary
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    showFilterBottomSheet(context, spacing);
                  },
                  icon: const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
            body: Stack(
              children: [
                _buildMainComponent(),
                ExpandableFab(
                  key: _speedDialKey,
                  visibilityController: _fabController,
                  padding: const EdgeInsets.only(bottom: 16),
                ),
              ],
            ),
          )
        : _buildMainComponent();
  }

  Widget _buildMainComponent() {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    final sectionedAsync =
        _useInfiniteScroll && _filterStartDate == null && _filterEndDate == null
            ? ref.watch(allSectionedTransactionsProvider(_filter))
            : _filterStartDate != null && _filterEndDate != null
                ? ref.watch(
                    sectionedTransactionsByDateRangeProvider(
                      (
                        start: _filterStartDate!,
                        end: _filterEndDate!,
                        type: _filter,
                      ),
                    ),
                  )
                : ref.watch(
                    sectionedTransactionsProvider(
                      (
                        month: _selectedDate,
                        type: _filter,
                      ),
                    ),
                  );

    return Column(
      children: [
        // ── Search bar ──
        if (_showSearch)
          _buildSearchBar(
            color,
            textTheme,
            spacing,
          ),

        // ── Active filter chips ──
        if (_selectedCategoryId != null || _filterStartDate != null || _selectedTagId != null)
          _buildFilterChips(
            color,
            textTheme,
            spacing,
          ),

        // ── Date header / calendar ──
        _buildDateHeader(
          color,
          textTheme,
          spacing,
        ),

        // ── Transaction list ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              _invalidateTransactionProviders();
            }),
            child: sectionedAsync.when(
              data: (sectioned) => _buildTransactionList(
                sectioned,
                color,
                textTheme,
                ctxt,
                spacing,
              ),
              loading: () => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, __) => const TransactionCardSkeleton(),
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(child: Text(BuddyMessages.errorWith('$e'))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _invalidateTransactionProviders() {
    _clearCache();
    ref.invalidate(allSectionedTransactionsProvider(_filter));
    ref.invalidate(sectionedTransactionsProvider);
    ref.invalidate(sectionedTransactionsByDateRangeProvider);
    ref.invalidate(transactionProvider);
    ref.invalidate(accountServiceProvider);
  }

  // ── SEARCH BAR ──
  Widget _buildSearchBar(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Material(
        elevation: 0,
        color: color.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: TextField(
          autofocus: true,
          onChanged: (value) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _clearCache();
                });
              }
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
                        _clearCache();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: color.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
          ),
        ),
      ),
    );
  }

  // ── FILTER CHIPS ──
  Widget _buildFilterChips(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Wrap(
        spacing: spacing.elementGap,
        runSpacing: spacing.elementGap,
        children: [
          if (_selectedCategoryId != null)
            Chip(
              avatar:
                  Icon(Icons.category_rounded, size: 18, color: color.primary),
              label: Text('Category', style: textTheme.labelMedium),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: color.primaryContainer,
              side: BorderSide.none,
              onDeleted: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _selectedCategoryId = null;
                  _clearCache();
                });
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
                  _clearCache();
                });
              },
            ),
          if (_selectedTagId != null)
            Chip(
              avatar: Icon(Icons.label_rounded, size: 18, color: color.tertiary),
              label: Text(_selectedTagName ?? 'Tag', style: textTheme.labelMedium),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: color.tertiaryContainer,
              side: BorderSide.none,
              onDeleted: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _selectedTagId = null;
                  _selectedTagName = null;
                  _clearCache();
                });
              },
            ),
        ],
      ),
    );
  }

  // ── DATE HEADER ──
  Widget _buildDateHeader(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (_useInfiniteScroll && _filterStartDate == null) {
                  setState(() {
                    _useInfiniteScroll = false;
                    _displayLimit = 50;
                    _clearCache();
                  });
                } else {
                  setState(() {
                    _showCalendar = !_showCalendar;
                    _showMonthPicker = false;
                  });
                }
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(spacing.elementGap),
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
                        SizedBox(width: spacing.sectionGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _useInfiniteScroll && _filterStartDate == null
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
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: color.primary),
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
                        _buildDateControls(
                          color,
                          spacing,
                        ),
                        SizedBox(width: spacing.elementGap),
                        if (!_useInfiniteScroll || _filterStartDate != null)
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
                        padding: EdgeInsets.only(top: spacing.radiusMedium),
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
                              icon: Icon(Icons.date_range_rounded, size: 16),
                            ),
                          ],
                          selected: {_rangeSelectionMode},
                          onSelectionChanged: (newSelection) {
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
            _buildMonthPicker(
              color,
              textTheme,
              spacing,
            ),
          if (_showCalendar)
            _buildCalendar(
              color,
              textTheme,
              spacing,
            ),
        ],
      ),
    );
  }

  // ── DATE CONTROLS (prev/next/toggle) ──
  Widget _buildDateControls(ColorScheme color, AppSpacing spacing) {
    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_useInfiniteScroll || _filterStartDate != null) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              tooltip: 'Previous Month',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                  );
                  _focusedDay = _selectedDate;
                  _clearCache();
                });
              },
            ),
            if (!isSameMonth(_selectedDate, DateTime.now()))
              IconButton(
                icon:
                    Icon(Icons.refresh_rounded, size: 20, color: color.primary),
                tooltip: 'Reset to Current Month',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _selectedDate = DateTime.now();
                    _focusedDay = DateTime.now();
                    _clearCache();
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
                  setState(() => _showMonthPicker = !_showMonthPicker);
                },
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              tooltip: 'Next Month',
              onPressed: isSameMonth(_selectedDate, DateTime.now())
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                        );
                        _focusedDay = _selectedDate;
                        _clearCache();
                      });
                    },
            ),
          ],
          IconButton(
            icon: Icon(
              _useInfiniteScroll && _filterStartDate == null
                  ? Icons.view_list_rounded
                  : Icons.all_inclusive_rounded,
              size: 20,
              color: color.primary,
            ),
            tooltip: _useInfiniteScroll ? 'Month View' : 'All Transactions',
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _useInfiniteScroll = !_useInfiniteScroll;
                _displayLimit = 50;
                _clearCache();
              });
            },
          ),
        ],
      ),
    );
  }

  // ── MONTH PICKER ──
  Widget _buildMonthPicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: spacing.cardInner,
                  mainAxisSpacing: spacing.cardInner,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthDate = DateTime(_selectedDate.year, month, 1);
                  final isSelected = _selectedDate.month == month;
                  final isFuture = monthDate.isAfter(DateTime.now());
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isFuture
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedDate =
                                    DateTime(_selectedDate.year, month, 1);
                                _focusedDay = _selectedDate;
                                _showMonthPicker = false;
                                _clearCache();
                              });
                            },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.primaryContainer
                              : color.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          border: Border.all(
                            color:
                                isSelected ? color.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat.MMM().format(DateTime(2000, month)),
                          style: textTheme.titleSmall?.copyWith(
                            color: isFuture
                                ? color.onSurface.withValues(alpha: 0.3)
                                : isSelected
                                    ? color.primary
                                    : color.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: spacing.sectionGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
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
                      onPressed: _selectedDate.year >= DateTime.now().year
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
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      label: Text('${_selectedDate.year + 1}'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _selectedDate.year >= DateTime.now().year
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
    );
  }

  // ── CALENDAR ──
  Widget _buildCalendar(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
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
          if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedDate = DateTime(selectedDay.year, selectedDay.month, 1);
              _focusedDay = focusedDay;
              _showCalendar = false;
              _clearCache();
            });
          }
        },
        onRangeSelected: (start, end, focusedDay) {
          HapticFeedback.mediumImpact();
          setState(() {
            _filterStartDate = start;
            _filterEndDate = end;
            _focusedDay = focusedDay;
            _clearCache();
            if (start != null && end != null) _showCalendar = false;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
            if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
              _selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
              _clearCache();
            }
          });
          if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {}
        },
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
          rangeStartDecoration: BoxDecoration(
            color: color.primary,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: color.primary,
            shape: BoxShape.circle,
          ),
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
    );
  }

  // ── TRANSACTION LIST ──
  Widget _buildTransactionList(
    List<TxListEntry> sectioned,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    final filtered = _filterTransactions(sectioned);

    if (filtered.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: NoDataFound(
              message: _searchQuery.isNotEmpty ||
                      _selectedCategoryId != null ||
                      _filterStartDate != null
                  ? BuddyMessages.noFilterResults('filter')
                  : BuddyMessages.noTransactions,
              iconData: Icons.receipt_long_outlined,
            ),
          ),
        ],
      );
    }

    final displayItems = filtered.take(_displayLimit).toList();
    final hasMore = filtered.length > _displayLimit;

    final transactionIds =
        displayItems.whereType<TxItem>().map((e) => e.txn.id).toList();

    // Cache trip names future — only re-fetch when IDs change
    if (_lastTxIds == null ||
        _lastTxIds!.length != transactionIds.length ||
        !_listEquals(_lastTxIds!, transactionIds)) {
      _lastTxIds = List.of(transactionIds);
      _tripNamesFuture = ref
          .read(tripServiceProvider)
          .getTripNamesByTransactionIds(transactionIds);
    }

    return FutureBuilder<Map<int, String>>(
      future: _tripNamesFuture,
      builder: (context, tripNamesSnapshot) {
        final tripNames = tripNamesSnapshot.data ?? {};
        bool peekShown = false;

        return ListView.builder(
          key: const PageStorageKey('transactionList'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                16,
          ),
          itemCount: displayItems.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayItems.length) {
              return Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final entry = displayItems[index];
            if (entry is TxHeader) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: spacing.cardVertical,
                  horizontal: spacing.cardHorizontal,
                ),
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
            final tags = transaction.tags.toList();
            final isRecurring =
                transaction.recurringTransactionSource.value != null;
            final tripName = tripNames[transaction.id];
            final isFirstTransaction = !peekShown && entry is TxItem;
            if (isFirstTransaction) peekShown = true;
            final int firstTxIndex =
                displayItems.indexWhere((e) => e is TxItem);

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
              tripName: isRecurring ? null : tripName,
              isRecurring: isRecurring,
              onEdit: () => _onEditTransaction(transaction),
              onRemove: () => _onRemoveTransaction(transaction, ctxt),
              enablePeek: index == firstTxIndex && widget.isTabActive,
            );
          },
        );
      },
    );
  }

  // ── EDIT HANDLER ──
  Future<void> _onEditTransaction(transaction) async {
    final bool? result;
    if (transaction.isTransfer) {
      // Await all nested Isar link loads before navigating
      await transaction.related.load();
      await transaction.account.load();
      final relatedTx = transaction.related.value;
      if (relatedTx != null) {
        await relatedTx.account.load();
      }
      result = await context.push(
        AppRoutes.transfer,
        extra: {
          'amount': transaction.amount.toStringAsFixed(2),
          'note': transaction.description,
          'date': transaction.date,
          'fromAccount': relatedTx?.account.value,
          'toAccount': transaction.account.value,
          'fromId': relatedTx?.id,
          'toId': transaction.id,
        },
      );
    } else {
      result = await context.push(
        AppRoutes.addTransaction,
        extra: {'transaction': transaction},
      );
    }
    if (result == true && mounted) {
      _invalidateTransactionProviders();
      setState(() {});
    }
  }

  // ── DELETE HANDLER ──
  Future<void> _onRemoveTransaction(transaction, AppLocalizations ctxt) async {
    final confirm = await DialogUtils.showDeleteConfirmation(
      context,
      title: BuddyMessages.deleteTitle,
      message: BuddyMessages.deleteMessage(null),
      cancelText: BuddyMessages.deleteCancel,
      deleteText: BuddyMessages.deleteConfirm,
    );

    if (confirm != true) return;

    await ref
        .read(tripServiceProvider)
        .removeTransactionFromTrip(transaction.id);

    if (transaction.isTransfer) {
      await transaction.related.load();
      final relatedId = transaction.related.value?.id;
      if (relatedId != null) {
        await ref.read(transactionProvider).deleteTransaction(relatedId);
      }
    }

    await ref.read(transactionProvider).deleteTransaction(transaction.id);
    _invalidateTransactionProviders();
    setState(() => _clearCache());

    if (context.mounted) {
      SnackbarService.success(BuddyMessages.txnDeleted);
    }
  }

  // ── FILTER LOGIC ──
  List<TxListEntry> _filterTransactions(List<TxListEntry> sectioned) {
    final filterKey = '$_searchQuery|$_selectedCategoryId|$_selectedTagId';
    if (_cachedFiltered != null && _lastFilterKey == filterKey) {
      return _cachedFiltered!;
    }

    if (_searchQuery.isEmpty && _selectedCategoryId == null && _selectedTagId == null) {
      _cachedFiltered = sectioned;
      _lastFilterKey = filterKey;
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
        matches = desc.contains(_searchQuery);
      }

      if (matches && _selectedCategoryId != null) {
        matches = tx.category.value?.id == _selectedCategoryId;
      }

      if (matches && _selectedTagId != null) {
        matches = tx.tags.any((t) => t.id == _selectedTagId);
      }

      if (matches && currentDate != null) {
        // Only add header if it's a new date group
        final lastHeader =
            filtered.isEmpty ? null : filtered.whereType<TxHeader>().lastOrNull;
        if (lastHeader == null ||
            lastHeader.group.year != currentDate.year ||
            lastHeader.group.month != currentDate.month ||
            lastHeader.group.day != currentDate.day) {
          filtered.add(TxHeader(currentDate));
        }
        filtered.add(txItem);
      }
    }

    _cachedFiltered = filtered;
    _lastFilterKey = filterKey;
    return filtered;
  }

  // ── LIST EQUALITY CHECK ──
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── FILTER BOTTOM SHEET ──
  void _showTagFilterSheet(BuildContext context) {
    final tagsAsync = ref.read(tagListProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return switch (tagsAsync) {
          AsyncData(:final value) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Tag',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No tags yet. Add tags to your transactions first.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_selectedTagId != null)
                          ActionChip(
                            label: const Text('Clear'),
                            avatar: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedTagId = null;
                                _selectedTagName = null;
                                _clearCache();
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        ...value.map((tag) {
                          final isSelected = _selectedTagId == tag.id;
                          return FilterChip(
                            label: Text(tag.name),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedTagId = tag.id;
                                _selectedTagName = tag.name;
                                _clearCache();
                              });
                              Navigator.pop(ctx);
                            },
                            showCheckmark: true,
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
        };
      },
    );
  }

  void showFilterBottomSheet(BuildContext context, AppSpacing spacing) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isar = await ref.read(isarServiceProvider).getInstance();
    final allCategories = await isar.categorys.where().findAll();
    for (final cat in allCategories) {
      await cat.parentCategory.load();
    }
    final parentCategories =
        allCategories.where((c) => c.parentCategory.value == null).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusMedium)),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
                          ),
                          child: Text(
                            'Transaction Type',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Transaction type filters
                        for (final entry in {
                          'all': ctxt.transaction_list_filter_all,
                          'income': ctxt.transaction_list_filter_income,
                          'expense': ctxt.transaction_list_filter_expense,
                        }.entries)
                          RadioListTile<String>(
                            value: entry.key,
                            groupValue: _filter,
                            title: Text(entry.value.toUpperCase()),
                            onChanged: (value) {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _filter = value!;
                                _clearCache();
                              });

                              setModalState(() {});
                            },
                          ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
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
                            setState(() {
                              _selectedCategoryId = null;
                              _clearCache();
                            });
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
                                    SizedBox(width: spacing.elementGap),
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
                                  setState(() {
                                    _selectedCategoryId = value;
                                    _clearCache();
                                  });
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
                                          SizedBox(width: spacing.elementGap),
                                          Text(
                                            sub.name,
                                            style: textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      onChanged: (value) {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          _selectedCategoryId = value;
                                          _clearCache();
                                        });
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
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
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
                              initialDateRange: _filterStartDate != null &&
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
                                _clearCache();
                              });
                              setModalState(() {});
                            }
                          },
                        ),
                        if (_filterStartDate != null)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: spacing.cardHorizontal),
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _filterStartDate = null;
                                  _filterEndDate = null;
                                  _clearCache();
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
                    padding: EdgeInsets.all(spacing.cardInner),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                        ),
                      ),
                      child: const Text('APPLY FILTERS'),
                    ),
                  ),
                  SizedBox(width: spacing.sectionGap),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
