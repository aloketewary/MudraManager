import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

const onboardingData = [
  // 1. Welcome — brand identity
  OnboardingPage(
    title: 'welcome_to_app',
    description: 'manageYourMoneyDescription',
    icon: LucideIcons.indianRupee,
  ),
  // 2. SMS auto-import — key differentiator
  OnboardingPage(
    title: 'onboard_SmartSmsTracking',
    description: 'onboard_SmartSmsTrackingDesc',
    icon: LucideIcons.messageSquare,
  ),
  // 3. Budgets & Goals
  OnboardingPage(
    title: 'onboard_SetBudgetsAndGoals',
    description: 'onboard_stayOnTrackAndAchieveYourDream',
    icon: LucideIcons.target,
  ),
  // 4. Analytics & Insights
  OnboardingPage(
    title: 'onboard_InsightsAndAnalytics',
    description: 'onboard_InsightsAndAnalyticsDesc',
    icon: LucideIcons.chartBar,
  ),
  // 5. Privacy-first — trust builder, final CTA
  OnboardingPage(
    title: 'onboard_SecureAndPrivate',
    description: 'onboard_SecureAndPrivateDesc',
    icon: LucideIcons.shieldCheck,
  ),
];
