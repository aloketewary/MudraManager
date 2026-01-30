import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Import Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable SMS Import'),
            subtitle: const Text(
              'Automatically detect and add transactions from SMS messages.',
            ),
            value: _smsImportEnabled,
            onChanged: (bool value) async {
              if (value) {
                // Request permission first
                final permission = await Permission.sms.request();
                if (permission.isGranted) {
                  setState(() {
                    _smsImportEnabled = value;
                  });
                  SharedPrefsUtil.instance.setSmsImportEnabled(value);
                  // Start listener - import from main.dart
                  await setupSmsListener();
                  if (!context.mounted) return;
                  SnackbarService.success(
                    'SMS import enabled. Financial transactions will be detected automatically.',
                  );
                } else {
                  // Show error
                  if (!context.mounted) return;
                  SnackbarService.error(
                    'SMS permission is required for automatic transaction detection',
                  );
                }
              } else {
                setState(() {
                  _smsImportEnabled = value;
                });
                SharedPrefsUtil.instance.setSmsImportEnabled(value);
                if (!context.mounted) return;
                SnackbarService.info('SMS import disabled');
              }
            },
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Rescan SMS Now'),
            subtitle: const Text(
              'Scan your recent SMS messages for transactions.',
            ),
            leading: const Icon(Icons.sync),
            onTap: () => _showSmsScanOptions(context),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Clear SMS transaction processing history'),
            subtitle: Text(
              'If scan sms not working clear this and re-scan sms again.',
            ),
            leading: const Icon(Icons.clear_all),
            onTap: () => SharedPrefsUtil.instance.clearProcessedHashes(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'How it Works:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Text(
            'We scan your SMS messages from trusted sources like banks or wallets to automatically create transactions for you.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
