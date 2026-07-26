import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';


/// Emits a tick whenever the transactions collection changes.
/// Uses debouncing to prevent excessive rebuilds on rapid changes.
final transactionChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final source = isar.transactions.watchLazy(fireImmediately: true);
  
  Timer? debounceTimer;
  DateTime? lastEmission;
  bool pendingYield = false;
  
  await for (final _ in source) {
    final now = DateTime.now();
    
    if (pendingYield) {
      pendingYield = false;
      lastEmission = now;
      yield null;
      continue;
    }
    
    if (lastEmission == null || now.difference(lastEmission).inMilliseconds > 100) {
      lastEmission = now;
      yield null;
    } else if (debounceTimer == null || !debounceTimer.isActive) {
      pendingYield = true;
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        // pendingYield=true causes yield on next loop iteration
      });
    }
  }
});


/// Emits a tick whenever the accounts collection changes.
final accountChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.accounts.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the categories collection changes.
final categoryChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.categorys.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the goals collection changes.
final goalChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.goals.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the trips collection changes.
final tripChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.trips.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the tags collection changes.
final tagChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.tags.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the budgets collection changes.
final budgetChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.budgets.watchLazy(fireImmediately: true);
});

/// Emits a tick whenever the pending transactions collection changes.
final pendingTransactionChangeProvider = StreamProvider<void>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  yield* isar.pendingTransactions.watchLazy(fireImmediately: true);
});