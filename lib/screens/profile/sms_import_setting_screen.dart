import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:mudra_manager/db/models/pending_transaction.dart'
    show PendingTransaction;
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/util/string_util.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart'
    show
        TransactionInfo,
        TransactionType,
        TransactionUtil,
        checkForTransactionalMessage,
        generateSmsHash;
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

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Import Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable SMS Import', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Auto-detect transactions from SMS', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
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
          SizedBox(height: 8),
          _buildSettingCard(context, color, textTheme, Icons.sync, 'Rescan SMS Now', 'Scan recent messages for transactions', () {
            HapticFeedback.mediumImpact();
            _showSmsScanOptions(context);
          }),
          SizedBox(height: 8),
          _buildSettingCard(context, color, textTheme, Icons.clear_all, 'Clear Processing History', 'Reset SMS scan history', () {
            HapticFeedback.mediumImpact();
            SharedPrefsUtil.instance.clearProcessedHashes();
            SnackbarService.success('Processing history cleared');
          }),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.primary.withValues(alpha: 0.3))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: color.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How it Works', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                      SizedBox(height: 4),
                      Text('We scan SMS from trusted sources like banks or wallets to automatically create transactions.', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color.primary, size: 24)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showSmsScanOptions(BuildContext context) async {
    final now = DateTime.now();

    final options = {
      'This Month': DateTime(now.year, now.month, 1),
      'Last Month': DateTime(now.year, now.month - 1, 1),
      'Last 2 Months': DateTime(now.year, now.month - 2, 1),
      'Last 3 Months': DateTime(now.year, now.month - 3, 1),
    };

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children:
              options.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  onTap: () {
                    context.pop(entry.value);
                  },
                );
              }).toList(),
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Scanning your SMS...",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
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
