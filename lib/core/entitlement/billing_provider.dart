import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/entitlement/billing_service.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final billing = BillingService(ref.watch(entitlementServiceProvider));
  ref.onDispose(() => billing.dispose());
  return billing;
});

/// Initializes billing and resolves when products are loaded.
final billingReadyProvider = FutureProvider<void>((ref) async {
  final billing = ref.watch(billingServiceProvider);
  await billing.initialize();
});
