import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';

late Isar isar;
late Directory tmpDir;
late AccountsService accountsService;
late ReconciliationService reconciliationService;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('reconcile_test_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        TransactionSchema,
        CategorySchema,
        AccountSchema,
        TagSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
        TripSchema,
        TripParticipantSchema,
        TripTransactionSchema,
        SplitExpenseSchema,
        SettlementSchema,
        ReconciliationStatusSchema,
      ],
      directory: tmpDir.path,
    );

    final isarService = IsarService();
    final log = AppLog(getLogger(), 'ReconcileTest');
    accountsService = AccountsService(isarService, log);
    reconciliationService = ReconciliationService(
      isarService,
      log,
      null,
      accountsService,
    );

    // Seed a fallback category
    await isar.writeTxn(() async {
      await isar.categorys.put(
        Category()
          ..name = 'Miscellaneous'
          ..iconName = 'circle'
          ..categoryType = CategoryType.expense,
      );
      await isar.categorys.put(
        Category()
          ..name = 'Miscellaneous Income'
          ..iconName = 'circle'
          ..categoryType = CategoryType.income,
      );
    });
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  // ── Helpers ──

  Future<Account> seedAccount(
    String name,
    AccountType type, {
    double initialBalance = 0,
  }) async {
    final acc = Account()
      ..name = name
      ..accountType = type
      ..initialBalance = initialBalance
      ..isActive = true;
    await isar.writeTxn(() => isar.accounts.put(acc));
    return acc;
  }

  Future<void> addTxn(Account acc, double amount, {required bool isExpense}) async {
    final txn = Transaction.create(
      date: DateTime.now(),
      amount: amount,
      isExpense: isExpense,
    )..account.value = acc;
    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      await txn.account.save();
    });
  }

  // ── Credit Card Balance Tests ──

  group('Credit card balance calculation', () {
    test('initial outstanding + expenses increases debt', () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 5000,);
      await addTxn(cc, 500, isExpense: true);

      final balance = await accountsService.getAccountBalance(cc.id);
      expect(balance, 5500); // 5000 + 500 expense = more debt
    });

    test('payment (income) reduces credit card debt', () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 5000,);
      await addTxn(cc, 2000, isExpense: false); // payment

      final balance = await accountsService.getAccountBalance(cc.id);
      expect(balance, 3000); // 5000 - 2000 payment = less debt
    });

    test('full payment brings credit card to zero', () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 5000,);
      await addTxn(cc, 5000, isExpense: false); // full payment

      final balance = await accountsService.getAccountBalance(cc.id);
      expect(balance, 0);
    });
  });

  // ── Credit Card Reconciliation Tests ──

  group('Credit card reconciliation', () {
    test('reconcile CC with ₹5000 debt to 0 creates income (payment) adjustment',
        () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 5000,);

      // Calculated balance = 5000 (outstanding debt)
      // User says actual = 0 (paid off)
      // diff = 0 - 5000 = -5000
      // For CC: negative diff = debt decreased = income adjustment needed
      final adj = await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 0,
      );

      expect(adj, -5000);

      // Verify the adjustment transaction is income (payment)
      final txns = await isar.transactions.where().findAll();
      expect(txns.length, 1);
      expect(txns.first.isExpense, false); // income = payment
      expect(txns.first.amount, 5000);

      // Verify balance is now 0
      final newBalance = await accountsService.getAccountBalance(cc.id);
      expect(newBalance, closeTo(0, 0.01));
    });

    test('reconcile CC with ₹3000 debt to ₹5000 creates expense adjustment',
        () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 3000,);

      // Calculated = 3000, actual = 5000 (more debt than tracked)
      // diff = 5000 - 3000 = +2000
      // For CC: positive diff = debt increased = expense adjustment needed
      final adj = await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 5000,
      );

      expect(adj, 2000);

      final txns = await isar.transactions.where().findAll();
      expect(txns.length, 1);
      expect(txns.first.isExpense, true); // expense = more debt
      expect(txns.first.amount, 2000);

      final newBalance = await accountsService.getAccountBalance(cc.id);
      expect(newBalance, closeTo(5000, 0.01));
    });

    test('reconcile CC with existing transactions to 0', () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 0,);
      // Spend 3000 on CC
      await addTxn(cc, 3000, isExpense: true);
      // Pay 1000
      await addTxn(cc, 1000, isExpense: false);

      // Calculated = 0 + 3000 - 1000 = 2000 outstanding
      final calcBefore = await accountsService.getAccountBalance(cc.id);
      expect(calcBefore, 2000);

      // Reconcile to 0 (fully paid)
      final adj = await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 0,
      );

      expect(adj, -2000);

      final newBalance = await accountsService.getAccountBalance(cc.id);
      expect(newBalance, closeTo(0, 0.01));
    });

    test('reconcile CC already at correct balance is no-op', () async {
      final cc = await seedAccount('HDFC CC', AccountType.creditCard,
          initialBalance: 5000,);

      final adj = await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 5000,
      );

      expect(adj, 0);

      // No adjustment transaction created
      final txns = await isar.transactions.where().findAll();
      expect(txns, isEmpty);
    });
  });

  // ── Regular Account Reconciliation (regression) ──

  group('Regular account reconciliation', () {
    test('reconcile bank account with less money creates expense', () async {
      final bank = await seedAccount('SBI', AccountType.bank,
          initialBalance: 10000,);

      // Calculated = 10000, actual = 8000 (money missing)
      final adj = await reconciliationService.reconcileBalance(
        account: bank,
        actualBalance: 8000,
      );

      expect(adj, -2000);

      final txns = await isar.transactions.where().findAll();
      expect(txns.length, 1);
      expect(txns.first.isExpense, true); // expense = money gone
      expect(txns.first.amount, 2000);

      final newBalance = await accountsService.getAccountBalance(bank.id);
      expect(newBalance, closeTo(8000, 0.01));
    });

    test('reconcile bank account with more money creates income', () async {
      final bank = await seedAccount('SBI', AccountType.bank,
          initialBalance: 10000,);

      final adj = await reconciliationService.reconcileBalance(
        account: bank,
        actualBalance: 12000,
      );

      expect(adj, 2000);

      final txns = await isar.transactions.where().findAll();
      expect(txns.length, 1);
      expect(txns.first.isExpense, false); // income = money appeared
      expect(txns.first.amount, 2000);

      final newBalance = await accountsService.getAccountBalance(bank.id);
      expect(newBalance, closeTo(12000, 0.01));
    });

    test('reconcile bank to 0 creates expense for full amount', () async {
      final bank = await seedAccount('Cash', AccountType.cash,
          initialBalance: 5000,);

      final adj = await reconciliationService.reconcileBalance(
        account: bank,
        actualBalance: 0,
      );

      expect(adj, -5000);

      final newBalance = await accountsService.getAccountBalance(bank.id);
      expect(newBalance, closeTo(0, 0.01));
    });
  });

  // ── Double reconciliation ──

  group('Double reconciliation', () {
    test('reconcile CC twice converges to correct balance', () async {
      final cc = await seedAccount('Axis CC', AccountType.creditCard,
          initialBalance: 10000,);

      // First: reconcile to 5000
      await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 5000,
      );
      expect(
        await accountsService.getAccountBalance(cc.id),
        closeTo(5000, 0.01),
      );

      // Second: reconcile to 0
      await reconciliationService.reconcileBalance(
        account: cc,
        actualBalance: 0,
      );
      expect(
        await accountsService.getAccountBalance(cc.id),
        closeTo(0, 0.01),
      );
    });

    test('reconcile bank twice converges to correct balance', () async {
      final bank = await seedAccount('HDFC', AccountType.bank,
          initialBalance: 10000,);

      await reconciliationService.reconcileBalance(
        account: bank,
        actualBalance: 7000,
      );
      expect(
        await accountsService.getAccountBalance(bank.id),
        closeTo(7000, 0.01),
      );

      await reconciliationService.reconcileBalance(
        account: bank,
        actualBalance: 12000,
      );
      expect(
        await accountsService.getAccountBalance(bank.id),
        closeTo(12000, 0.01),
      );
    });
  });
}
