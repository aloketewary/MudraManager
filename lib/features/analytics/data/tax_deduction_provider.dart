import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/tax_deduction_profile.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';

final taxDeductionProfileProvider =
    StreamProvider.autoDispose<TaxDeductionProfile?>((ref) async* {
  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  final fy = TaxEstimationService.currentFYStartYear();

  yield* isar.taxDeductionProfiles
      .filter()
      .financialYearEqualTo(fy)
      .watch(fireImmediately: true)
      .map((profiles) => profiles.isEmpty ? null : profiles.first);
});

final taxDeductionServiceProvider =
    Provider.autoDispose<TaxDeductionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TaxDeductionService(isarService);
});

class TaxDeductionService {
  final IsarService _isarService;

  TaxDeductionService(this._isarService);

  Future<TaxDeductionProfile?> getForFY(int fy) async {
    final isar = await _isarService.getInstance();
    return isar.taxDeductionProfiles
        .filter()
        .financialYearEqualTo(fy)
        .findFirst();
  }

  Future<void> save(TaxDeductionProfile profile) async {
    final isar = await _isarService.getInstance();
    profile.updatedAt = DateTime.now();
    await isar.writeTxn(() => isar.taxDeductionProfiles.put(profile));
  }
}
