import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Audit-only guard for Task 3.
///
/// This test validates audit coverage and exception registration. It does not
/// change production behavior and never contains account values or ciphertext.
void main() {
  final audit = File(
    '.kiro/specs/encryption-decryption-data-visibility-gap/account-path-audit.md',
  ).readAsStringSync();

  const requiredPaths = <String>[
    'lib/core/db/field_encryption_service.dart',
    'lib/core/db/extensions/field_encryption_ext.dart',
    'lib/core/db/models/account.dart',
    'lib/core/db/models/account.g.dart',
    'lib/core/db/account_encryption_migration.dart',
    'lib/core/db/account_suffix_hash_migration.dart',
    'lib/core/db/encryption_migration.dart',
    'lib/core/db/signal_fields_migration.dart',
    'lib/core/db/pin_migration.dart',
    'lib/core/providers/isar_provider.dart',
    'lib/core/providers/collection_watchers.dart',
    'lib/core/providers/app_filter_chip.dart',
    'lib/core/router/app_router.dart',
    'lib/core/services/backup_restore_service.dart',
    'lib/core/services/widget_service.dart',
    'lib/core/entitlement/entitlement_service.dart',
    'lib/features/account/data/account_providers.dart',
    'lib/features/account/data/account_access_provider.dart',
    'lib/features/account/data/balance_history_provider.dart',
    'lib/features/account/data/balance_history_service.dart',
    'lib/features/account/data/investment_portfolio_service.dart',
    'lib/features/account/data/reconciliation_service.dart',
    'lib/features/account/data/low_balance_alert_plugin.dart',
    'lib/features/account/presentation/screens/add_edit_account_screen.dart',
    'lib/features/account/presentation/screens/manage_account_screen.dart',
    'lib/features/onboarding/presentation/screens/account_setup_screen.dart',
    'lib/features/dashboard/presentation/providers/dashboard_data_provider.dart',
    'lib/features/dashboard/presentation/widgets/swipeable_account_card.dart',
    'lib/features/dashboard/presentation/widgets/dashboard_account_card.dart',
    'lib/features/dashboard/presentation/widgets/dashboard_animated_card.dart',
    'lib/features/dashboard/presentation/screens/command_center_screen.dart',
    'lib/features/dashboard/presentation/screens/dashboard_home.dart',
    'lib/features/credit_card/data/credit_card_provider.dart',
    'lib/features/credit_card/presentation/screens/credit_card_bills_screen.dart',
    'lib/shared/widgets/account_selector.dart',
    'lib/shared/widgets/account_selector_bottom_sheet.dart',
    'lib/shared/widgets/account_display_card.dart',
    'lib/shared/widgets/approve_transaction_sheet.dart',
    'lib/features/transactions/presentation/widgets/add_transaction_widgets.dart',
    'lib/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart',
    'lib/features/transactions/presentation/widgets/account_card_mini.dart',
    'lib/features/transactions/presentation/screens/add_edit_transaction_screen.dart',
    'lib/features/transactions/presentation/screens/transfer_screen_new.dart',
    'lib/features/transactions/presentation/screens/add_recurring_transaction_screen.dart',
    'lib/features/transactions/data/transaction_matching_service.dart',
    'lib/features/transactions/data/pending_transaction_prodiver.dart',
    'lib/features/transactions/data/models/pending_transaction_data.dart',
    'lib/features/transactions/data/transaction_service.dart',
    'lib/features/transactions/data/transaction_provider.dart',
    'lib/features/transactions/data/transaction_query_provider.dart',
    'lib/features/transactions/data/paginated_transaction_provider.dart',
    'lib/features/transactions/data/bulk_transaction_service.dart',
    'lib/features/transactions/data/recurring_transaction_service.dart',
    'lib/features/transactions/data/recurring_transaction_provider.dart',
    'lib/features/transactions/presentation/widgets/sms_activity_card.dart',
    'lib/features/sms/data/sms_activity_service.dart',
    'lib/features/sms/data/sms_processor_service.dart',
    'lib/features/sms/data/sms_parser_manager.dart',
    'lib/features/sms/data/bank_sms_parser.dart',
    'lib/features/sms/data/notification_listener_service.dart',
    'lib/features/sms/data/category_matcher_service.dart',
    'lib/features/sms/data/tag_matcher_service.dart',
    'lib/features/sms/data/recurring_detector_service.dart',
    'lib/features/sms/presentation/screens/sms_activity_screen.dart',
    'lib/features/sms/presentation/widgets/sms_activity_card.dart',
    'lib/core/services/mudra_api_impl.dart',
    'lib/core/services/background_task_manager.dart',
    'lib/features/analytics/data/net_worth_service.dart',
    'lib/features/statistics/data/financial_context_service.dart',
    'lib/features/trip/data/trip_service.dart',
    'lib/features/notifications/data/checks/balance_drop_check.dart',
    'lib/features/notifications/data/checks/upcoming_bills_check.dart',
    'lib/features/transactions/data/bill_control_center_provider.dart',
    'lib/features/budget/data/bill_service.dart',
    'lib/core/services/google_drive_service.dart',
    'lib/core/services/auto_backup_service.dart',
    'lib/features/backup/data/account_backup.dart',
    'lib/features/backup/data/backup_data.dart',
    'lib/features/backup/data/backup_config.dart',
    'lib/features/backup/data/backable_model.dart',
    'lib/features/backup/data/backup_sync_plugin.dart',
    'lib/features/backup/data/transaction_backup.dart',
    'lib/features/backup/data/recurring_transaction_backup.dart',
    'lib/features/backup/data/pending_transaction_backup.dart',
    'lib/features/backup/data/goal_backup.dart',
    'lib/features/backup/presentation/screens/backup_restore_screen.dart',
    'lib/features/import_export/presentation/screens/import_preview_screen.dart',
    'lib/features/marketplace/screens/plugin_groups_screen.dart',
    'lib/features/profile/presentation/screens/profile_screen.dart',
  ];

  const requiredRoles = <String>['**N**', '**L**', '**U**', '**W**'];
  const requiredTasks = <String>[
    '4.1',
    '4.2',
    '4.3',
    '4.4',
    '4.5',
    '4.6',
    '4.7',
    '4.8',
    '4.9',
  ];

  test('audit artifact covers every discovered path and role', () {
    final missing =
        requiredPaths.where((path) => !audit.contains('`$path`')).toList();
    expect(missing, isEmpty);
    for (final role in requiredRoles) {
      expect(audit, contains(role));
    }
    for (final task in requiredTasks) {
      expect(audit, contains(task));
    }
  });

  test('audit registers field-free exceptions and absent inventory paths', () {
    expect(audit, contains('Link/count-only exception register'));
    expect(audit, contains('generated Isar files'));
    expect(audit, contains('category-rule `accountNumber`'));
    expect(audit, contains('no matching files exist in current checkout'));
    expect(audit, contains('must not inspect account-number content'));
    expect(audit, contains('no account `put` using returned model'));
  });

  test('audit records required decision fields without sensitive fixtures', () {
    expect(audit, contains('Data needed'));
    expect(audit, contains('Boundary + reach'));
    expect(audit, contains('Test/scope decision'));
    expect(audit, contains('UI/matching/serialization/persistence'));
    expect(audit, isNot(contains('123456789')));
    expect(audit, isNot(contains('ciphertext=')));
    expect(audit, isNot(contains('plaintext=')));
  });

  test('4.8 source guards keep L paths field-free and N/W paths contracted',
      () {
    const linkOnlyPaths = <String>[
      'lib/core/entitlement/entitlement_service.dart',
      'lib/features/account/data/balance_history_service.dart',
      'lib/features/account/data/investment_portfolio_service.dart',
      'lib/features/account/data/reconciliation_service.dart',
      'lib/features/account/data/low_balance_alert_plugin.dart',
      'lib/features/notifications/data/checks/balance_drop_check.dart',
      'lib/features/notifications/data/checks/upcoming_bills_check.dart',
      'lib/features/analytics/data/net_worth_service.dart',
      'lib/features/statistics/data/financial_context_service.dart',
      'lib/features/trip/data/trip_service.dart',
      'lib/features/transactions/data/bulk_transaction_service.dart',
    ];

    for (final path in linkOnlyPaths) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('accountNumber')), reason: path);
      expect(source, isNot(contains('accountSuffixHash')), reason: path);
      expect(source, isNot(contains('accounts.put')), reason: path);
      expect(source, isNot(contains('accounts.putAll')), reason: path);
    }

    final contractSources = <String, List<String>>{
      'lib/core/db/account_encryption_migration.dart': [
        'AccountDataContract.copyAccount',
        'resolveAccountNumberStrict',
        'redactedFailure',
      ],
      'lib/core/db/account_suffix_hash_migration.dart': [
        'AccountDataContract.copyAccount',
        'resolveAccountNumberStrict',
        'redactedFailure',
      ],
      'lib/core/services/backup_restore_service.dart': [
        'AccountBackup',
        'prepareRestoredAccount',
        'redactedFailure',
      ],
      'lib/features/backup/data/account_backup.dart': [
        'reEncrypt',
        'redactedCategory',
      ],
      'lib/core/db/models/account.dart': [
        'generic JSON output',
        "startsWith('ENC:')",
      ],
    };
    for (final entry in contractSources.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final marker in entry.value) {
        expect(source, contains(marker), reason: entry.key);
      }
    }

    final forbiddenRawErrorSnippets = <String>[
      "_log.e('Backup creation failed', e",
      "_log.e('Restore failed', e",
      "_log.w('Decrypt failed, returning raw value', e",
      "_log.e('Encrypt failed', e",
      "_log.w('Encrypt failed, storing plaintext', e",
    ];
    final sensitiveSources = <String>[
      'lib/core/db/field_encryption_service.dart',
      'lib/core/services/backup_restore_service.dart',
      'lib/features/backup/data/account_backup.dart',
    ];
    for (final path in sensitiveSources) {
      final source = File(path).readAsStringSync();
      for (final forbidden in forbiddenRawErrorSnippets) {
        expect(source, isNot(contains(forbidden)), reason: '$path: $forbidden');
      }
    }
  });

  test('audit artifact records 4.8 redaction and L guard obligations', () {
    expect(audit, contains('Redacted diagnostics'));
    expect(audit, contains('account ID and categories'));
    expect(audit, contains('Field-free L exception guards'));
    expect(audit, contains('no account `put` using returned model'));
    expect(audit, contains('no raw secret-bearing exception'));
  });
}
