import 'package:isar/isar.dart';
import 'category.dart'; // Import for linking
import 'account.dart';  // Import for linking
import 'frequency.dart';   // Import Frequency enum

part 'recurring_transaction.g.dart';

@collection
class RecurringTransaction {
  Id id = Isar.autoIncrement;

  late double amount; // Amount for each occurrence
  late bool isExpense; // Income or Expense?
  String? description; // Description for each generated transaction

  @enumerated // Store the enum value
  late Frequency frequency; // How often it recurs

  @Index() // Index for querying by start date
  late DateTime startDate; // When the recurrence begins

  DateTime? endDate; // Optional: When the recurrence ends

  @Index() // Essential for finding transactions due to be generated
  late DateTime nextDueDate; // The date the *next* transaction should be created

  // Links to the default category and account for generated transactions
  @Index()
  final category = IsarLink<Category>();

  @Index()
  final account = IsarLink<Account>();

  // Flag to indicate if this recurrence is still active
  bool isActive = true;

  // Isar requires a default constructor
  RecurringTransaction();

  // Optional: Convenience constructor
  RecurringTransaction.create({
    required this.amount,
    required this.isExpense,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    // nextDueDate is typically calculated based on startDate and frequency initially
    // category and account links assigned after creation
    this.isActive = true,
  }) {
    // Initial calculation for nextDueDate (example)
    // More robust calculation needed based on frequency
    nextDueDate = calculateNextDueDate(startDate, frequency, startDate);
  }

// Note: You will need application logic to:
// 1. Periodically check for RecurringTransactions where `nextDueDate` is past or present.
// 2. Generate a new `Transaction` record based on the template data.
// 3. Update the `nextDueDate` of this RecurringTransaction template.
// 4. Potentially deactivate it if `endDate` is reached.
}


// Helper function (example - needs refinement for edge cases like month ends)
// This should ideally live in a service/logic class, not directly in the model file.
DateTime calculateNextDueDate(DateTime currentDueDate, Frequency frequency, DateTime startDate) {
  if (currentDueDate.isBefore(startDate)) {
    return startDate; // Ensure first due date isn't before start date
  }
  switch (frequency) {
    case Frequency.daily:
      return currentDueDate.add(Duration(days: 1));
    case Frequency.weekly:
      return currentDueDate.add(Duration(days: 7));
    case Frequency.monthly:
    // Basic calculation - careful with month lengths! Libraries like `intl` or `jiffy` can help.
      return DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
    case Frequency.yearly:
      return DateTime(currentDueDate.year + 1, currentDueDate.month, currentDueDate.day);
  }
}