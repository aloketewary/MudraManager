import 'package:flutter/material.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';

/// Universal screen state contract.
///
/// SINGLE AUTHORITY for what a screen shows and what it can do.
///
/// - gate: controls rendering depth
/// - data: the primary content
/// - constraint: optional boundary state
/// - alert: optional single alert
/// - actions: pre-grouped slots (NO filtering at render time)
///
/// ScreenShell reads [actions] slots directly.
/// Templates read [gate] + [data] + [actions.contextual].
/// Nothing interprets, filters, or selects.
class AppScreenState<T> {
  /// Data readiness gate. Controls what renders.
  final DataValidityLevel gate;

  /// The primary content/data for this screen.
  final T? data;

  /// Optional single constraint state (if relevant).
  final ConstraintInfo? constraint;

  /// Optional single alert (highest priority only).
  final ScreenAlert? alert;

  /// Whether the screen is in loading state.
  final bool isLoading;

  /// Error message if data fetch failed.
  final String? error;

  /// Pre-grouped action slots. Structurally valid by construction.
  final ScreenActions actions;

  const AppScreenState({
    this.gate = DataValidityLevel.valid,
    this.data,
    this.constraint,
    this.alert,
    this.isLoading = false,
    this.error,
    this.actions = ScreenActions.empty,
  });

  /// Convenience: screen has enough data to render primary content.
  bool get canRender => gate != DataValidityLevel.insufficient && data != null;
}

/// Pre-grouped action slots. Single factory entry point.
///
/// Invariants (enforced at construction):
/// - [fab]: 0..1 (nullable field = type-system enforced)
/// - Action IDs are globally unique across ALL slots
/// - All instances go through [empty] or [build] — no other paths exist
///
/// If you hit the StateError, fix the state provider — not this class.
class ScreenActions {
  final List<ScreenAction> appBar;
  final ScreenAction? fab;
  final List<ScreenAction> overflow;
  final List<ScreenAction> contextual;

  const ScreenActions._({
    required this.appBar,
    required this.fab,
    required this.overflow,
    required this.contextual,
  });

  /// Empty state — no actions. Used for loading, insufficient gate, etc.
  static const ScreenActions empty = ScreenActions._(
    appBar: [],
    fab: null,
    overflow: [],
    contextual: [],
  );

  /// Validated construction. Throws [StateError] on duplicate action IDs.
  /// This is the ONLY way to create non-empty ScreenActions.
  factory ScreenActions.build({
    List<ScreenAction> appBar = const [],
    ScreenAction? fab,
    List<ScreenAction> overflow = const [],
    List<ScreenAction> contextual = const [],
  }) {
    final ids = <String>{};
    void check(ScreenAction a) {
      if (!ids.add(a.id)) {
        throw StateError(
          'Duplicate ScreenAction id: "${a.id}". '
          'Each action must be unique across all slots.',
        );
      }
    }

    appBar.forEach(check);
    if (fab != null) check(fab);
    overflow.forEach(check);
    contextual.forEach(check);

    return ScreenActions._(
      appBar: appBar,
      fab: fab,
      overflow: overflow,
      contextual: contextual,
    );
  }

  /// Whether any actions exist at all.
  bool get isEmpty =>
      appBar.isEmpty && fab == null && overflow.isEmpty && contextual.isEmpty;
}

/// A single UI action. Slot is determined by WHERE it lives in ScreenActions,
/// not by a field on the action itself. No placement enum needed.
class ScreenAction {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ScreenAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// A single constraint state for display (budget or bill).
class ConstraintInfo {
  final String label;
  final ConstraintSeverity severity;
  final String? route;

  const ConstraintInfo({
    required this.label,
    required this.severity,
    this.route,
  });
}

enum ConstraintSeverity { ok, warn, breach }

/// A single alert for a screen. One screen, one alert max.
class ScreenAlert {
  final String title;
  final String message;
  final ScreenAlertLevel level;
  final String? actionRoute;

  const ScreenAlert({
    required this.title,
    required this.message,
    required this.level,
    this.actionRoute,
  });
}

enum ScreenAlertLevel { info, warning, urgent }
