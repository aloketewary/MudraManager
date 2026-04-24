import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

void main() {
  group('FreeTierLimits', () {
    test('limits are positive and reasonable', () {
      expect(FreeTierLimits.maxAccounts, greaterThan(0));
      expect(FreeTierLimits.maxBudgets, greaterThan(0));
      expect(FreeTierLimits.maxGoals, greaterThan(0));
      expect(FreeTierLimits.maxActiveTrips, greaterThan(0));
      expect(FreeTierLimits.maxThemes, greaterThan(0));
    });

    test('limits are restrictive (less than 10)', () {
      expect(FreeTierLimits.maxAccounts, lessThanOrEqualTo(10));
      expect(FreeTierLimits.maxBudgets, lessThanOrEqualTo(10));
      expect(FreeTierLimits.maxGoals, lessThanOrEqualTo(10));
      expect(FreeTierLimits.maxActiveTrips, lessThanOrEqualTo(5));
    });
  });

  group('ProFeature enum', () {
    test('has resource limit features', () {
      expect(ProFeature.values, contains(ProFeature.unlimitedAccounts));
      expect(ProFeature.values, contains(ProFeature.unlimitedBudgets));
      expect(ProFeature.values, contains(ProFeature.unlimitedGoals));
      expect(ProFeature.values, contains(ProFeature.unlimitedTrips));
    });

    test('has screen/module features', () {
      expect(ProFeature.values, contains(ProFeature.advancedAnalytics));
      expect(ProFeature.values, contains(ProFeature.spendingPersonality));
      expect(ProFeature.values, contains(ProFeature.monthlyRecap));
    });

    test('has export and backup features', () {
      expect(ProFeature.values, contains(ProFeature.businessExports));
      expect(ProFeature.values, contains(ProFeature.cloudBackup));
    });
  });

  group('gatedRoutes', () {
    test('analytics routes are gated', () {
      expect(gatedRoutes['/analytics'], ProFeature.advancedAnalytics);
      expect(gatedRoutes['/financial-health'], ProFeature.advancedAnalytics);
      expect(gatedRoutes['/tax-estimation'], ProFeature.advancedAnalytics);
      expect(gatedRoutes['/spending-personality'], ProFeature.spendingPersonality);
    });

    test('free routes are not in the map', () {
      expect(gatedRoutes.containsKey('/'), false);
      expect(gatedRoutes.containsKey('/transactions'), false);
      expect(gatedRoutes.containsKey('/settings'), false);
    });

    test('all gated routes map to valid ProFeature', () {
      for (final entry in gatedRoutes.entries) {
        expect(ProFeature.values, contains(entry.value),
            reason: '${entry.key} maps to invalid feature',);
      }
    });

    test('backup route is gated', () {
      expect(gatedRoutes['/backup-restore'], ProFeature.cloudBackup);
    });
  });

  group('ProPlanInfo', () {
    test('free plan has no full access', () {
      const info = ProPlanInfo(plan: ProPlan.free);
      expect(info.isPro, false);
      expect(info.isTrial, false);
      expect(info.hasFullAccess, false);
      expect(info.label, 'Free');
    });

    test('trial plan has full access but is not pro', () {
      const info = ProPlanInfo(plan: ProPlan.trial, trialDaysRemaining: 45);
      expect(info.isPro, false);
      expect(info.isTrial, true);
      expect(info.hasFullAccess, true);
      expect(info.label, 'Full Access');
    });

    test('monthly plan is pro with full access', () {
      final info = ProPlanInfo(
        plan: ProPlan.monthly,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(info.isPro, true);
      expect(info.isTrial, false);
      expect(info.hasFullAccess, true);
      expect(info.label, 'Pro Monthly');
    });

    test('yearly plan is pro with full access', () {
      final info = ProPlanInfo(
        plan: ProPlan.yearly,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      expect(info.isPro, true);
      expect(info.hasFullAccess, true);
      expect(info.label, 'Pro Yearly');
    });
  });

  group('EntitlementProducts', () {
    test('subscription product id is defined', () {
      expect(EntitlementProducts.subscription, isNotEmpty);
    });

    test('isSubscription identifies correctly', () {
      expect(EntitlementProducts.isSubscription(EntitlementProducts.subscription), true);
      expect(EntitlementProducts.isSubscription('random_id'), false);
    });

    test('allProductIds contains subscription', () {
      expect(EntitlementProducts.allProductIds, contains(EntitlementProducts.subscription));
    });

    test('plan identifiers are distinct', () {
      expect(EntitlementProducts.monthlyPlan, isNot(EntitlementProducts.yearlyPlan));
    });
  });

  group('AppColorTheme isPro classification', () {
    test('free themes are not pro', () {
      expect(AppColorTheme.finance.isPro, false);
      expect(AppColorTheme.classic.isPro, false);
      expect(AppColorTheme.mint.isPro, false);
    });

    test('pro themes are pro', () {
      final proThemes = AppColorTheme.values.where((t) => t.isPro);
      expect(proThemes.length, greaterThan(0));
      for (final theme in proThemes) {
        expect(theme.isPro, true,
            reason: '${theme.name} should be pro',);
      }
    });

    test('exactly 3 free themes', () {
      final freeThemes = AppColorTheme.values.where((t) => !t.isPro);
      expect(freeThemes.length, 3);
    });

    test('every theme has a label and subtitle', () {
      for (final theme in AppColorTheme.values) {
        expect(theme.label, isNotEmpty, reason: '${theme.name} missing label');
        expect(theme.subtitle, isNotEmpty, reason: '${theme.name} missing subtitle');
      }
    });

    test('every theme has a seed color', () {
      for (final theme in AppColorTheme.values) {
        expect(theme.seedColor, isNotNull, reason: '${theme.name} missing seedColor');
      }
    });
  });
}
