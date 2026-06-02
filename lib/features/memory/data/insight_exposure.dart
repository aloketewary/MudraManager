import 'package:isar_community/isar.dart';

part 'insight_exposure.g.dart';

/// Tracks the lifecycle of a single insight shown to the user.
/// Enables experiment evaluation: CTR, dismiss rate, per-user metrics, segmentation.
@collection
class InsightExposure {
  Id id = Isar.autoIncrement;

  /// Type of insight (e.g. "spending_drift")
  @Index()
  late String insightType;

  /// Deduplication key: "drift:{month}:{categoryId}:{variant}"
  /// Prevents duplicate records when provider rebuilds.
  @Index(unique: true, replace: false)
  late String fingerprint;

  /// Category involved (if applicable)
  int? categoryId;

  /// A/B variant: 'trend' or 'consequence'
  @Index()
  late String variant;

  /// Financial impact in ₹/year (for segmentation by magnitude)
  double? impactAmount;

  /// Raw percent change detected (for segmentation)
  double? percentChange;

  /// Number of months of data used for this detection
  int? monthsObserved;

  /// Device user identifier (for per-user CTR calculation)
  @Index()
  String? userId;

  /// The exact headline shown
  String? headline;

  /// When the insight was computed by the detector
  late DateTime generatedAt;

  /// When the card was actually rendered on screen (set by widget layer ONLY)
  DateTime? displayedAt;

  /// When user tapped the insight card
  DateTime? clickedAt;

  /// When user navigated to the detail screen after clicking
  DateTime? viewedDetailsAt;

  /// When user explicitly dismissed/swiped away the card
  DateTime? dismissedAt;

  /// What action the user took (e.g. "navigated_to_statistics")
  String? actionTaken;

  InsightExposure();

  InsightExposure.create({
    required this.insightType,
    required this.fingerprint,
    required this.variant,
    required this.generatedAt,
    this.categoryId,
    this.headline,
    this.impactAmount,
    this.percentChange,
    this.monthsObserved,
    this.userId,
  });

  bool get wasDisplayed => displayedAt != null;
  bool get wasClicked => clickedAt != null;
  bool get wasDismissed => dismissedAt != null;
  bool get viewedDetails => viewedDetailsAt != null;
}
