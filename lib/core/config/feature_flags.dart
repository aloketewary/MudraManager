/// Feature flags for controlled migration to the new dashboard engine.
/// Flip these ONE AT A TIME after verifying parity.
abstract final class FeatureFlags {
  static const useNewDashboardEngine = true;
  static const useValidityGate = true;
  static const useCoreStateMachines = true;
}
