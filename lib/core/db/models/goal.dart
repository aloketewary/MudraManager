import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/features/goal/domain/goal_enums.dart';
import 'account.dart'; // Import for optional linking

part 'goal.g.dart';

@embedded
@JsonSerializable()
class GoalContribution {
  double amount = 0.0;
  DateTime date = DateTime.now();

  GoalContribution();

  factory GoalContribution.create(double amount) => GoalContribution()
    ..amount = amount
    ..date = DateTime.now();

  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      _$GoalContributionFromJson(json);
  Map<String, dynamic> toJson() => _$GoalContributionToJson(this);
}

@collection
@JsonSerializable()
class Goal {
  Id id = Isar.autoIncrement; // Auto-incrementing primary key

  @Index(type: IndexType.value) // Index for easy lookup/display
  late String name; // e.g., "New Laptop", "Down Payment", "Vacation Fund"

  late double targetAmount; // The total amount the user wants to save

  /// Currency code for this goal. Null = base currency.
  String? currencyCode;

  // Amount currently saved.
  // IMPORTANT: This needs careful management.
  // Option 1 (Store): Store it here and update it whenever a contribution is made. Simpler display, but requires discipline in updates.
  // Option 2 (Calculate): Calculate it dynamically based on linked transactions or the balance of a linked account. More robust, but requires more complex queries/logic.
  // We define it here for model completeness, assuming Option 1 for now.
  double currentAmount = 0.0;

  DateTime? targetDate; // Optional deadline for the goal

  /// Last contribution date — updated on each deposit for efficient querying
  DateTime? lastContributionDate;

  DateTime creationDate = DateTime.now(); // When the goal was set up

  @Index() // Index for filtering active/completed goals
  bool isActive = true; // Mark false when completed or abandoned

  // Optional: Link to a specific account where savings for this goal are kept.
  // This is useful if you want to automatically track progress based on an account's balance increase
  // or if contributions are made specifically from/to this account.
  @Index()
  final linkedAccount = IsarLink<Account>();

  String? iconName;
  int? colorValue;
  String? description;

  @enumerated
  GoalType goalType = GoalType.custom;

  @enumerated
  GoalPriority priority = GoalPriority.important;

  List<GoalContribution> contributions = [];

  Goal();

  // Optional: Convenience constructor
  Goal.create({
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.isActive = true,
    // linkedAccount assigned after creation if needed
  });

  // You might add helper getters for progress:
  double get progressPercent =>
      (targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount =>
      (targetAmount - currentAmount).isNegative
          ? 0.0
          : (targetAmount - currentAmount);

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
  Map<String, dynamic> toJson() => _$GoalToJson(this);
}
