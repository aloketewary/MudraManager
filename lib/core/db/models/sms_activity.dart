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

  @Index()
  late DateTime date;

  @Index()
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
  String? transactionType;
  double? balance;
  bool? isLikelyTransfer;
  int? pairedActivityId;

  @Index(unique: true, replace: true)
  late String smsHash;

  @Index()
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

  /// Currency code from SMS parser (e.g. "USD", "EUR"). Null = base currency.
  String? currencyCode;

  SmsActivity();
}
