import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class InvestorPack extends CategoryPack {
  static final instance = InvestorPack._();
  InvestorPack._();

  @override
  String get id => 'com.mudra.pack.investor';
  @override
  String get name => 'Investor';
  @override
  String get description => 'SIP, stocks, crypto & portfolio tracking';
  @override
  String get icon => 'trending_up';
  @override
  int get color => 0xFF4CAF50;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'SIP/Mutual Funds',
          icon: 'sip',
          color: 0xFF4CAF50,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'Stocks/Equity',
          icon: 'stocks',
          color: 0xFF2196F3,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'Fixed Deposit',
          icon: 'fixed_deposit',
          color: 0xFF795548,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'Gold/Silver',
          icon: 'gem',
          color: 0xFFFFEB3B,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'Crypto',
          icon: 'crypto',
          color: 0xFFFF9800,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'PPF/NPS',
          icon: 'ppf',
          color: 0xFF607D8B,
          type: CategoryType.income,
          parent: 'Investment',
        ),
        CategoryDef(
          name: 'Brokerage Fees',
          icon: 'commission',
          color: 0xFF9C27B0,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Demat Charges',
          icon: 'invoice',
          color: 0xFF3F51B5,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Tax on Gains',
          icon: 'tax',
          color: 0xFFF44336,
          parent: 'Bills',
        ),
      ];
}
