import 'package:isar_community/isar.dart';
import 'package:mudra_manager/features/memory/data/insight_exposure.dart';
import 'package:mudra_manager/features/memory/data/financial_snapshot.dart';

/// Per-variant experiment results.
class VariantReport {
  final String variant;
  final int exposures;
  final int clicks;
  final int viewedDetails;
  final int dismissals;
  final double avgImpact;
  final double medianImpact;
  final double exposureCtr;
  final double userCtr;
  final double dismissRate;
  final int uniqueUsers;

  const VariantReport({
    required this.variant,
    required this.exposures,
    required this.clicks,
    required this.viewedDetails,
    required this.dismissals,
    required this.avgImpact,
    required this.medianImpact,
    required this.exposureCtr,
    required this.userCtr,
    required this.dismissRate,
    required this.uniqueUsers,
  });
}

/// Full experiment dashboard — answers all key evaluation questions.
class ExperimentDashboard {
  final List<VariantReport> byVariant;
  final int totalExposures;
  final int totalUniqueUsers;
  final int usersGeneratingDrift;
  final double avgDriftsPerUser;
  final bool hasReachedThreshold;

  // Overall funnel
  final int displayed;
  final int clicked;
  final int viewedDetails;
  final int dismissed;

  // Per-user CTR (one vote per user)
  final double overallUserCtr;
  final double overallExposureCtr;
  final double overallDismissRate;

  // Coverage diagnostic
  final int snapshotMonths;

  const ExperimentDashboard({
    required this.byVariant,
    required this.totalExposures,
    required this.totalUniqueUsers,
    required this.usersGeneratingDrift,
    required this.avgDriftsPerUser,
    required this.hasReachedThreshold,
    required this.displayed,
    required this.clicked,
    required this.viewedDetails,
    required this.dismissed,
    required this.overallUserCtr,
    required this.overallExposureCtr,
    required this.overallDismissRate,
    required this.snapshotMonths,
  });
}

/// Generates the experiment report from InsightExposure data.
/// Call from dev menu / debug screen.
Future<ExperimentDashboard> generateExperimentDashboard(Isar isar) async {
  final all = await isar.insightExposures
      .filter()
      .insightTypeEqualTo('spending_drift')
      .displayedAtIsNotNull()
      .findAll();

  final allUserIds =
      all.where((e) => e.userId != null).map((e) => e.userId!).toSet();

  // Users who clicked (for per-user CTR)
  final clickingUserIds = all
      .where((e) => e.clickedAt != null && e.userId != null)
      .map((e) => e.userId!)
      .toSet();

  // Coverage: how many months of snapshots exist
  final snapshotCount = await isar.financialSnapshots.count();

  // Users who generated at least one drift (regardless of display)
  final allGenerated = await isar.insightExposures
      .filter()
      .insightTypeEqualTo('spending_drift')
      .findAll();
  final generatingUsers = allGenerated
      .where((e) => e.userId != null)
      .map((e) => e.userId!)
      .toSet();

  // By variant
  final byVariant = <String, List<InsightExposure>>{};
  for (final e in all) {
    byVariant.putIfAbsent(e.variant, () => []).add(e);
  }

  final reports = byVariant.entries.map((entry) {
    final list = entry.value;
    final clicks = list.where((e) => e.clickedAt != null).length;
    final details = list.where((e) => e.viewedDetailsAt != null).length;
    final dismissals = list.where((e) => e.dismissedAt != null).length;
    final impacts = list
        .where((e) => e.impactAmount != null)
        .map((e) => e.impactAmount!)
        .toList();
    final avgImpact =
        impacts.isEmpty ? 0.0 : impacts.reduce((a, b) => a + b) / impacts.length;
    final medianImpact = _median(impacts);
    final users =
        list.where((e) => e.userId != null).map((e) => e.userId!).toSet();
    final usersClicked = list
        .where((e) => e.clickedAt != null && e.userId != null)
        .map((e) => e.userId!)
        .toSet();

    return VariantReport(
      variant: entry.key,
      exposures: list.length,
      clicks: clicks,
      viewedDetails: details,
      dismissals: dismissals,
      avgImpact: avgImpact,
      medianImpact: medianImpact,
      exposureCtr: list.isEmpty ? 0 : clicks / list.length * 100,
      userCtr: users.isEmpty ? 0 : usersClicked.length / users.length * 100,
      dismissRate: list.isEmpty ? 0 : dismissals / list.length * 100,
      uniqueUsers: users.length,
    );
  }).toList();

  final totalClicks = all.where((e) => e.clickedAt != null).length;
  final totalDetails = all.where((e) => e.viewedDetailsAt != null).length;
  final totalDismissals = all.where((e) => e.dismissedAt != null).length;

  return ExperimentDashboard(
    byVariant: reports,
    totalExposures: all.length,
    totalUniqueUsers: allUserIds.length,
    usersGeneratingDrift: generatingUsers.length,
    avgDriftsPerUser:
        allUserIds.isEmpty ? 0 : all.length / allUserIds.length,
    hasReachedThreshold: all.length >= 300 && allUserIds.length >= 100,
    displayed: all.length,
    clicked: totalClicks,
    viewedDetails: totalDetails,
    dismissed: totalDismissals,
    overallUserCtr: allUserIds.isEmpty
        ? 0
        : clickingUserIds.length / allUserIds.length * 100,
    overallExposureCtr:
        all.isEmpty ? 0 : totalClicks / all.length * 100,
    overallDismissRate:
        all.isEmpty ? 0 : totalDismissals / all.length * 100,
    snapshotMonths: snapshotCount,
  );
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}
