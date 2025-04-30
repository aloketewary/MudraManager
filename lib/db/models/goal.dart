import 'package:isar/isar.dart';
import 'account.dart'; // Import for optional linking

part 'goal.g.dart';

@collection
class Goal {
  Id id = Isar.autoIncrement; // Auto-incrementing primary key

  @Index(type: IndexType.value) // Index for easy lookup/display
  late String name; // e.g., "New Laptop", "Down Payment", "Vacation Fund"

  late double targetAmount; // The total amount the user wants to save

  // Amount currently saved.
  // IMPORTANT: This needs careful management.
  // Option 1 (Store): Store it here and update it whenever a contribution is made. Simpler display, but requires discipline in updates.
  // Option 2 (Calculate): Calculate it dynamically based on linked transactions or the balance of a linked account. More robust, but requires more complex queries/logic.
  // We define it here for model completeness, assuming Option 1 for now.
  double currentAmount = 0.0;

  DateTime? targetDate; // Optional deadline for the goal

  late DateTime creationDate; // When the goal was set up

  @Index() // Index for filtering active/completed goals
  bool isActive = true; // Mark false when completed or abandoned

  // Optional: Link to a specific account where savings for this goal are kept.
  // This is useful if you want to automatically track progress based on an account's balance increase
  // or if contributions are made specifically from/to this account.
  @Index()
  final linkedAccount = IsarLink<Account>();

  // Optional: Icon identifier or color for UI representation
  // String? iconName;
  // int? colorValue;

  // Isar requires a default constructor
  Goal();

  // Optional: Convenience constructor
  Goal.create({
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.isActive = true,
    // linkedAccount assigned after creation if needed
  }) {
    creationDate = DateTime.now(); // Set creation date automatically
  }

  // You might add helper getters for progress:
  double get progressPercent => (targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).isNegative ? 0.0 : (targetAmount - currentAmount);

}