import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/filter_state_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_query_provider.dart';
import 'package:mudra_manager/features/transactions/data/view_mode_provider.dart';
import 'package:mudra_manager/features/transactions/domain/filter_state.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/speed_dial_fab.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';

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

  // Interaction state (local to this screen)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  bool _showMonthPicker = false;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  bool _showSearch = false;
  late final ScrollController _scrollController;
  int _displayLimit = 50;
  bool _isLoadingMore = false;
  double _lastScrollOffset = 0;
  Timer? _searchDebounce;
  final Map<int, Timer> _pendingDeletes = {};

  // Multi-select for merge-as-transfer
  bool _selectMode = false;
  final Set<int> _selectedTxnIds = {};

  // Trip names caching
  List<int>? _lastTxIds;
  Future<Map<int, String>>? _tripNamesFuture;
  AnimationController? _fabController;
  final _speedDialKey = GlobalKey<ExpandableFabState>();

  // ── Bridge getters: derive old-style values from providers ──
  // These allow remaining UI methods (calendar, month picker, date controls,
  // filter sheet) to compile unchanged. The real state lives in providers.

  bool get _useInfiniteScroll => ref.read(viewModeProvider) is InfiniteView;

  DateTime get _selectedDate {
    final mode = ref.read(viewModeProvider);
    if (mode is MonthView) return DateTime(mode.year, mode.month);
    return DateTime.now();
  }

  int? get _selectedCategoryId => ref.read(filterStateProvider).categoryId;
  int? get _selectedTagId => ref.read(filterStateProvider).tagId;
