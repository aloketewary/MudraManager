import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mudra_manager/main.dart' as app;

/// Integration tests for Mudra Manager.
///
/// These tests run on a real device/emulator and simulate real user
/// interactions — similar to Jasmine/Protractor in Angular.
///
/// Run with:
///   flutter test integration_test/app_test.dart
///
/// Or on a specific device:
///   flutter test integration_test/app_test.dart -d [device_id]
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow', () {
    testWidgets('completes full onboarding and reaches home screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should land on onboarding screen
      // Swipe through onboarding pages or tap Continue/Skip
      final skipFinder = find.text('Skip');
      if (skipFinder.evaluate().isNotEmpty) {
        await tester.tap(skipFinder);
        await tester.pumpAndSettle();
      }

      // Step 0: Name entry
      final nameField = find.byType(TextFormField).first;
      expect(nameField, findsOneWidget, reason: 'Name field should be visible');
      await tester.enterText(nameField, 'Test User');
      await tester.pumpAndSettle();

      // Tap Continue
      await _tapContinueButton(tester);

      // Step 1: Currency selection — INR is pre-selected, just continue
      await _tapContinueButton(tester);

      // Step 2: Account setup
      await tester.pumpAndSettle();
      final textFields = find.byType(TextFormField);
      // Enter account name
      await tester.enterText(textFields.first, 'Cash');
      await tester.pumpAndSettle();

      // Balance field should already have '0', continue
      await _tapContinueButton(tester);

      // Step 3: Tone picker — just continue
      await tester.pumpAndSettle();
      await _tapContinueButton(tester);

      // Step 4: Category packs — tap Get Started
      await tester.pumpAndSettle();
      await _tapContinueButton(tester);

      // Should reach home screen — wait for Isar + deferred init
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on the home screen by checking for bottom nav
      expect(
        find.byType(NavigationBar),
        findsOneWidget,
        reason: 'Home screen should show bottom navigation bar',
      );

      // Take screenshot for CI
      await binding.takeScreenshot('onboarding_complete');
    });
  });

  group('Tab Navigation', () {
    testWidgets('can navigate between all tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If onboarding shows, skip it first
      await _skipOnboardingIfPresent(tester);

      final navBar = find.byType(NavigationBar);
      if (navBar.evaluate().isEmpty) {
        // Still loading — wait more
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      expect(navBar, findsOneWidget);

      // Tap Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Tap Manage tab
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();

      // Tap Insights tab
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Go back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(
        navBar,
        findsOneWidget,
        reason: 'Should still be on home after full tab cycle',
      );

      await binding.takeScreenshot('tab_navigation_complete');
    });
  });

  group('Add Transaction Flow', () {
    testWidgets('can open add transaction screen and fill form',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _skipOnboardingIfPresent(tester);

      // Find and tap the FAB or add button
      // The app uses SpeedDialFab — look for FloatingActionButton
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
        await tester.pumpAndSettle();

        // Speed dial may show options — look for add expense/income option
        // Try tapping the first available action
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // If we're on the add transaction screen, fill the form
      final amountFields = find.byType(TextFormField);
      if (amountFields.evaluate().isNotEmpty) {
        // Enter amount
        await tester.enterText(amountFields.first, '500');
        await tester.pumpAndSettle();

        await binding.takeScreenshot('add_transaction_filled');
      }
    });
  });
}

/// Taps the primary FilledButton (Continue / Get Started).
Future<void> _tapContinueButton(WidgetTester tester) async {
  final filledButton = find.byType(FilledButton);
  expect(filledButton, findsWidgets, reason: 'Continue button should exist');
  await tester.tap(filledButton.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Skips onboarding if the app shows it (e.g., fresh install state).
Future<void> _skipOnboardingIfPresent(WidgetTester tester) async {
  final skip = find.text('Skip');
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();

    // Complete minimal onboarding
    final nameField = find.byType(TextFormField);
    if (nameField.evaluate().isNotEmpty) {
      await tester.enterText(nameField.first, 'Test User');
      await tester.pumpAndSettle();
      await _tapContinueButton(tester); // name → currency
      await _tapContinueButton(tester); // currency → account

      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, 'Cash');
        await tester.pumpAndSettle();
      }
      await _tapContinueButton(tester); // account → tone
      await _tapContinueButton(tester); // tone → packs
      await _tapContinueButton(tester); // packs → home
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }
}
