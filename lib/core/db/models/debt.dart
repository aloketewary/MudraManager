import 'package:isar_community/isar.dart';

part 'debt.g.dart';

/// A single debt entry (credit card, loan, EMI) tracked for payoff planning.
@collection
class Debt {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String name;

  late double balance;
  late double minimumPayment;

  /// Annual percentage rate.
  late double interestRate;

  /// Additional amount the user commits to pay each month, on top of
  /// [minimumPayment]. Null/0 = minimum only.
  double? extraPayment;

  String? iconName;
  int? colorValue;

  @Index()
  bool isActive = true;

  DateTime creationDate = DateTime.now();

  Debt();

  Debt.create({
    required this.name,
    required this.balance,
    required this.minimumPayment,
    required this.interestRate,
    this.extraPayment,
    this.iconName = 'debt',
    this.colorValue,
    this.isActive = true,
  });

  double get totalPayment => minimumPayment + (extraPayment ?? 0);

  bool get isPaid => balance <= 0;

  double get monthlyInterest => balance * (interestRate / 100 / 12);
}

/// Strategy used to order debts for payoff.
enum DebtSortOrder {
  balanceAscending, // Snowball: smallest balance first
  balanceDescending, // Avalanche: highest interest first
}
