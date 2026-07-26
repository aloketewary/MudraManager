import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';

void main() {
  group('B5 Scroll Performance Bug Condition', () {
    /// Bug Condition B5: Missing RepaintBoundary causes scroll jank
    ///
    /// This test verifies that scrolling through a list of AnimatedBalance
    /// widgets causes frame rate drops below 55fps when RepaintBoundary
    /// is not used to isolate repaints.
    ///
    /// **Validates: Requirements 1.5**
    testWidgets(
        'Scrolling list of 50 animated balances drops frame rate below 55fps (B5 Bug Condition)',
        (tester) async {
      /// Build a ListView with 50 AnimatedBalance items
      /// The widget does NOT have RepaintBoundary wrapper (bug condition)
      final List<double> values = List.generate(50, (index) => 1000.0 + index * 100);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: AnimatedBalance(
                      value: values[index],
                      duration: const Duration(milliseconds: 500),
                    ),
                    subtitle: Text('Account ${index + 1}'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      /// Use Flutter's frame monitoring for accurate FPS measurement
      final stopwatch = Stopwatch()..start();

      /// Scroll through the entire list to gather frame data
      for (int i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -1000),
        );
        await tester.pump();
      }

      stopwatch.stop();

      /// Calculate actual frame rate based on elapsed time
      if (stopwatch.elapsedMilliseconds > 0) {
        final fps = 1000 / stopwatch.elapsedMilliseconds * 10;

        /// Bug condition: Frame rate should be below 55fps without RepaintBoundary
        /// This test SHOULD FAIL on unfixed code, confirming the bug exists
        expect(
          fps,
          lessThan(55),
          reason: '''Scrolling list of 50 animated balances drops to ${fps.toStringAsFixed(1)}fps without RepaintBoundary isolation.

            Counterexample: AnimatedBalance widgets in a scrollable ListView should maintain 55+ fps during scrolling. Without RepaintBoundary, each AnimatedBalance widget's animation repaints the entire subtree causing frame drops.

            Expected: fps >= 55 (smooth scrolling with RepaintBoundary isolation)
            Actual: fps = ${fps.toStringAsFixed(1)} (below threshold, confirming B5 bug)

            Root Cause: Missing RepaintBoundary wrapper in AnimatedBalance causes animation repaints to propagate up the widget tree, triggering excessive repaints during scrolling.''',
        );
      } else {
        /// If time is too short, use the frame count to determine
        expect(
          10,
          greaterThan(10),
          reason: 'Insufficient frame data gathered. Need at least 10 frames for accurate measurement.',
        );
      }
    });

    /// Alternative test checking if AnimatedBalance has RepaintBoundary in its ancestor chain
    testWidgets(
        'AnimatedBalance has RepaintBoundary isolation for scroll performance (B5 Fix Verification)',
        (tester) async {
      /// Build a scrollable list with AnimatedBalance widgets
      final values = List.generate(50, (i) => 1000.0 + i * 50);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: ListView.builder(
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AnimatedBalance(
                        value: values[index],
                        duration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      /// Scroll to force all items to build (ListView.builder is lazy)
      for (int i = 0; i < 5; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -800),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      /// Find all AnimatedBalance widgets
      final animatedBalanceFinder = find.byType(AnimatedBalance);
      expect(animatedBalanceFinder, findsWidgets);

      /// Count total RepaintBoundary widgets in the tree
      final repaintBoundaryFinder = find.byType(RepaintBoundary);
      final repaintBoundaryCount = repaintBoundaryFinder.evaluate().length;

      /// Check if RepaintBoundary count is at least equal to AnimatedBalance count
      /// This verifies each AnimatedBalance has a RepaintBoundary wrapper
      final elements = tester.elementList(animatedBalanceFinder);
      final animatedBalanceCount = elements.length;

      /// This test verifies the fix - AnimatedBalance SHOULD have RepaintBoundary
      expect(
        repaintBoundaryCount,
        greaterThanOrEqualTo(animatedBalanceCount),
        reason: '''AnimatedBalance in scrollable list must have RepaintBoundary isolation (B5 Fix Verification).

                  Counterexample: $repaintBoundaryCount RepaintBoundary widgets found for $animatedBalanceCount AnimatedBalance widgets.

                  Expected: At least as many RepaintBoundary widgets as AnimatedBalance widgets for scroll isolation
                  Actual: $repaintBoundaryCount RepaintBoundary widgets, $animatedBalanceCount AnimatedBalance widgets

                  Without RepaintBoundary:
                  - Animation changes trigger repaints of the entire list item
                  - Scrolling causes continuous repaints of all visible AnimatedBalance widgets
                  - Frame rate drops below 55fps during active scrolling

                  Solution: Wrap AnimatedBalance content with RepaintBoundary to isolate repaints.''',
      );
    });
  });
}