// Derived from tag provider if needed
  String get _searchQuery => ref.read(filterStateProvider).searchQuery;
  String get _filter {
    final type = ref.read(filterStateProvider).type;
    switch (type) {
      case TransactionTypeFilter.all:
        return 'all';
      case TransactionTypeFilter.income:
        return 'income';
      case TransactionTypeFilter.expense:
        return 'expense';
    }
  }

  DateTime? get _filterStartDate {
    final mode = ref.read(viewModeProvider);
    if (mode is DateRangeView) return mode.start;
    return null;
  }

  DateTime? get _filterEndDate {
    final mode = ref.read(viewModeProvider);
    if (mode is DateRangeView) return mode.end;
    return null;
  }

  // ── Bridge setters: forward mutations to providers ──

  void _clearCache() {
    _clearTripCache();
  }

  // ignore: use_setters_to_change_properties
  set _selectedDate(DateTime date) {
    ref.read(viewModeProvider.notifier).setMonth(date.year, date.month);
  }

  // ignore: use_setters_to_change_properties
  set _useInfiniteScroll(bool value) {
    if (value) {
      ref.read(viewModeProvider.notifier).setInfinite();
    } else {
      final now = DateTime.now();
      ref.read(viewModeProvider.notifier).setMonth(now.year, now.month);
    }
  }

  // ignore: use_setters_to_change_properties
  set _selectedCategoryId(int? value) {
    ref.read(filterStateProvider.notifier).setCategory(value);
  }

  // ignore: use_setters_to_change_properties
  set _selectedTagId(int? value) {
    ref.read(filterStateProvider.notifier).setTag(value);
  }

  // ignore: use_setters_to_change_properties
  set _selectedTagName(String? _) {} // Display state derived from tag provider

  // ignore: use_setters_to_change_properties
  set _filter(String value) {
    final type = switch (value) {
      'income' => TransactionTypeFilter.income,
      'expense' => TransactionTypeFilter.expense,
      _ => TransactionTypeFilter.all,
    };
    ref.read(filterStateProvider.notifier).setType(type);
  }

  // ignore: use_setters_to_change_properties
  set _filterStartDate(DateTime? value) {
    if (value != null && _filterEndDate != null) {
      ref.read(viewModeProvider.notifier).setDateRange(value, _filterEndDate!);
    } else if (value == null) {
      // Clearing date range — go back to month view
      final now = DateTime.now();
      ref.read(viewModeProvider.notifier).setMonth(now.year, now.month);
    }
  }

  // ignore: use_setters_to_change_properties
  set _filterEndDate(DateTime? value) {
    if (value != null && _filterStartDate != null) {
      ref
          .read(viewModeProvider.notifier)
          .setDateRange(_filterStartDate!, value);
    }
  }

  // ignore: use_setters_to_change_properties

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
    for (final timer in _pendingDeletes.values) {
      timer.cancel();
    }
    _scrollController.dispose();
    _fabController?.dispose();
    super.dispose();
  }

  void _clearTripCache() {
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

    final mode = ref.read(viewModeProvider);
    final isViewingCurrentMonth = mode is InfiniteView ||
        (mode is MonthView &&
            mode.year == today.year &&
            mode.month == today.month);

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
      if (!_showSearch) {
        ref.read(filterStateProvider.notifier).clearSearch();
      }
    });
  }

  String _getDateRangeText() {
    final mode = ref.read(viewModeProvider);
    if (mode is DateRangeView) {
      return '${DateFormat.MMMd().format(mode.start)} - ${DateFormat.MMMd().format(mode.end)}';
    }
    if (mode is MonthView) {
      return DateFormat.yMMMM().format(DateTime(mode.year, mode.month));
    }
    return '';
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return widget.showAppBar
        ? Scaffold(
            appBar: _selectMode
                ? AppBar(
                    leading: IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectMode = false;
                          _selectedTxnIds.clear();
                        });
                      },
                      icon: const Icon(LucideIcons.x),
                    ),
                    title: Text('${_selectedTxnIds.length} selected'),
                    actions: [
                      if (_selectedTxnIds.length == 2)
                        TextButton.icon(
                          onPressed: () => _mergeAsTransfer(ctxt, spacing,),
                          icon:
                              const Icon(LucideIcons.arrowLeftRight, size: 18),
                          label: Text(ctxt.txnList_convertToTransfer),
                        ),
                    ],
                  )
                : AppBar(
                    title: Text(ctxt.transaction_list_cash_flow_screen_title),
                    actions: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          toggleSearch();
                        },
                        icon: Icon(
                          _showSearch ? LucideIcons.x : LucideIcons.search,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showTagFilterSheet(context);
                        },
                        icon: Icon(
                          LucideIcons.tag,
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
                        icon: const Icon(LucideIcons.listFilter),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _selectMode = true;
                            _selectedTxnIds.clear();
                          });
                        },
                        icon: const Icon(LucideIcons.combine),
                        tooltip: ctxt.txnList_convertToTransfer,
                      ),
                    ],
                  ),
            body: Stack(
              children: [
                _buildMainComponent(),
                if (!_selectMode)
                  ExpandableFab(
                    key: _speedDialKey,
                    visibilityController: _fabController,
                    padding: const EdgeInsets.only(bottom: 16),
                  ),
                if (_selectMode && _selectedTxnIds.isNotEmpty)
                  _buildSelectModeHint(
                    Theme.of(context).colorScheme,
                    Theme.of(context).textTheme,
                    spacing,
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
    final filters = ref.watch(filterStateProvider);
    final mode = ref.watch(viewModeProvider);

    final sectionedAsync = ref.watch(transactionQueryProvider);

    return Column(
      children: [
        // ── Search bar ──
        if (_showSearch)
          _buildSearchBar(
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

        // ── Sticky filter bar (always visible when filters active) ──
        if (filters.categoryId != null ||
            mode is DateRangeView ||
            filters.tagId != null)
          _buildStickyFilterBar(
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
    _clearTripCache();
    ref.invalidate(transactionQueryProvider);
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
                ref
                    .read(filterStateProvider.notifier)
                    .setSearch(value.toLowerCase());
              }
            });
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.txnList_searchHint,
            hintStyle: TextStyle(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              color: color.primary,
              size: 22,
            ),
            suffixIcon: ref.watch(filterStateProvider).searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(filterStateProvider.notifier).clearSearch();
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

  // ── STICKY FILTER BAR ──
  Widget _buildStickyFilterBar(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final filters = ref.watch(filterStateProvider);
    final mode = ref.watch(viewModeProvider);
    final parts = <String>[];
    if (filters.categoryId != null) parts.add(ctxt.txnList_category);
    if (mode is DateRangeView) parts.add(ctxt.txnList_dateRange);
    if (filters.tagId != null) parts.add(ctxt.txnList_tag);

    // Check if a budget exists for the selected category
    BudgetWithProgress? matchingBudget;
    if (filters.categoryId != null) {
      final budgetsAsync = ref.watch(budgetsWithProgressProvider);
      budgetsAsync.whenData((budgets) {
        for (final bwp in budgets) {
          final catIds = bwp.budget.categories.map((c) => c.id).toSet();
          if (catIds.contains(filters.categoryId)) {
            matchingBudget = bwp;
            break;
          }
        }
      });
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listFilter, size: 16, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  parts.join(' · '),
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(filterStateProvider.notifier).clearAll();
                  ref.read(viewModeProvider.notifier).setInfinite();
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    ctxt.txnList_clear,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (matchingBudget != null) ...[
            SizedBox(height: spacing.elementGapMin),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(
                  AppRoutes.budgetDetails,
                  extra: matchingBudget!.budget.id,
                );
              },
              child: Row(
                children: [
                  Icon(LucideIcons.chartPie, size: 14, color: color.primary),
                  SizedBox(width: spacing.elementGapMin),
                  Text(
                    ctxt.budget_dashboardPageTitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 12, color: color.primary),
                ],
              ),
            ),
          ],
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
                final mode = ref.read(viewModeProvider);
                if (mode is InfiniteView) {
                  final now = DateTime.now();
                  ref
                      .read(viewModeProvider.notifier)
                      .setMonth(now.year, now.month);
                  setState(() => _displayLimit = 50);
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
                            borderRadius: BorderRadius.circular(
                              spacing.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.calendar,
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
                                ref.watch(viewModeProvider) is InfiniteView
                                    ? AppLocalizations.of(context)!
                                        .txnList_allTransactions
                                    : _getDateRangeText(),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.onSurface,
                                ),
                              ),
                              if (_rangeSelectionMode ==
                                  RangeSelectionMode.toggledOn)
                                Text(
                                  AppLocalizations.of(context)!
                                      .txnList_tapStartEnd,
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: color.primary),
                                )
                              else if (ref.watch(viewModeProvider)
                                  is InfiniteView)
                                Text(
                                  AppLocalizations.of(context)!
                                      .txnList_scrollToLoad,
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
                        if (ref.watch(viewModeProvider) is! InfiniteView)
                          Icon(
                            _showCalendar || _showMonthPicker
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            color: color.onSurfaceVariant,
                          ),
                      ],
                    ),
                    if (_showCalendar || _showMonthPicker)
                      Padding(
                        padding: EdgeInsets.only(top: spacing.radiusMedium),
                        child: SegmentedButton<RangeSelectionMode>(
                          segments: [
                            ButtonSegment(
                              value: RangeSelectionMode.toggledOff,
                              label: Text(
                                AppLocalizations.of(context)!.txnList_month,
                              ),
                              icon: const Icon(
                                LucideIcons.calendarDays,
                                size: 16,
                              ),
                            ),
                            ButtonSegment(
                              value: RangeSelectionMode.toggledOn,
                              label: Text(
                                AppLocalizations.of(context)!.txnList_dateRange,
                              ),
                              icon: const Icon(
                                LucideIcons.calendarRange,
                                size: 16,
                              ),
                            ),
                          ],
                          selected: {_rangeSelectionMode},
                          onSelectionChanged: (newSelection) {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _rangeSelectionMode = newSelection.first;
                              if (_rangeSelectionMode ==
                                  RangeSelectionMode.toggledOff) {
                                // Switch back to month view
                                final now = DateTime.now();
                                ref
                                    .read(viewModeProvider.notifier)
                                    .setMonth(now.year, now.month);
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
              icon: const Icon(LucideIcons.chevronLeft, size: 22),
              tooltip: AppLocalizations.of(context)!.txnList_previousMonth,
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
                    Icon(LucideIcons.refreshCw, size: 20, color: color.primary),
                tooltip:
                    AppLocalizations.of(context)!.txnList_resetToCurrentMonth,
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
                  LucideIcons.calendar,
                  size: 20,
                  color: color.primary,
                ),
                tooltip: AppLocalizations.of(context)!.txnList_selectMonth,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _showMonthPicker = !_showMonthPicker);
                },
              ),
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 22),
              tooltip: AppLocalizations.of(context)!.txnList_nextMonth,
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
                  ? LucideIcons.list
                  : LucideIcons.infinity,
              size: 20,
              color: color.primary,
            ),
            tooltip: _useInfiniteScroll
                ? AppLocalizations.of(context)!.txnList_monthView
                : AppLocalizations.of(context)!.txnList_allTransactions,
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
                      icon: const Icon(LucideIcons.chevronLeft, size: 18),
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
                      icon: const Icon(LucideIcons.chevronRight, size: 18),
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
    final filtered = sectioned;

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
              iconData: LucideIcons.receipt,
            ),
          ),
        ],
      );
    }

    // Hide pending delete from UI
    final visible = _pendingDeletes.isNotEmpty
        ? filtered.where((e) {
            if (e is! TxItem) return true;
            return !_pendingDeletes.containsKey(e.txn.id);
          }).toList()
        : filtered;

    final displayItems = visible.take(_displayLimit).toList();
    final hasMore = visible.length > _displayLimit;

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
                child: const TransactionCardSkeleton(),
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
            final isFirstTransaction = !peekShown;
            if (isFirstTransaction) peekShown = true;
            final int firstTxIndex =
                displayItems.indexWhere((e) => e is TxItem);

            return _selectMode
                ? _buildSelectableCard(
                    transaction,
                    tags,
                    isRecurring,
                    tripName,
                    ctxt,
                    color,
                    spacing,
                  )
                : TransactionCard(
                    category: transaction.category.value,
                    description: transaction.description,
                    account: transaction.account.value,
                    amount: transaction.amount.toStringAsFixed(2),
                    currencyCode: transaction.currencyCode,
                    convertedAmount: transaction.convertedAmount,
                    date: transaction.date,
                    isExpense: transaction.isExpense,
                    isTransfer: transaction.isTransfer,
                    tags: tags,
                    related: transaction.related.value,
                    tripName: tripName,
                    isRecurring: isRecurring,
                    onEdit: () => _onEditTransaction(transaction, spacing,),
                    onRemove: () => _onRemoveTransaction(transaction, ctxt, spacing,),
                    onUnlinkRecurring: isRecurring
                        ? () => _onUnlinkRecurring(transaction, spacing,)
                        : null,
                    enablePeek: index == firstTxIndex && widget.isTabActive,
                  );
          },
        );
      },
    );
  }

  // ── SELECT MODE HINT BAR ──
  Widget _buildSelectModeHint(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final hint = _selectedTxnIds.length == 1
        ? 'Select the matching transaction'
        : 'Tap merge in the app bar';

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom +
          kBottomNavigationBarHeight +
          8,
      left: spacing.cardHorizontal,
      right: spacing.cardHorizontal,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical + 2,
        ),
        decoration: BoxDecoration(
          color: color.primaryContainer,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.arrowLeftRight, size: 18, color: color.primary),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                hint,
                style: textTheme.labelLarge?.copyWith(
                  color: color.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_selectedTxnIds.length}/2',
              style: textTheme.labelLarge?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SELECTABLE CARD (merge-as-transfer mode) ──
  Widget _buildSelectableCard(
    Transaction transaction,
    List<Tag> tags,
    bool isRecurring,
    String? tripName,
    AppLocalizations ctxt,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    final isSelected = _selectedTxnIds.contains(transaction.id);
    final canSelect =
        !transaction.isTransfer && (_selectedTxnIds.length < 2 || isSelected);

    return GestureDetector(
      onTap: () {
        if (!canSelect && !isSelected) return;
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedTxnIds.remove(transaction.id);
          } else {
            _selectedTxnIds.add(transaction.id);
          }
        });
      },
      child: Stack(
        children: [
          Opacity(
            opacity: canSelect || isSelected ? 1.0 : 0.4,
            child: TransactionCard(
              category: transaction.category.value,
              description: transaction.description,
              account: transaction.account.value,
              amount: transaction.amount.toStringAsFixed(2),
              currencyCode: transaction.currencyCode,
              convertedAmount: transaction.convertedAmount,
              date: transaction.date,
              isExpense: transaction.isExpense,
              isTransfer: transaction.isTransfer,
              tags: tags,
              related: transaction.related.value,
              tripName: tripName,
              isRecurring: isRecurring,
              onEdit: () {},
              onRemove: () {},
              enablePeek: false,
            ),
          ),
          if (isSelected)
            Positioned(
              top: spacing.cardVertical + 4,
              right: spacing.cardHorizontal + 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(LucideIcons.check, size: 16, color: color.onPrimary),
              ),
            ),
        ],
      ),
    );
  }

  // ── MERGE AS TRANSFER ──
  Future<void> _mergeAsTransfer(AppLocalizations ctxt, AppSpacing spacing) async {
    if (_selectedTxnIds.length != 2) return;

    final isar = await ref.read(isarServiceProvider).getInstance();
    final txns = <Transaction>[];
    for (final id in _selectedTxnIds) {
      final t = await isar.transactions.get(id);
      if (t != null) {
        t.account.loadSync();
        txns.add(t);
      }
    }

    if (txns.length != 2) {
      SnackbarService.error(BuddyMessages.genericError, spacing,);
      return;
    }

    // Validate: one expense, one income
    final expense = txns.where((t) => t.isExpense).firstOrNull;
    final income = txns.where((t) => !t.isExpense).firstOrNull;
    if (expense == null || income == null) {
      SnackbarService.error('Select one expense and one income transaction', spacing,);
      return;
    }

    // Validate: same amount (±1% tolerance)
    if ((expense.amount - income.amount).abs() > expense.amount * 0.01) {
      SnackbarService.error('Amounts must match (within 1%)', spacing,);
      return;
    }

    // Validate: within 24 hours
    if (expense.date.difference(income.date).inHours.abs() > 24) {
      SnackbarService.error('Transactions must be within 24 hours', spacing,);
      return;
    }

    final fromAccount = expense.account.value;
    final toAccount = income.account.value;

    // Validate: different accounts
    if (fromAccount?.id == toAccount?.id) {
      SnackbarService.error('Cannot transfer between the same account', spacing,);
      return;
    }

    if (!context.mounted) return;
    final result = await context.push<bool>(
      AppRoutes.transfer,
      extra: {
        'amount': expense.amount.toStringAsFixed(2),
        'note': expense.description ?? income.description,
        'date': expense.date,
        'fromAccount': fromAccount,
        'toAccount': toAccount,
      },
    );

    if (result == true) {
      // Delete both original transactions atomically
      await ref
          .read(transactionProvider)
          .deleteTransactionPair(expense.id, income.id);
      _invalidateTransactionProviders();

      setState(() {
        _selectMode = false;
        _selectedTxnIds.clear();
        _clearCache();
      });

      if (context.mounted) {
        SnackbarService.success(ctxt.txnList_convertedToTransfer, spacing,);
      }
    }
  }

  // ── EDIT HANDLER ──
  Future<void> _onEditTransaction(transaction, AppSpacing spacing,) async {
    final bool? result;
    if (transaction.isTransfer) {
      await transaction.related.load();
      await transaction.account.load();
      final relatedTx = transaction.related.value;
      if (relatedTx == null) {
        if (context.mounted) {
          SnackbarService.error(BuddyMessages.genericError, spacing);
        }
        return;
      }
      await relatedTx.account.load();
      if (!context.mounted) return;
      result = await context.push(
        AppRoutes.transfer,
        extra: {
          'amount': transaction.amount.toStringAsFixed(2),
          'note': transaction.description,
          'date': transaction.date,
          'fromAccount': relatedTx.account.value,
          'toAccount': transaction.account.value,
          'fromId': relatedTx.id,
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
  Future<void> _onUnlinkRecurring(Transaction transaction, AppSpacing spacing,) async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    await isar.writeTxn(() async {
      transaction.recurringTransactionSource.value = null;
      await transaction.recurringTransactionSource.save();
      await isar.transactions.put(transaction);
    });
    _invalidateTransactionProviders();
    setState(() => _clearCache());
    if (!context.mounted) return;
    SnackbarService.success(
      AppLocalizations.of(context)!.txnList_subscriptionTagRemoved,
      spacing,
    );
  }

  Future<void> _onRemoveTransaction(
      transaction, AppLocalizations ctxt, AppSpacing spacing,) async {
    final confirm = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: BuddyMessages.deleteTitle,
      message: BuddyMessages.deleteMessage(null),
      cancelText: BuddyMessages.deleteCancel,
      deleteText: BuddyMessages.deleteConfirm,
    );

    if (confirm != true) return;

    final txnId = transaction.id as int;

    // Hide from UI immediately
    setState(() => _clearCache());

    // Schedule actual delete after undo window
    bool undone = false;
    _pendingDeletes[txnId]?.cancel();
    final timer = Timer(const Duration(seconds: 6), () async {
      if (undone) return;
      _pendingDeletes.remove(txnId);
      if (!mounted) return;

      await ref.read(tripServiceProvider).removeTransactionFromTrip(txnId);

      final service = ref.read(transactionProvider);
      if (transaction.isTransfer) {
        await service.deleteTransferAtomic(txnId);
      } else {
        await service.deleteTransaction(txnId);
      }

      _invalidateTransactionProviders();
      if (mounted) setState(() => _clearCache());
    });
    _pendingDeletes[txnId] = timer;

    if (context.mounted) {
      SnackbarService.success(
        BuddyMessages.txnDeleted,
        spacing,
        actionLabel: ctxt.common_undo,
        onAction: () {
          undone = true;
          _pendingDeletes[txnId]?.cancel();
          _pendingDeletes.remove(txnId);
          if (mounted) {
            setState(() => _clearCache());
          }
        },
      );
    }
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final tagsAsync = ref.watch(tagListProvider);
            return switch (tagsAsync) {
              AsyncData(:final value) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.txnList_filterByTag,
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
                              AppLocalizations.of(context)!.txnList_noTagsYet,
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
                                label: Text(
                                  AppLocalizations.of(context)!.txnList_clear,
                                ),
                                avatar: const Icon(LucideIcons.x, size: 16),
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
              _ => Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: List.generate(
                      5,
                      (_) => const TransactionCardSkeleton(),
                    ),
                  ),
                ),
            };
          },
        );
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

    if (!context.mounted) return;

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
                      AppLocalizations.of(context)!.txnList_filterOptions,
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
                            AppLocalizations.of(context)!
                                .txnList_transactionType,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Transaction type filters
                        RadioGroup<String>(
                          groupValue: _filter,
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _filter = value!;
                              _clearCache();
                            });
                            setModalState(() {});
                          },
                          child: Column(
                            children: [
                              for (final entry in {
                                'all': ctxt.transaction_list_filter_all,
                                'income': ctxt.transaction_list_filter_income,
                                'expense': ctxt.transaction_list_filter_expense,
                              }.entries)
                                RadioListTile<String>(
                                  value: entry.key,
                                  title: Text(entry.value.toUpperCase()),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.txnList_category,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadioGroup<int?>(
                          groupValue: _selectedCategoryId,
                          onChanged: (value) {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _selectedCategoryId = value;
                              _clearCache();
                            });
                            setModalState(() {});
                          },
                          child: Column(
                            children: [
                              RadioListTile<int?>(
                                value: null,
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .txnList_allCategories,
                                ),
                              ),
                              ...parentCategories.map((parent) {
                                final subcategories = allCategories
                                    .where(
                                      (c) =>
                                          c.parentCategory.value?.id ==
                                          parent.id,
                                    )
                                    .toList();
                                final hasSubcategories =
                                    subcategories.isNotEmpty;

                                return Column(
                                  children: [
                                    RadioListTile<int?>(
                                      value: parent.id,
                                      title: Row(
                                        children: [
                                          Icon(
                                            IconHelper.getIconData(
                                              parent.iconName,
                                            ),
                                            size: 20,
                                            color: Color(
                                              parent.colorValue ?? 0xFF9E9E9E,
                                            ),
                                          ),
                                          SizedBox(width: spacing.elementGap),
                                          Expanded(child: Text(parent.name)),
                                          if (hasSubcategories)
                                            Icon(
                                              LucideIcons.chevronRight,
                                              size: 16,
                                              color: color.onSurfaceVariant,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (hasSubcategories)
                                      ...subcategories.map(
                                        (sub) => Padding(
                                          padding:
                                              const EdgeInsets.only(left: 32),
                                          child: RadioListTile<int?>(
                                            value: sub.id,
                                            title: Row(
                                              children: [
                                                Icon(
                                                  IconHelper.getIconData(
                                                    sub.iconName,
                                                  ),
                                                  size: 18,
                                                  color: Color(
                                                    sub.colorValue ??
                                                        0xFF9E9E9E,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: spacing.elementGap,
                                                ),
                                                Text(
                                                  sub.name,
                                                  style: textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.txnList_dateRange,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            LucideIcons.calendarRange,
                            color: color.primary,
                          ),
                          title: Text(
                            _filterStartDate != null && _filterEndDate != null
                                ? '${DateFormat.yMMMd().format(_filterStartDate!)} - ${DateFormat.yMMMd().format(_filterEndDate!)}'
                                : AppLocalizations.of(context)!
                                    .txnList_selectDateRange,
                          ),
                          trailing: const Icon(LucideIcons.chevronRight),
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
                              horizontal: spacing.cardHorizontal,
                            ),
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
                              icon: const Icon(LucideIcons.x),
                              label: Text(
                                AppLocalizations.of(context)!
                                    .txnList_clearDateRange,
                              ),
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
