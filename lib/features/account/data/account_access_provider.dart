import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

/// Whether a specific account is unlocked for full use (add transactions).
/// Locked accounts can still be viewed (balance, history).
final isAccountUnlockedProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, accountId) async {
  final hasAccess = await ref.watch(hasFullAccessProvider.future);
  if (hasAccess) return true;

  final accounts = await ref.watch(accountsProvider.future);
  // Sorted by ID = creation order. Oldest N are unlocked.
  final sorted = List<Account>.from(accounts)..sort((a, b) => a.id.compareTo(b.id));
  final unlocked = sorted.take(FreeTierLimits.maxAccounts).map((a) => a.id).toSet();
  return unlocked.contains(accountId);
});

/// Returns the set of unlocked account IDs.
final unlockedAccountIdsProvider =
    FutureProvider.autoDispose<Set<int>>((ref) async {
  final hasAccess = await ref.watch(hasFullAccessProvider.future);
  final accounts = await ref.watch(accountsProvider.future);

  if (hasAccess) return accounts.map((a) => a.id).toSet();

  final sorted = List<Account>.from(accounts)..sort((a, b) => a.id.compareTo(b.id));
  return sorted.take(FreeTierLimits.maxAccounts).map((a) => a.id).toSet();
});

/// How many extra accounts would be unlocked with Pro.
final lockedAccountCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final hasAccess = await ref.watch(hasFullAccessProvider.future);
  if (hasAccess) return 0;

  final accounts = await ref.watch(accountsProvider.future);
  return (accounts.length - FreeTierLimits.maxAccounts).clamp(0, 999);
});
