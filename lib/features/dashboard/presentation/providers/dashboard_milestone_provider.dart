import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';

/// Side-effect controller for dashboard milestones (streaks, SMS celebration, reconciliation patching).
final dashboardMilestoneController = Provider.autoDispose((ref) {
  return DashboardMilestoneController(ref);
});

class DashboardMilestoneController {
  final Ref _ref;
  DashboardMilestoneController(this._ref);

  void onAppOpened() {
    _patchReconciliation();
    _checkDailyCheckIn();
  }

  void _patchReconciliation() {
    _ref.read(reconciliationServiceProvider).patchUncategorizedTransactions();
  }

  Future<void> _checkDailyCheckIn() async {
    await NotificationService.cancelStreakReminder();
    // Logic remains mostly in UI for now as it needs context for bottom sheets,
    // but the trigger and non-UI logic could live here.
  }
}
