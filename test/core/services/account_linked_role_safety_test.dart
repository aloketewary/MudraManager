import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:mudra_manager/features/backup/data/account_backup.dart';

void main() {
  Account storedAccount() {
    return Account()
      ..id = 42
      ..name = 'Primary'
      ..accountType = AccountType.bank
      ..initialBalance = 100
      ..currencyCode = 'INR'
      ..accountNumber = 'ENC:opaque-storage-value';
  }

  test('link projection omits account-number content', () {
    final stored = storedAccount();
    final projection = AccountLinkProjection.fromStored(stored);

    expect(projection.id, stored.id);
    expect(projection.accountType, AccountType.bank);
    expect(projection.initialBalance, 100);
    expect(projection.currencyCode, 'INR');
    expect(projection.isActive, isTrue);
    expect(projection.toString(), isNot(contains('ENC:')));
  });

  test('notification/widget text and payload redact opaque ciphertext', () {
    final text = AccountDataContract.safeOutputText(
      'Account label ENC:opaque-storage-value',
    );
    final payload = AccountDataContract.safeOutputPayload({
      'title': 'ENC:opaque-storage-value',
      'type': 'view_accounts',
      'count': 2,
    });

    expect(text, isNot(contains('ENC:')));
    expect(text, contains('••••'));
    expect(payload['title'], '••••');
    expect(payload['type'], 'view_accounts');
    expect(payload['count'], 2);
  });

  test(
      'account-linked L paths stay field-free and background N boundary awaits readiness',
      () {
    const paths = <String>[
      'lib/features/notifications/data/checks/balance_drop_check.dart',
      'lib/core/services/widget_service.dart',
      'lib/features/analytics/data/net_worth_service.dart',
      'lib/features/statistics/data/financial_context_service.dart',
      'lib/features/account/data/balance_history_service.dart',
      'lib/features/account/data/investment_portfolio_service.dart',
      'lib/core/entitlement/entitlement_service.dart',
      'lib/features/budget/data/bill_service.dart',
      'lib/features/transactions/data/bill_control_center_provider.dart',
      'lib/features/trip/data/trip_service.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('account.accountNumber')), reason: path);
      expect(source, isNot(contains('accountSuffixHash')), reason: path);
    }

    final background = File('lib/core/services/background_task_manager.dart')
        .readAsStringSync();
    expect(background, contains('FieldEncryptionService.waitForReadiness'));
    expect(background, contains("'background_task_failed'"));
    expect(background, isNot(contains('error.toString()')));
  });

  test('generic account serialization emits safe masked value', () {
    final json = storedAccount().toJson();

    expect(json['accountNumber'], '••••');
    expect(json.toString(), isNot(contains('ENC:')));
  });

  test('captured errors expose account ID and allow-listed category only', () {
    final error = AccountReadinessException('secret-from-plugin');
    final backupError = AccountBackupException('raw-account-value');
    final diagnostic = AccountDataContract.redactedFailure(
      accountId: 42,
      category: 'raw-key-material',
    );

    expect(
        error.toString(), 'Account data unavailable: account_data_unavailable');
    expect(backupError.toString(),
        'Account backup unavailable: account_data_unavailable');
    expect(diagnostic, 'accountId=42 category=account_data_unavailable');
    expect(diagnostic, isNot(contains('raw-key-material')));
    expect(diagnostic, isNot(contains('ENC:')));
  });

  test('nested captured payload values are redacted recursively', () {
    final payload = AccountDataContract.safeOutputPayload({
      'title': 'safe',
      'nested': {
        'body': 'ENC:opaque-value',
        'items': ['prefix ENC:another-value suffix'],
      },
    });

    expect(payload['title'], 'safe');
    expect(payload['nested'], {
      'body': '••••',
      'items': ['prefix •••• suffix'],
    });
    expect(payload.toString(), isNot(contains('ENC:')));
  });
}
