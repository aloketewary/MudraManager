import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/date_change_provider.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

/// Why budget-dependent data must be read again.
enum BudgetRefreshReason {
  dateBoundary,
  appResumed,
  manual,
  navigation,
  retry,
  budgetCrud,
  transactionChanged,
  categoryChanged,
  tagChanged,
}

/// One coherent budget read generation.
///
/// Consumers must use [evaluationDate] for every calculation and discard a
/// result if its [generation] is no longer current.
class BudgetRefreshState {
  final int generation;
  final DateTime evaluationDate;
  final BudgetRefreshReason reason;

  const BudgetRefreshState({
    required this.generation,
    required this.evaluationDate,
    required this.reason,
  });
}

final budgetRefreshProvider =
    NotifierProvider<BudgetRefreshNotifier, BudgetRefreshState>(
  BudgetRefreshNotifier.new,
);

class BudgetRefreshNotifier extends Notifier<BudgetRefreshState>
    with WidgetsBindingObserver {
  Timer? _queuedRefresh;
  BudgetRefreshReason? _queuedReason;
  DateTime? _queuedDate;
  BudgetRefreshReason? _lastPublishedReason;
  DateTime? _lastPublishedAt;

  @override
  BudgetRefreshState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _queuedRefresh?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    ref.listen<AsyncValue<DateTime>>(dateChangeProvider, (_, next) {
      if (next.hasValue) _queue(BudgetRefreshReason.dateBoundary, next.value);
    });
    ref.listen<AsyncValue<void>>(transactionChangeProvider, (_, next) {
      if (next.hasValue) _queue(BudgetRefreshReason.transactionChanged, null);
    });
    ref.listen<AsyncValue<void>>(budgetChangeProvider, (_, next) {
      if (next.hasValue) _queue(BudgetRefreshReason.budgetCrud, null);
    });
    ref.listen<AsyncValue<void>>(categoryChangeProvider, (_, next) {
      if (next.hasValue) _queue(BudgetRefreshReason.categoryChanged, null);
    });
    ref.listen<AsyncValue<void>>(tagChangeProvider, (_, next) {
      if (next.hasValue) _queue(BudgetRefreshReason.tagChanged, null);
    });

    return BudgetRefreshState(
      generation: 0,
      evaluationDate: _day(DateTime.now()),
      reason: BudgetRefreshReason.navigation,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh(BudgetRefreshReason.appResumed);
    }
  }

  /// Publish one refresh immediately. Call only after successful persistence.
  void refresh(
    BudgetRefreshReason reason, {
    DateTime? evaluationDate,
  }) {
    _queuedRefresh?.cancel();
    _queuedRefresh = null;
    _queuedReason = null;
    _queuedDate = null;

    _lastPublishedReason = reason;
    _lastPublishedAt = DateTime.now();
    state = BudgetRefreshState(
      generation: state.generation + 1,
      evaluationDate: _day(evaluationDate ?? DateTime.now()),
      reason: reason,
    );
  }

  void _queue(BudgetRefreshReason reason, DateTime? evaluationDate) {
    final now = DateTime.now();
    final lastPublishedAt = _lastPublishedAt;
    if (_lastPublishedReason == reason &&
        lastPublishedAt != null &&
        now.difference(lastPublishedAt) < const Duration(milliseconds: 200)) {
      return;
    }

    _queuedReason = reason;
    _queuedDate = evaluationDate ?? _queuedDate;
    _queuedRefresh ??= Timer(const Duration(milliseconds: 100), () {
      final queuedReason = _queuedReason;
      if (queuedReason == null) return;
      refresh(queuedReason, evaluationDate: _queuedDate);
    });
  }

  DateTime _day(DateTime value) => DateArithmetic.startOfDay(value);
}
