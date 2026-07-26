import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/debt.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:mudra_manager/features/debt_snowball/data/debt_snowball_service.dart';
import 'package:mudra_manager/features/debt_snowball/domain/debt_models.dart';

final debtSnowballServiceProvider = Provider<DebtSnowballService>((ref) {
  return const DebtSnowballService();
});

final debtServiceProvider = Provider<DebtService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return DebtService(isarService);
});

/// All debts (active + archived), live-updating.
final debtsProvider = StreamProvider.autoDispose<List<Debt>>((ref) {
  final service = ref.watch(debtServiceProvider);
  return service.watchAll();
});

/// User's chosen payoff strategy (Snowball vs Avalanche). Kept in memory —
/// this is a display preference, not persisted data.
final debtSortOrderProvider =
    NotifierProvider<StateValue<DebtSortOrder>, DebtSortOrder>(
  () => StateValue(DebtSortOrder.balanceAscending),
);

/// Computed payoff schedule for the active debts, using the selected
/// strategy. Recomputes whenever debts or strategy change.
final debtSnowballResultProvider = Provider.autoDispose<SnowballResult>((ref) {
  final debtsAsync = ref.watch(debtsProvider);
  final order = ref.watch(debtSortOrderProvider);
  final service = ref.watch(debtSnowballServiceProvider);

  final debts = debtsAsync.value ?? const <Debt>[];
  final active = debts.where((d) => d.isActive).toList();

  return service.calculatePayoff(debts: active, order: order);
});

class DebtService {
  final IsarService isarService;

  DebtService(this.isarService);

  Future<void> addDebt(Debt debt) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.debts.put(debt);
    });
  }

  Future<void> updateDebt(Debt debt) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.debts.put(debt);
    });
  }

  Future<void> deleteDebt(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.debts.delete(id);
    });
  }

  Future<void> setActive(int id, bool isActive) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final debt = await isar.debts.get(id);
      if (debt != null) {
        debt.isActive = isActive;
        await isar.debts.put(debt);
      }
    });
  }

  Stream<List<Debt>> watchAll() async* {
    final isar = await isarService.getInstance();
    yield* isar.debts.where().watch(fireImmediately: true);
  }
}
