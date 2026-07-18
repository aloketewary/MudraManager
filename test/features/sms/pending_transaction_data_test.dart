import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

/// Test implementation of PendingTransactionData
class TestPendingData implements PendingTransactionData {
  @override
  final String? account;
  @override
  final double? amount;
  @override
  final bool? isIncome;
  @override
  final String body;
  @override
  final String? fromBank;
  @override
  final String? toAccount;

  TestPendingData({
    this.account,
    this.amount,
    this.isIncome,
    required this.body,
    this.fromBank,
    this.toAccount
  });
}

void main() {
  group('PendingTransactionData interface', () {
    test('TestPendingData implements PendingTransactionData', () {
      final data = TestPendingData(
        account: '1234',
        amount: 500.0,
        isIncome: false,
        body: 'test sms',
        fromBank: 'HDFC',
      );

      expect(data, isA<PendingTransactionData>());
      expect(data.account, '1234');
      expect(data.amount, 500.0);
      expect(data.isIncome, false);
      expect(data.body, 'test sms');
      expect(data.fromBank, 'HDFC');
    });

    test('TransactionMatchingService accepts PendingTransactionData', () {
      final account = Account()
        ..name = 'Test Account'
        ..accountNumber = 'XXXX5678'
        ..accountType = AccountType.bank
        ..isActive = true;

      final category = db_category.Category()
        ..name = 'Others'
        ..categoryType = db_category.CategoryType.expense
        ..keywords = ['others'];

      final pending = TestPendingData(
        account: '5678',
        amount: 100.0,
        isIncome: false,
        body: 'Rs.100 debited from A/c XX5678',
      );

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: [account],
        categories: [category],
      );

      expect(result, isNotNull);
      expect(result!.account.name, 'Test Account');
      expect(result.category.name, 'Others');
    });

    test('null fields are handled gracefully', () {
      final pending = TestPendingData(
        account: null,
        amount: null,
        isIncome: null,
        body: 'some text',
        fromBank: null,
      );

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: [],
        categories: [],
      );

      expect(result, isNull);
    });
  });
}
