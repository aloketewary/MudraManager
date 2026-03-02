import 'package:isar_community/isar.dart';

part 'sms_activity.g.dart';

enum ActivityStatus {
  pending, // Needs review
  approved, // Auto-approved or user approved
  duplicate, // Potential duplicate
  rejected, // User rejected
  needsReview, // Parsing incomplete
}

@collection
class SmsActivity {
  Id id = Isar.autoIncrement;

  late String sender;
  late String body;
  late DateTime date;
  late DateTime createdAt;

  double? amount;
  bool? isIncome;
  String? account;
  String? fromBank;
  String? toAccount;
  String? transactionRef;
  String? category;
  String? merchant;
  String? paymentType;
  String? transactionType; // UPI, Card, ATM, NEFT, etc.
  double? balance; // Available balance after transaction

  @Index(unique: true)
  late String smsHash;

  @Enumerated(EnumType.name)
  late ActivityStatus status;

  // Parsing confidence (0-100)
  int? confidence;

  // If approved, link to transaction ID
  int? transactionId;

  // Duplicate detection
  bool? isPotentialDuplicate;
  List<int>? similarActivityIds;

  // Review notes
  String? reviewNotes;

  SmsActivity();
}
