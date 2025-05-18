// Your onboarding page model
import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final bool needsInput;
  final String? inputHint;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.needsInput = false,
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
    icon: Icons.settings_outlined,
  ),
  OnboardingPage(
    title: "onboard_howShouldWeCallYou",
    description: "onboard_enterYourNameToPersonalizeYourExperience",
    icon: Icons.person_outline,
    needsInput: true,
    inputHint: "onboard_enterYourName",
  ),
  OnboardingPage(
    title: "onboard_setupYourFirstAccount",
    description: "onboard_letsCreateYourFirstAccount",
    icon: Icons.account_balance_wallet_outlined,
    needsInput: true,
    inputHint: "onboard_accountName",
  ),
  OnboardingPage(
    title: "onboard_youAreAllSet",
    description: "onboard_letsStartManagingYourMoneyWisely",
    icon: Icons.emoji_events_outlined,
  ),
];
