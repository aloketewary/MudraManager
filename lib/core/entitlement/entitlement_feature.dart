/// All gatable features in the app.
enum ProFeature {
  // ── Resource limits ──
  unlimitedAccounts,
  unlimitedBudgets,
  unlimitedGoals,
  unlimitedTrips,

  // ── Screens / modules ──
  advancedAnalytics, // analytics, financial health
  spendingPersonality,
  netWorth,
  monthlyRecap,
  dashboardCustomize,

  // ── Exports ──
  businessExports,

  // ── Backup ──
  cloudBackup,

  // ── Plugins ──
  premiumPlugins, // extra category packs, etc.

  // ── Theming ──
  allThemes,
}

/// Free-tier limits. Anything not listed here is unlimited.
class FreeTierLimits {
  static const int maxAccounts = 3;
  static const int maxBudgets = 2;
  static const int maxGoals = 2;
  static const int maxActiveTrips = 1;
  static const int maxThemes = 3;
}

/// Maps a route path to the [ProFeature] it requires.
/// Routes NOT in this map are free.
const Map<String, ProFeature> gatedRoutes = {
  '/analytics': ProFeature.advancedAnalytics,
  '/financial-health': ProFeature.advancedAnalytics,
  '/spending-personality': ProFeature.spendingPersonality,
  '/net-worth': ProFeature.netWorth,
  '/monthly-recap': ProFeature.monthlyRecap,
  '/dashboard-customize': ProFeature.dashboardCustomize,
  '/backup-restore': ProFeature.cloudBackup,
};
