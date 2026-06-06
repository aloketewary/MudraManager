import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_assembler.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_state.dart';

const _assembler = GroupDetailAssembler();

/// Single provider that produces the fully-hydrated read model for a group.
/// UI consumes this — never raw Isar models.
final groupDetailProvider = FutureProvider.autoDispose
    .family<GroupDetailState?, int>((ref, groupId) async {
  final service = ref.watch(tripServiceProvider);

  // Load group with all links pre-resolved
  final group = await service.getTripById(groupId);
  if (group == null) return null;

  final participants = group.participants.toList();
  final transactions = group.transactions.toList();

  // Calculate pending settlements (reuses existing engine)
  final pendingSettlements = await service.calculateSettlements(groupId);

  return _assembler.build(
    group: group,
    transactions: transactions,
    participants: participants,
    pendingSettlements: pendingSettlements,
  );
});
