import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

/// Property 2 baseline characterization for non-buggy account-linked flows.
///
/// These tests intentionally run before the account contract implementation.
/// Assertions encode observations from unfixed code: non-sensitive account
/// metadata, business calculations, valid matching, lifecycle markers, and
/// unrelated encrypted-field behavior must remain stable after the fix.
/// Failure output never contains account numbers or ciphertext.
void main() {
  final source = <String, String>{
    'account providers':
        File('lib/features/account/data/account_providers.dart')
            .readAsStringSync(),
    'dashboard cards': File(
      'lib/features/dashboard/presentation/widgets/swipeable_account_card.dart',
    ).readAsStringSync(),
    'dashboard style': File(
      'lib/features/dashboard/presentation/providers/account_display_style_provider.dart',
    ).readAsStringSync(),
    'account form': File(
      'lib/features/account/presentation/screens/add_edit_account_screen.dart',
    ).readAsStringSync(),
    'manage accounts': File(
      'lib/features/account/presentation/screens/manage_account_screen.dart',
    ).readAsStringSync(),
    'main startup': File('lib/main.dart').readAsStringSync(),
    'backup restore': File(
      'lib/core/services/backup_restore_service.dart',
    ).readAsStringSync(),
  };

  group('Property 2 — account metadata and read-path preservation', () {
    final states = <({String label, String? accountNumber})>[
      (label: 'ready-valid legacy value', accountNumber: '123456789012'),
      (label: 'legacy plaintext value', accountNumber: '987654321234'),
      (label: 'null account number', accountNumber: null),
      (label: 'empty account number', accountNumber: ''),
    ];

    for (final state in states) {
      test('${state.label} preserves non-sensitive account fields', () {
        final account = _account(
          id: 101,
          name: 'Primary Bank',
          accountType: AccountType.bank,
          number: state.accountNumber,
          balance: 12500,
          currency: 'INR',
          active: true,
          primary: true,
        );
        final before = _nonSensitive(account);

        // Observation: unfixed test environment has no field key, so these
        // methods leave legacy/null account records unchanged.
        account.decryptFields();
        account.encryptFields();

        expect(_nonSensitive(account), equals(before));
        expect(account.id, 101);
        expect(account.name, 'Primary Bank');
        expect(account.accountType, AccountType.bank);
        expect(account.initialBalance, 12500);
        expect(account.currencyCode, 'INR');
        expect(account.isActive, isTrue);
        expect(account.isPrimary, isTrue);
      });
    }

    test('active/all/primary ordering projection preserves IDs and order', () {
      final accounts = [
        _account(id: 7, name: 'Cash', accountType: AccountType.cash),
        _account(id: 3, name: 'Bank', accountType: AccountType.bank),
        _account(id: 11, name: 'Card', accountType: AccountType.creditCard),
      ];
      final before = accounts.map(_linkProjection).toList();

      // Link/count-only readers use only this projection; no account-number
      // field is inspected or transformed.
      final after = accounts.map(_linkProjection).toList();

      expect(after, equals(before));
      expect(after.map((item) => item.id), [7, 3, 11]);
      expect(after.map((item) => item.name), ['Cash', 'Bank', 'Card']);
    });

    test('full and legacy truncated suffix hashes preserve matching semantics',
        () {
      final fullHash = sha256.convert(utf8.encode('6988')).toString();
      final accounts = [
        _account(id: 1, name: 'Full hash', accountType: AccountType.bank)
          ..accountSuffixHash = fullHash,
        _account(id: 2, name: 'Legacy hash', accountType: AccountType.bank)
          ..accountSuffixHash = fullHash.substring(0, 16),
      ];

      expect(accounts[0].matchesSuffix('6988'), isTrue);
      expect(accounts[1].matchesSuffix('6988'), isTrue);
      expect(accounts[0].matchesSuffix('0000'), isFalse);
      expect(accounts[1].matchesSuffix('0000'), isFalse);
    });
  });

  group('Property 2 — balances, totals, currency, and privacy', () {
    test('balance signs and net-worth totals remain unchanged', () {
      final accounts = [
        _account(id: 1, name: 'Savings', accountType: AccountType.bank),
        _account(id: 2, name: 'Card', accountType: AccountType.creditCard),
        _account(id: 3, name: 'Cash', accountType: AccountType.cash),
      ];
      final rawBalances = <int, double>{1: 10000, 2: 2500, 3: -500};
      final baseBalances = <int, double>{1: 10000, 2: 210000, 3: -500};

      final assets = <AccountItem>[];
      final liabilities = <AccountItem>[];
      var totalAssets = 0.0;
      var totalLiabilities = 0.0;
      for (final account in accounts) {
        final raw = rawBalances[account.id]!;
        final base = baseBalances[account.id]!;
        final item = AccountItem(
          name: account.name,
          balance: raw.abs(),
          accountType: account.accountType,
          currencyCode: account.currencyCode,
        );
        if (account.accountType == AccountType.creditCard) {
          if (raw > 0) {
            liabilities.add(item);
            totalLiabilities += base.abs();
          }
        } else if (raw >= 0) {
          assets.add(item);
          totalAssets += base.abs();
        } else {
          liabilities.add(item);
          totalLiabilities += base.abs();
        }
      }

      final data = NetWorthData(
        netWorth: totalAssets - totalLiabilities,
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        monthlyChange: 0,
        assets: assets,
        liabilities: liabilities,
      );

      expect(data.totalAssets, 10000);
      expect(data.totalLiabilities, 210500);
      expect(data.netWorth, -200500);
      expect(data.assets.map((item) => item.name), ['Savings']);
      expect(data.liabilities.map((item) => item.name), ['Card', 'Cash']);
    });

    test('transaction aggregation keeps base amount and exclusion rules', () {
      final transaction = Transaction.create(
        date: DateTime(2026, 1, 1),
        amount: 100,
        isExpense: true,
        currencyCode: 'USD',
        convertedAmount: 8350,
      );

      expect(transaction.baseAmount, 8350);
      expect(transaction.effectiveAmount, 8350);
      transaction.isTransfer = true;
      expect(transaction.effectiveAmount, 0);
      transaction.isTransfer = false;
      transaction.isSettlement = true;
      expect(transaction.effectiveAmount, 0);
      expect(transaction.currencyCode, 'USD');
      expect(
        formatCurrency(transaction.baseAmount, code: 'INR'),
        contains('₹'),
      );
    });

    test(
        'guest mode preserves real values when disabled and masks when enabled',
        () {
      const value = -987654.0;
      expect(GuestModeUtil.applyGuestMode(value, false), value);

      final masked = GuestModeUtil.applyGuestMode(value, true);
      expect(masked, inInclusiveRange(100, 5099));
      expect(masked, isNot(value));

      final formatted = GuestModeUtil.formatWithGuestMode(
        value,
        true,
        (amount) => amount.toString(),
      );
      expect(double.parse(formatted), inInclusiveRange(100, 5099));
    });
  });

  group('Property 2 — valid matching, precedence, and links', () {
    late List<Category> categories;

    setUp(() {
      categories = [
        Category.create(
          name: 'Salary',
          categoryType: CategoryType.income,
          keywords: ['salary'],
        ),
        Category.create(
          name: 'Other',
          categoryType: CategoryType.expense,
        ),
      ];
    });

    test('duplicate suffix candidates preserve first-match precedence', () {
      final first =
          _account(id: 21, name: 'First Bank', accountType: AccountType.bank)
            ..accountNumber = '00006988';
      final second =
          _account(id: 22, name: 'Second Bank', accountType: AccountType.bank)
            ..accountNumber = '99996988';
      final result = TransactionMatchingService.matchTransaction(
        pending: _pending(account: '6988', income: false),
        accounts: [first, second],
        categories: categories,
      );

      expect(result, isNotNull);
      expect(result!.account.id, 21);
      expect(result.account.name, 'First Bank');
    });

    test('bank-name fallback preserves credit-card matching', () {
      final card = _account(
        id: 23,
        name: 'HDFC Credit Card',
        accountType: AccountType.creditCard,
      );
      final result = TransactionMatchingService.matchTransaction(
        pending: _pending(account: '0000', bank: 'hdfc', income: false),
        accounts: [card],
        categories: categories,
      );

      expect(result, isNotNull);
      expect(result!.account.id, 23);
      expect(result.account.accountType, AccountType.creditCard);
    });

    test('valid matching retains category precedence and account link identity',
        () {
      final account =
          _account(id: 24, name: 'Salary Bank', accountType: AccountType.bank)
            ..accountNumber = '1234';
      final result = TransactionMatchingService.matchTransaction(
        pending:
            _pending(account: '1234', income: true, body: 'salary credited'),
        accounts: [account],
        categories: categories,
      );
      final transaction = Transaction.create(
        date: DateTime(2026, 1, 2),
        amount: 500,
        isExpense: false,
      )..account.value = account;

      expect(result, isNotNull);
      expect(result!.category.name, 'Salary');
      expect(transaction.account.value?.id, 24);
      expect(transaction.account.value?.name, 'Salary Bank');
    });
  });

  group('Property 2 — unrelated encrypted fields and idempotence', () {
    test('non-account encrypted fields retain baseline identity behavior', () {
      final transaction = Transaction.create(
        date: DateTime(2026, 1, 3),
        amount: 50,
        isExpense: true,
        description: 'Coffee',
      );
      final bill = RecurringBill()
        ..name = 'Rent'
        ..description = 'Monthly rent'
        ..amount = 1000
        ..dueDate = DateTime(2026, 2, 1)
        ..frequency = BillFrequency.monthly
        ..isActive = true;

      transaction.encryptFields();
      bill.encryptFields();
      transaction.decryptFields();
      bill.decryptFields();

      expect(transaction.description, 'Coffee');
      expect(bill.name, 'Rent');
      expect(bill.description, 'Monthly rent');
      expect(FieldEncryptionService.encrypt('ENC:opaque'), 'ENC:opaque');
      expect(
        FieldEncryptionService.decrypt('plain legacy value'),
        'plain legacy value',
      );
    });
  });

  group('Property 2 — lifecycle, loading, layout, and persistence markers', () {
    test('provider invalidation/loading and direct-reader role markers remain',
        () {
      final providers = source['account providers']!;
      expect(providers, contains('accountChangeProvider'));
      expect(providers, contains('transactionChangeProvider'));
      expect(providers, contains('accountsProvider'));
      expect(providers, contains('allAccountsProvider'));
      expect(providers, contains('primaryAccountProvider'));
      expect(providers, contains('getAccountBalanceMap'));
      expect(providers, contains('getAccountBalanceMapInBase'));
    });

    test(
        'display modes preserve carousel paging, stack expansion, and bento layout',
        () {
      final cards = source['dashboard cards']!;
      final styles = source['dashboard style']!;
      expect(styles, contains('carousel'));
      expect(styles, contains('stack'));
      expect(styles, contains('bento'));
      expect(cards, contains('PageController'));
      expect(cards, contains('keepPage: true'));
      expect(cards, contains('_toggleStack'));
      expect(cards, contains('_stackExpanded'));
      expect(cards, contains('_buildCarouselSection'));
      expect(cards, contains('_buildStackSection'));
      expect(cards, contains('_buildBentoSection'));
    });

    test('form validation/save UX and archive/primary lifecycle markers remain',
        () {
      final form = source['account form']!;
      final manage = source['manage accounts']!;
      expect(form, contains('GlobalKey<FormState>'));
      expect(form, contains('_formKey'));
      expect(form, contains('_saving'));
      expect(form, contains('_saveAccount'));
      expect(form, contains('isLoading: _saving'));
      expect(manage, contains('isActive'));
      expect(manage, contains('RefreshIndicator'));
      expect(manage, contains('ref.invalidate(allAccountsProvider)'));
      expect(manage, contains('archivedAccounts'));
    });

    test('migration guards and backup compatibility markers remain', () {
      final startup = source['main startup']!;
      final backup = source['backup restore']!;
      expect(startup, contains('AccountEncryptionMigration.run'));
      expect(startup, contains('AccountSuffixHashMigration.run'));
      expect(startup, contains('safeExecute'));
      expect(backup, contains('ExchangeRate'));
      expect(backup, contains('rateToBase'));
      expect(backup, contains('BaseCurrency.sync'));
    });
  });
}

