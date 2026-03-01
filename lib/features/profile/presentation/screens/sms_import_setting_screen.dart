import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';

import 'package:mudra_manager/main.dart' show setupSmsListener;

import 'package:permission_handler/permission_handler.dart';

class SmsImportSettingsScreen extends ConsumerStatefulWidget {
  const SmsImportSettingsScreen({super.key});

  @override
  ConsumerState<SmsImportSettingsScreen> createState() =>
      _SmsImportSettingsScreenState();
}

class _SmsImportSettingsScreenState
    extends ConsumerState<SmsImportSettingsScreen> {
  bool _smsImportEnabled = SharedPrefsUtil.instance.getSmsImportEnabled();
  TransactionUtil transactionUtil = TransactionUtil();
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    Permission.sms.status.then(
      (value) => {
        setState(() {
          _permissionGranted = value == PermissionStatus.granted;
        }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gradientColors = [
      color.primary.withValues(alpha: 0.1),
      color.primary.withValues(alpha: 0.05),
    ];

    if (Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Import Settings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.onSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_iphone,
                      color: color.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Not Available on iOS',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SMS import is only available on Android devices due to iOS platform restrictions.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Import Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.security, color: color.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable SMS Permission',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grant access to read SMS',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _permissionGranted,
                    onChanged: (bool value) async {
                      HapticFeedback.mediumImpact();
                      if (value) {
                        final confirmed = await _showSmsPermissionDisclosure(
                          context,
                        );
                        if (confirmed != true) return;

                        final permission = await Permission.sms.request();
                        if (permission.isGranted) {
                          setState(() => _permissionGranted = true);
                          if (!context.mounted) return;
                          SnackbarService.success('SMS permission granted');
                        } else {
                          if (!context.mounted) return;
                          SnackbarService.error('SMS permission denied');
                        }
                      } else {
                        if (!context.mounted) return;
                        SnackbarService.info(
                          'Please disable in system settings',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _permissionGranted ? 1.0 : 0.5,
            child: Card(
              elevation: 0,
              color: color.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.sms, color: color.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto Import SMS',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Auto-detect transactions from SMS',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _smsImportEnabled && _permissionGranted,
                      onChanged: !_permissionGranted
                          ? null
                          : (bool value) async {
                              HapticFeedback.mediumImpact();
                              setState(() => _smsImportEnabled = value);
                              SharedPrefsUtil.instance.setSmsImportEnabled(
                                value,
                              );
                              if (value) {
                                await setupSmsListener();
                                if (!context.mounted) return;
                                SnackbarService.success('Auto import enabled');
                              } else {
                                if (!context.mounted) return;
                                SnackbarService.info('Auto import disabled');
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _permissionGranted ? 1.0 : 0.5,
            child: _buildSettingCard(
              context,
              color,
              textTheme,
              Icons.sync,
              'Rescan SMS Now',
              'Scan recent messages for transactions',
              !_permissionGranted
                  ? () {}
                  : () {
                      HapticFeedback.mediumImpact();
                      _showSmsScanOptions(context);
                    },
              enabled: _permissionGranted,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _permissionGranted ? 1.0 : 0.5,
            child: _buildSettingCard(
              context,
              color,
              textTheme,
              Icons.clear_all,
              'Clear Processing History',
              'Reset SMS scan history',
              !_permissionGranted
                  ? () {}
                  : () {
                      HapticFeedback.mediumImpact();
                      _showClearHistoryConfirmation(context);
                    },
              enabled: _permissionGranted,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: color.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How SMS Import Works',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoPoint(
                          context,
                          '🏦',
                          'Only scans bank and wallet SMS',
                        ),
                        _buildInfoPoint(
                          context,
                          '🔒',
                          'All data stays on your device',
                        ),
                        _buildInfoPoint(
                          context,
                          '✨',
                          'Automatically creates transactions',
                        ),
                        _buildInfoPoint(
                          context,
                          '🚫',
                          'No personal messages are read',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(BuildContext context, String emoji, String text) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSmsPermissionDisclosure(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security, color: color.primary, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'SMS Permission Required',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Mudra Manager needs SMS permission to automatically detect transactions from your bank and wallet messages.',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDisclosurePoint(
                      context,
                      Icons.filter_alt,
                      'Only bank/wallet SMS are scanned',
                    ),
                    const SizedBox(height: 12),
                    _buildDisclosurePoint(
                      context,
                      Icons.phone_android,
                      'All data stays on your device',
                    ),
                    const SizedBox(height: 12),
                    _buildDisclosurePoint(
                      context,
                      Icons.block,
                      'Personal messages are never read',
                    ),
                    const SizedBox(height: 12),
                    _buildDisclosurePoint(
                      context,
                      Icons.cloud_off,
                      'No data sent to servers',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => context.pop(true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Allow Permission'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisclosurePoint(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: color.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(color: color.onSurface),
          ),
        ),
      ],
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: color.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Clear Processing History?',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: color.error, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Warning: This will rescan all SMS messages',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clearing history means previously scanned SMS will be processed again, which may create duplicate transactions.',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => context.pop(false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: color.error,
                        side: BorderSide(color: color.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      SharedPrefsUtil.instance.clearProcessedHashes();
      if (!context.mounted) return;
      SnackbarService.success('Processing history cleared');
    }
  }

  Widget _buildSettingCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showSmsScanOptions(BuildContext context) async {
    final now = DateTime.now();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final options = {
      'Today': DateTime(now.year, now.month, now.day),
      'Yesterday': DateTime(now.year, now.month, now.day - 1),
      'This Month': DateTime(now.year, now.month, 1),
      'Last Month': DateTime(now.year, now.month - 1, 1),
      'Last 2 Months': DateTime(now.year, now.month - 2, 1),
      'Last 3 Months': DateTime(now.year, now.month - 3, 1),
    };

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Scan Period',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...options.entries.map((entry) {
                return Card(
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.pop(entry.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: color.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: color.onSurfaceVariant,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((selectedStartDate) async {
      if (selectedStartDate != null && selectedStartDate is DateTime) {
        final permission = await Permission.sms.status;
        if (permission.isGranted) {
          _rescanSmsFrom(selectedStartDate);
        } else {
          await Permission.sms.request();
        }
      }
    });
  }

  void _rescanSmsFrom(DateTime startDate) async {
    final now = DateTime.now();
    int processedCount = 0;
    int scannedCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final color = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: color.primary),
                const SizedBox(height: 20),
                Text(
                  'Scanning your SMS...',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final telephony = Telephony.instance;
      final startMillis = startDate.millisecondsSinceEpoch;
      final allMessages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThanOrEqualTo(startMillis.toString()),
      );

      if (!mounted) return;

      final filteredMessages = allMessages.where((sms) {
        if (sms.date == null) return false;
        final smsDate = DateTime.fromMillisecondsSinceEpoch(sms.date!);
        return smsDate.isBefore(now);
      }).toList();

      // Process in background to prevent UI blocking
      for (var sms in filteredMessages) {
        scannedCount++;
        if (!checkForTransactionalMessage(sms.body)) continue;

        final smsHash = generateSmsHash(
          sms.address ?? '',
          sms.date,
          sms.body ?? '',
        );
        if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) continue;

        SharedPrefsUtil.instance.storeProcessedHash(smsHash);
        final transactionInfo = transactionUtil.getTransactionInfo(
          sms.body,
          sms.address,
          null,
          smsHash,
        );
        
        // Process async without awaiting to prevent blocking
        processSmsForSaving(transactionInfo);
        processedCount++;
        
        // Yield to UI every 10 messages
        if (processedCount % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Wait a bit for async processing to complete
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ref.invalidate(pendingTxnServiceProvider);
        ref.invalidate(pendingTxnDataProvider);
        ref.invalidate(transactionProvider);
      }
    } catch (e) {
      debugPrint('Error scanning SMS: $e');
      if (mounted) {
        SnackbarService.error('Failed to scan SMS');
      }
    } finally {
      if (context.mounted) context.pop();
      if (mounted) {
        _showFoundSmsMessage(processedCount);
      }
    }
  }

  void _showFoundSmsMessage(int count) {
    if (!mounted) return;
    final message = count > 0
        ? '🔎 Found $count SMS related messages!'
        : 'No SMS found for selected period.';
    SnackbarService.info(message);
  }

  void processSmsForSaving(TransactionInfo sms) async {
    if (!mounted) return;
    
    // Use the centralized SMS processor service which has auto-matching logic
    SmsProcessorService.instance.processSmsForSaving(
      sms,
      sms.transactionTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String generateSmsHash(String address, int? date, String body) {
    final input = '$address|$date|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
