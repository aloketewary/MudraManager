import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/models/onboarding_page_model.dart';

void main() {
  group('Onboarding page model', () {
    test('has exactly 3 pages (reduced from 5)', () {
      expect(onboardingData.length, 3);
    });

    test('page 1 is Welcome with indianRupee icon', () {
      final page = onboardingData[0];
      expect(page.title, 'welcome_to_app');
      expect(page.description, 'manageYourMoneyDescription');
      expect(page.icon, LucideIcons.indianRupee);
    });

    test('page 2 is Smart Auto Tracking with merged description', () {
      final page = onboardingData[1];
      expect(page.title, 'onboard_SmartAutoTracking');
      expect(page.description, 'onboard_smartTrackingMergedDesc');
      expect(page.icon, LucideIcons.bellRing);
    });

    test('page 3 is Secure & Private (trust builder + CTA)', () {
      final page = onboardingData[2];
      expect(page.title, 'onboard_SecureAndPrivate');
      expect(page.description, 'onboard_SecureAndPrivateDesc');
      expect(page.icon, LucideIcons.shieldCheck);
    });

    test('no page references removed Budget/Goals page', () {
      final titles = onboardingData.map((p) => p.title).toList();
      expect(titles, isNot(contains('onboard_SetBudgetsAndGoals')));
    });

    test('no page references removed Insights page', () {
      final titles = onboardingData.map((p) => p.title).toList();
      expect(titles, isNot(contains('onboard_InsightsAndAnalytics')));
    });

    test('all pages have non-empty title and description keys', () {
      for (final page in onboardingData) {
        expect(page.title, isNotEmpty);
        expect(page.description, isNotEmpty);
      }
    });
  });
}