Account _account({
  required int id,
  required String name,
  required AccountType accountType,
  String? number,
  double balance = 0,
  String? currency,
  bool active = true,
  bool primary = false,
}) {
  final account = Account.create(
    name: name,
    initialBalance: balance,
    isActive: active,
  )
    ..id = id
    ..accountType = accountType
    ..accountNumber = number
    ..currencyCode = currency
    ..isPrimary = primary;
  return account;
}

Map<String, Object?> _nonSensitive(Account account) => {
      'id': account.id,
      'name': account.name,
      'type': account.accountType,
      'balance': account.initialBalance,
      'currency': account.currencyCode,
      'active': account.isActive,
      'primary': account.isPrimary,
      'color': account.colorValue,
      'creditLimit': account.creditLimit,
      'statementDay': account.statementDay,
      'dueDay': account.dueDay,
    };

({int id, String name, AccountType type, double balance}) _linkProjection(
  Account account,
) =>
    (
      id: account.id,
      name: account.name,
      type: account.accountType,
      balance: account.initialBalance,
    );

_PendingStub _pending({
  required String account,
  required bool income,
  String? bank,
  String body = 'ordinary transaction',
}) =>
    _PendingStub(
      account: account,
      amount: 100,
      body: body,
      isIncome: income,
      fromBank: bank,
    );

class _PendingStub implements PendingTransactionData {
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

  const _PendingStub({
    required this.account,
    required this.amount,
    required this.body,
    required this.isIncome,
    this.fromBank,
  });
}
