import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/ai_insight_provider.dart';
import 'package:mudra_manager/features/memory/data/insight_exposure.dart';
import 'package:mudra_manager/features/memory/data/memory_drift_analyzer.dart';

/// Provides drift insights for the dashboard AI carousel.
/// Does NOT log displayedAt — that's the widget's responsibility.
/// Deduplicates exposures via fingerprint.
final driftInsightsProvider =
    FutureProvider.autoDispose<List<DriftInsightCard>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();

  // Stable user ID from UserProfile (single-user app — typically ID 1)
  final profile = await isar.userProfiles.where().findFirst();
  final userId = profile?.id.toString() ?? '1';

  final detector = SpendingDriftDetector(isar, userId);
  final drifts = await detector.detect(maxResults: 2);

  final cards = <DriftInsightCard>[];

  for (final drift in drifts) {
    // Find existing exposure by fingerprint (deduplication)
    var exposure = await isar.insightExposures
        .filter()
        .fingerprintEqualTo(drift.fingerprint)
        .findFirst();

    if (exposure == null) {
      // First time this drift is generated — create exposure record
      exposure = InsightExposure.create(
        insightType: 'spending_drift',
        fingerprint: drift.fingerprint,
        variant: drift.variant,
        generatedAt: DateTime.now(),
        categoryId: drift.categoryId,
        headline: drift.headline,
        impactAmount: drift.yearlySavingsIfReverted,
        percentChange: drift.percentChange,
        monthsObserved: drift.months,
        userId: userId,
      );
      await isar.writeTxn(() async {
        await isar.insightExposures.put(exposure!);
      });
    }

    cards.add(DriftInsightCard(
      insight: AiInsight(
        title: drift.headline,
        message: drift.narrative,
        type: drift.isRising ? 'warning' : 'success',
        iconType: drift.isRising ? IconType.spending : IconType.savings,
        generatedAt: DateTime.now(),
        actionLabel: 'View Details',
        actionRoute: AppRoutes.statistics,
        priority: drift.isRising ? 80 : 40,
      ),
      exposureId: exposure.id,
    ),);
  }

  return cards;
});

/// A drift insight card paired with its exposure ID for tracking.
class DriftInsightCard {
  final AiInsight insight;
  final int exposureId;

  const DriftInsightCard({required this.insight, required this.exposureId});
}

// ─── Exposure lifecycle tracking (called by widget layer) ───

/// Call when the insight card is rendered on screen for the first time.
Future<void> markInsightDisplayed(Isar isar, int exposureId) async {
  await isar.writeTxn(() async {
    final exp = await isar.insightExposures.get(exposureId);
    if (exp != null && exp.displayedAt == null) {
      exp.displayedAt = DateTime.now();
      await isar.insightExposures.put(exp);
    }
  });
}

/// Call when user taps the insight card.
Future<void> markInsightClicked(Isar isar, int exposureId) async {
  await isar.writeTxn(() async {
    final exp = await isar.insightExposures.get(exposureId);
    if (exp != null && exp.clickedAt == null) {
      exp.clickedAt = DateTime.now();
      await isar.insightExposures.put(exp);
    }
  });
}

/// Call when user navigates to the detail/statistics screen after clicking.
Future<void> markInsightViewedDetails(Isar isar, int exposureId) async {
  await isar.writeTxn(() async {
    final exp = await isar.insightExposures.get(exposureId);
    if (exp != null && exp.viewedDetailsAt == null) {
      exp.viewedDetailsAt = DateTime.now();
      await isar.insightExposures.put(exp);
    }
  });
}

/// Call when user explicitly dismisses/swipes away the card.
Future<void> markInsightDismissed(Isar isar, int exposureId) async {
  await isar.writeTxn(() async {
    final exp = await isar.insightExposures.get(exposureId);
    if (exp != null && exp.dismissedAt == null) {
      exp.dismissedAt = DateTime.now();
      await isar.insightExposures.put(exp);
    }
  });
}
