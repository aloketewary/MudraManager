import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';

/// Manages which dataset the transaction list is currently viewing.
///
/// This is query state — it determines what data is fetched.
/// Interaction state (displayLimit, selection) lives elsewhere.
class ViewModeNotifier extends Notifier<TransactionViewMode> {
  @override
  TransactionViewMode build() => const InfiniteView();

  void setInfinite() => state = const InfiniteView();

  void setMonth(int year, int month) => state = MonthView(year, month);

  void setDateRange(DateTime start, DateTime end) =>
      state = DateRangeView(start, end);

  void previousMonth() {
    if (state case MonthView(:final year, :final month)) {
      final prev =
          month == 1 ? MonthView(year - 1, 12) : MonthView(year, month - 1);
      state = prev;
    }
  }

  void nextMonth() {
    if (state case MonthView(:final year, :final month)) {
      final next =
          month == 12 ? MonthView(year + 1, 1) : MonthView(year, month + 1);
      state = next;
    }
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    state = MonthView(now.year, now.month);
  }
}

final viewModeProvider =
    NotifierProvider<ViewModeNotifier, TransactionViewMode>(
  ViewModeNotifier.new,
);
