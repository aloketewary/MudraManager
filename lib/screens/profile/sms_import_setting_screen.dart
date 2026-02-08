import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:mudra_manager/db/models/pending_transaction.dart' show PendingTransaction;
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';

import 'package:mudra_manager/util/string_util.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart' show TransactionInfo, TransactionType, TransactionUtil, checkForTransactionalMessage, generateSmsHash;
import 'package:mudra_manager/main.dart' show setupSmsListener;
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsImportSettingsScreen extends ConsumerStatefulWidget {
  const SmsImportSettingsScreen({super.key});

  @override
  ConsumerState<SmsImportSettingsScreen> createState() =>
      _SmsImportSettingsScreenState();
}

class _SmsImportSettingsScreenState
    extends ConsumerState<SmsImportSettingsScreen> {
  bool _smsImportEnabled =
      SharedPrefsUtil.instance.getSmsImportEnabled(); // Toggle for SMS Import
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = [color.primary.withValues(alpha: 0.1), color.primary.withValues(alpha: 0.05)];

    if (Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Import Settings')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.onSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Icon(Icons.phone_iphone, color: color.primary, size: 48),
                  ),
                  SizedBox(height: 20),
                  Text('Not Available on iOS', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                  SizedBox(height: 12),
                  Text('SMS import is only available on Android devices due to iOS platform restrictions.', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: color.primary.withValues(alpha: 0.75))),
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
                    child: Icon(Icons.sms, color: color.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable SMS Import',
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
                    value: _smsImportEnabled,
                    onChanged: (bool value) async {
                      HapticFeedback.mediumImpact();
                      if (value) {
                        final permission = await Permission.sms.request();
                        if (permission.isGranted) {
                          setState(() => _smsImportEnabled = value);
                          SharedPrefsUtil.instance.setSmsImportEnabled(value);
                          await setupSmsListener();
                          if (!context.mounted) return;
                          SnackbarService.success('SMS import enabled');
                        } else {
                          if (!context.mounted) return;
                          SnackbarService.error('SMS permission required');
                        }
                      } else {
                        setState(() => _smsImportEnabled = value);
                        SharedPrefsUtil.instance.setSmsImportEnabled(value);
                        if (!context.mounted) return;
                        SnackbarService.info('SMS import disabled');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            context,
            color,
            textTheme,
            Icons.sync,
            'Rescan SMS Now',
            'Scan recent messages for transactions',
            () {
              HapticFeedback.mediumImpact();
              _showSmsScanOptions(context);
            },
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            context,
            color,
            textTheme,
            Icons.clear_all,
            'Clear Processing History',
            'Reset SMS scan history',
            () {
              HapticFeedback.mediumImpact();
              SharedPrefsUtil.instance.clearProcessedHashes();
              SnackbarService.success('Processing history cleared');
            },
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
                    child: Icon(Icons.info_outline, color: color.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How it Works',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We scan SMS from trusted sources like banks or wallets to automatically create transactions.',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
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

  Widget _buildSettingCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
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
        var permission = await Permission.sms.status;
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
    // 1. Show fancy loading dialog
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
                CircularProgressIndicator(
                  color: color.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  "Scanning your SMS...",
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

    final query = SmsQuery();
    final messages = await query.getAllSms;

    if (!mounted) return;

    final filteredMessages =
        messages
            .where((sms) {
              return sms.date != null &&
                  sms.date!.isAfter(startDate) &&
                  sms.date!.isBefore(now);
            })
            .where((sms) {
              return checkForTransactionalMessage(sms.body);
            })
            .toList();

    debugPrint(
      'Found ${filteredMessages.length} SMS between $startDate and $now',
    );
    _showFoundSmsMessage(filteredMessages.length);

    // Optionally show a SnackBar or dialog to user
    if (filteredMessages.isNotEmpty) {
      for (var sms in filteredMessages) {
        var smsHash = generateSmsHash(
          sms.address ?? '',
          sms.date?.millisecondsSinceEpoch,
          sms.body ?? '',
        );
        var alreadyProcessed = SharedPrefsUtil.instance.isAlreadyProcessed(
          smsHash,
        );
        if (!alreadyProcessed) {
          SharedPrefsUtil.instance.storeProcessedHash(smsHash);
          var transactionInfo = transactionUtil.getTransactionInfo(
            sms.body,
            sms.address,
            sms.sender,
            smsHash,
          );
          processSmsForSaving(transactionInfo);
        } else {
          debugPrint("Skipping already processed SMS from ${sms.address}");
        }
      }
      ref.invalidate(pendingTxnServiceProvider);
    }

    // 2. After scanning, close progress dialog
    if (context.mounted) context.pop();
  }

  void _showFoundSmsMessage(int count) {
    if (!mounted) return;
    // You can use a SnackBar, Dialog, Toast, anything.
    // Here's a quick SnackBar example:
    final message =
        count > 0
            ? "🔎 Found $count SMS related messages!"
            : "No SMS found for selected period.";

    SnackbarService.info(message);
  }

  void processSmsForSaving(TransactionInfo sms) async {
    if (!mounted) return;
    var pendingTxnService = ref.read(pendingTxnServiceProvider);

    var pending =
        PendingTransaction()
          ..date = sms.transactionTime ?? DateTime.now()
          ..account = sms.account?.sendTo
          ..amount = sms.money?.toDouble()
          ..isIncome = sms.typeOfTransaction == TransactionType.credited
          ..body = sms.body
          ..sender = sms.sender
          ..transactionRef = sms.account?.refNo
          ..category = sms.typeOfTransaction?.name
          ..smsHash = sms.smsHash
          ..toAccount = sms.account?.type == 'UPI' ? sms.account?.sendTo : '';

    try {
      pendingTxnService.save(pending);
    } catch (exp) {
      if (!mounted) return;
      var message = 'Error saving pending transaction to database: $exp';
      SnackbarService.error(message);
    }
  }

  String generateSmsHash(String address, int? date, String body) {
    final input = '$address|$date|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
