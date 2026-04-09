import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(isarServiceProvider));
});

/// Whether the user currently has Pro.
/// Widgets watch this to reactively show/hide pro features.
/// Whether the user currently has Pro.
/// Auto-invalidates when a subscription expires.
final isProProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  final isPro = await service.isPro();

  // If Pro, check if there's an expiry and schedule auto-invalidation
  if (isPro) {
    final isar = await ref.watch(isarServiceProvider).getInstance();
    final expiresConfig =
        await isar.appConfigs.filter().keyEqualTo('ent_expires_at').findFirst();
    final expiresAt = expiresConfig?.dateValue;

    if (expiresAt != null) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) return false; // already expired
      // Schedule invalidation at expiry
      final timer = Timer(remaining, () => ref.invalidateSelf());
      ref.onDispose(timer.cancel);
    }
  }

  return isPro;
});

/// Check if a specific feature is accessible.
final canAccessProvider =
    FutureProvider.autoDispose.family<bool, ProFeature>((ref, feature) {
  return ref.watch(entitlementServiceProvider).canAccess(feature);
});

/// Limit checks for resource creation.
final canCreateAccountProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(entitlementServiceProvider).canCreateAccount();
});

final canCreateBudgetProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(entitlementServiceProvider).canCreateBudget();
});

final canCreateGoalProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(entitlementServiceProvider).canCreateGoal();
});

final canCreateTripProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(entitlementServiceProvider).canCreateTrip();
});

/// Watches Pro/trial status and reverts to free theme if access expires.
final themeEntitlementGuardProvider = Provider.autoDispose<void>((ref) {
  final hasAccess = ref.watch(hasFullAccessProvider).valueOrNull ?? true;
  if (!hasAccess) {
    final currentTheme = ref.read(themeNotifierProvider);
    if (currentTheme.isPro) {
      Future.microtask(() {
        ref.read(themeNotifierProvider.notifier).enforceFreeTheme();
      });
    }
  }
});

final isInTrialProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  return service.isInTrialPeriod();
});

final trialDaysRemainingProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  return service.trialDaysRemaining();
});

/// True if user has full access via any path: Pro, trial, or active.
final hasFullAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final isPro = await ref.watch(isProProvider.future);
  if (isPro) return true;
  final inTrial = await ref.watch(isInTrialProvider.future);
  return inTrial;
});

enum ProPlan { free, trial, monthly, yearly }

class ProPlanInfo {
  final ProPlan plan;
  final DateTime? expiresAt;
  final int? trialDaysRemaining;

  const ProPlanInfo({
    required this.plan,
    this.expiresAt,
    this.trialDaysRemaining,
  });

  String get label => switch (plan) {
        ProPlan.free => 'Free',
        ProPlan.trial => 'Full Access',
        ProPlan.monthly => 'Pro Monthly',
        ProPlan.yearly => 'Pro Yearly',
      };

  IconData get icon => switch (plan) {
        ProPlan.free => LucideIcons.user,
        ProPlan.trial => LucideIcons.gift,
        _ => LucideIcons.crown,
      };

  bool get isPro => plan == ProPlan.monthly || plan == ProPlan.yearly;

  bool get isTrial => plan == ProPlan.trial;
  bool get hasFullAccess => plan != ProPlan.free;
}

final proPlanInfoProvider =
    FutureProvider.autoDispose<ProPlanInfo>((ref) async {
  final isPro = await ref.watch(isProProvider.future);
  if (!isPro) {
    // Check if in trial
    final inTrial = await ref.watch(isInTrialProvider.future);
    if (inTrial) {
      final daysLeft = await ref.watch(trialDaysRemainingProvider.future);
      return ProPlanInfo(plan: ProPlan.trial, trialDaysRemaining: daysLeft);
    }
    return const ProPlanInfo(plan: ProPlan.free);
  }

  final isar = await ref.watch(isarServiceProvider).getInstance();

  final productConfig =
      await isar.appConfigs.filter().keyEqualTo('ent_product_id').findFirst();
  final expiresConfig =
      await isar.appConfigs.filter().keyEqualTo('ent_expires_at').findFirst();

  final productId = productConfig?.stringValue ?? '';
  final plan = switch (productId) {
    _ when productId.contains(EntitlementProducts.monthlyPlan) =>
      ProPlan.monthly,
    _ when productId.contains(EntitlementProducts.yearlyPlan) => ProPlan.yearly,
    _ => ProPlan.yearly,
  };

  return ProPlanInfo(plan: plan, expiresAt: expiresConfig?.dateValue);
});

/// Invalidates all entitlement-related providers.
/// Call after any purchase, restore, or revoke.
void invalidateEntitlements(WidgetRef ref) {
  ref.invalidate(isProProvider);
  ref.invalidate(proPlanInfoProvider);
  ref.invalidate(hasFullAccessProvider);
  ref.invalidate(isInTrialProvider);
  ref.invalidate(trialDaysRemainingProvider);
  ref.invalidate(canCreateAccountProvider);
  ref.invalidate(canCreateBudgetProvider);
  ref.invalidate(canCreateGoalProvider);
  ref.invalidate(canCreateTripProvider);
}
