import 'package:flutter/material.dart';
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
        MaterialApp(
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
      );

      await tester.pumpAndSettle();

      /// Measure frame rate during scrolling
      int frameCount = 0;
      DateTime? firstFrameTime;
      final frameTimes = <DateTime>[];

      /// Scroll through the entire list multiple times to gather frame data
      for (int i = 0; i < 5; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -800),
          duration: const Duration(milliseconds: 500),
        );
        await tester.pump();

        frameTimes.add(DateTime.now());
        frameCount++;

        /// Small delay to allow frames to render
        await Future.delayed(const Duration(milliseconds: 50));
      }

      /// Continue scrolling to gather more frame data
      for (int i = 0; i < 5; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, 800),
          duration: const Duration(milliseconds: 500),
        );
        await tester.pump();

        frameTimes.add(DateTime.now());
        frameCount++;

        await Future.delayed(const Duration(milliseconds: 50));
      }

      /// Calculate frame rate
      if (frameTimes.length >= 2) {
        final totalDuration = frameTimes.last.difference(frameTimes.first);
        final averageFrameDuration = totalDuration / (frameTimes.length - 1);
        final fps = 1000 / averageFrameDuration.inMilliseconds;

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
        /// If we couldn't gather enough frame data, fail the test
        expect(
          frameTimes.length,
          greaterThanOrEqualTo(2),
          reason: 'Insufficient frame data gathered to measure fps. Gathered ${frameTimes.length} frames, need at least 2.',
        );
      }
    }));

    /// Alternative test using frame benchmarking approach
    testWidgets(
        'AnimatedBalance lacks RepaintBoundary isolation (B5 Bug Condition)',
        (tester) async {
      /// Build a scrollable list with AnimatedBalance widgets
      final values = List.generate(50, (i) => 1000.0 + i * 50);

      await tester.pumpWidget(
        MaterialApp(
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
      );

      await tester.pumpAndSettle();

      /// Verify that AnimatedBalance does NOT have RepaintBoundary by checking
      /// the widget tree structure
      final animatedBalanceWidgets = find.byType(AnimatedBalance);
      expect(animatedBalanceWidgets, findsWidgets);

      /// Count RepaintBoundary widgets in the tree
      final repaintBoundaryCount = find.byType(RepaintBoundary).evaluate().length;

      /// Check if RepaintBoundary is present (it shouldn't be in unfixed code)
      final hasRepaintBoundary = repaintBoundaryCount > 0;

      /// This test exposes the bug by checking for missing RepaintBoundary
      /// The expectation is that RepaintBoundary is NOT present (bug condition)
      expect(
        hasRepaintBoundary,
        isFalse,
        reason: '''AnimatedBalance in scrollable list lacks RepaintBoundary isolation (B5 Bug Condition).

Counterexample: ListView with 50 AnimatedBalance widgets has $repaintBoundaryCount RepaintBoundary widgets.

Expected: At least 1 RepaintBoundary wrapping AnimatedBalance for scroll isolation
Actual: No RepaintBoundary wrapping, animations will repaint entire subtree during scroll

Without RepaintBoundary:
- Animation changes trigger repaints of the entire list item
- Scrolling causes continuous repaints of all visible AnimatedBalance widgets
- Frame rate drops below 55fps during active scrolling

Solution: Wrap AnimatedBalance content with RepaintBoundary to isolate repaints.''',
      );
    });
  });
}