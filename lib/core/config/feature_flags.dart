/// Feature flags for controlled migration to the new dashboard engine.
/// Flip these ONE AT A TIME after verifying parity.
abstract final class FeatureFlags {
  static const useNewDashboardEngine = true;
  static const useValidityGate = true;
  static const useCoreStateMachines = true;

  /// Legacy AI insight cards on dashboard. Gate until core/logic/generators
  /// cover all signal types (drift, leak, weekend, best-day).
  /// When false: ai_insight_provider is not consumed by any widget.
  static const useLegacyAiInsights = true;
}
