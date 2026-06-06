import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';

/// Diagnostic snapshot of the insight pipeline for a single compute cycle.
/// Use in dev mode to understand why a specific insight was or wasn't shown.
class InsightDiagnostics {
  final List<Insight> generated;
  final List<Insight> suppressed;
  final List<Insight> active;
  final Insight? selected;

  const InsightDiagnostics({
    required this.generated,
    required this.suppressed,
    required this.active,
    this.selected,
  });

  /// Run the full pipeline with diagnostics capture.
  static InsightDiagnostics run({
    required List<InsightGenerator> generators,
    required Facts facts,
    required List<SuppressionRecord> suppressionHistory,
    required DateTime now,
  }) {
    final generated = generators.expand((g) => g.generate(facts)).toList();

    final suppressed = <Insight>[];
    final active = <Insight>[];

    for (final insight in generated) {
      final isSuppressed = SuppressionEngine.shouldSuppress(
        insight: insight,
        history: suppressionHistory,
        now: now,
      );
      if (isSuppressed) {
        suppressed.add(insight);
      } else {
        active.add(insight);
      }
    }

    active.sort(
      (a, b) => b.effectivePriority.compareTo(a.effectivePriority),
    );

    return InsightDiagnostics(
      generated: generated,
      suppressed: suppressed,
      active: active,
      selected: active.isNotEmpty ? active.first : null,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('── Insight Diagnostics ──')
      ..writeln('Generated: ${generated.length}')
      ..writeln('Suppressed: ${suppressed.length}')
      ..writeln('Active: ${active.length}')
      ..writeln('');

    for (final i in generated) {
      final status = suppressed.contains(i) ? 'SUPPRESSED' : 'ACTIVE';
      buf.writeln(
        '  ${i.trigger.name} [$status]'
        '\n    source: ${i.source}'
        '\n    magnitude: ${i.magnitude.toStringAsFixed(0)}'
        '\n    confidence: ${i.confidence}',
      );
    }

    buf.writeln('');
    if (selected != null) {
      buf.writeln('Selected: ${selected!.trigger.name} (${selected!.source})');
    } else {
      buf.writeln('Selected: SILENT (no active insights)');
    }

    return buf.toString();
  }
}
