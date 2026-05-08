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
  // 2. Smart tracking — merged SMS + budgets + insights
  OnboardingPage(
    title: 'onboard_SmartAutoTracking',
    description: 'onboard_smartTrackingMergedDesc',
    icon: LucideIcons.bellRing,
  ),
  // 3. Privacy-first — trust builder, final CTA
  OnboardingPage(
    title: 'onboard_SecureAndPrivate',
    description: 'onboard_SecureAndPrivateDesc',
    icon: LucideIcons.shieldCheck,
  ),
];
