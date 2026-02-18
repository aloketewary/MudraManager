// Your onboarding page model
import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final bool needsInput;
  final bool backupDialogue;
  final String? inputHint;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.needsInput = false,
    this.backupDialogue = false,
    this.inputHint,
  });
}

// Sample onboarding data
final onboardingData = [
  OnboardingPage(
    title: "welcome_to_app",
    description: "manageYourMoneyDescription",
    icon: Icons.account_balance_wallet_outlined,
  ),
  OnboardingPage(
    title: 'onboard_TrackYourTransactions',
    description: "onboard_SeeWhereYourMoneyGoes",
    icon: Icons.show_chart_outlined,
  ),
  OnboardingPage(
    title: "onboard_SetBudgetsAndGoals",
    description: "onboard_stayOnTrackAndAchieveYourDream",
    icon: Icons.track_changes_outlined,
  ),
  OnboardingPage(
    title: "onboard_GetStarted",
    description: "onboard_letsSetupYourAccount",
    icon: Icons.rocket_launch_outlined,
  ),
];
