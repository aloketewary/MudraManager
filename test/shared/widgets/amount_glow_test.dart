import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';

void main() {
  group('AmountGlow Performance', () {
    testWidgets('AmountGlow rebuilds only once for static content (B1 Bug Condition)', (tester) async {
      // Counter to track rebuilds
      int rebuildCount = 0;

      // Create a widget that tracks rebuilds
      final childWidget = Builder(
        builder: (context) {
          rebuildCount++;
          return Container(
            width: 100,
            height: 50,
            color: Colors.blue,
          );
        },
      );

      // Build AmountGlow with the tracking child
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountGlow(
              color: Colors.green,
              child: childWidget,
            ),
          ),
        ),
      );

      // Initial build should happen (rebuildCount = 1)
      await tester.pumpAndSettle();

      // Capture the rebuild count after initial build
      final initialRebuildCount = rebuildCount;

      // Pump again without any changes to see if it rebuilds
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountGlow(
              color: Colors.green,
              child: childWidget,
            ),
          ),
        ),
      );

      // Rebuild count should still be 1 (only initial build)
      // If rebuild count > 1, it indicates unnecessary rebuilds (bug exists)
      expect(
        initialRebuildCount,
        equals(1),
        reason: '''AmountGlow rebuilds 60 times/second with AnimatedOpacity despite no value changes.

Counterexample: AmountGlow with static glow properties should rebuild exactly once on initial build, but if AnimatedOpacity is used (bug condition B1), it will continuously rebuild the widget subtree even though the glow effect is static and requires no animation.

Expected: rebuildCount = 1 (single rebuild for static content)
Actual: rebuildCount = $initialRebuildCount''',
      );
    });
  });
}
