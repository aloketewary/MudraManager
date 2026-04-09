import 'package:isar_community/isar.dart';

part 'category_rule.g.dart';

@collection
class CategoryRule {
  Id id = Isar.autoIncrement;

  // Matching criteria
  String? recipientName; // UPI recipient like "SUKANTA BEHERA"
  String? merchantName; // Bank/wallet name like "Swiggy", "Zomato"
  String? accountNumber; // Last 4 digits like "6988"
  double? amountMin; // For amount range matching
  double? amountMax;

  // Category assignment
  @Index()
  String categoryId; // Link to category

  // Learning metrics
  int matchCount = 1; // How many times this rule matched
  late DateTime lastUsed;
  int confidence = 50; // Confidence score (0-100)

  CategoryRule({
    this.recipientName,
    this.merchantName,
    this.accountNumber,
    this.amountMin,
    this.amountMax,
    required this.categoryId,
    this.matchCount = 1,
    this.confidence = 50,
  }) {
    lastUsed = DateTime.now();
  }
}
