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
    title: "Track your Transactions",
    description: "See where your money goes, every day.",
    icon: Icons.show_chart_outlined,
  ),
  OnboardingPage(
    title: "Set Budgets and Goals",
    description: "Stay on track and achieve your dreams.",
    icon: Icons.track_changes_outlined,
  ),
  OnboardingPage(
    title: "Get Started!",
    description: "Let's set up your account.",
    icon: Icons.settings_outlined,
  ),
  OnboardingPage(
    title: "How should we call you?",
    description: "Enter your name to personalize your experience.",
    icon: Icons.person_outline,
    needsInput: true,
    inputHint: "Enter your name",
  ),
  OnboardingPage(
    title: "Setup Your First Account",
    description: "Let's create your first account (let say: Cash).",
    icon: Icons.account_balance_wallet_outlined,
    needsInput: true,
    inputHint: "Account Name",
  ),
  OnboardingPage(
    title: "You're all set!",
    description: "Let's start managing your money wisely.",
    icon: Icons.emoji_events_outlined,
  ),
];
