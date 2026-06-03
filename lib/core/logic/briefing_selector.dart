import 'package:mudra_manager/core/domain/financial_states.dart';

/// A candidate briefing signal with its trigger, params, and route.
class BriefingSelection {
  final BriefingTrigger trigger;
  final Map<String, dynamic> params;
  final String? actionRoute;

  const BriefingSelection({
    required this.trigger,
    required this.params,
    this.actionRoute,
  });
}

/// Selects the single highest-priority briefing from candidates.
/// Returns null when the system should be silent.
abstract final class BriefingSelector {
  static BriefingSelection? select(List<BriefingSelection> candidates) {
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => b.trigger.priority.compareTo(a.trigger.priority),
    );
    return candidates.first;
  }
}
