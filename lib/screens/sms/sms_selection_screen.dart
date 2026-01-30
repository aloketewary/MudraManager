import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:telephony/telephony.dart';

class SmsSelectionScreen extends StatefulWidget {
  final List<SmsMessage> messages;
  const SmsSelectionScreen({super.key, required this.messages});

  @override
  _SmsSelectionScreenState createState() => _SmsSelectionScreenState();
}

class _SmsSelectionScreenState extends State<SmsSelectionScreen> {
  final Set<SmsMessage> _selectedMessages = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onAddSelected,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final sms = widget.messages[index];
          final isSelected = _selectedMessages.contains(sms);
          return ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedMessages.add(sms);
                  } else {
                    _selectedMessages.remove(sms);
                  }
                });
              },
            ),
            title: Text(sms.address ?? 'Unknown Sender'),
            subtitle: Text(
              sms.body?.split('\n').first ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              DateFormat('dd MMM').format(
                DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0),
              ),
              style: TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  void _onAddSelected() {
    if (_selectedMessages.isEmpty) {
      SnackbarService.warning("Please select at least one SMS");
      return;
    }

    // Here map your selected SMS to your Transaction model
    final transactions = _selectedMessages.map((sms) {
      return Transaction.create(
        amount: _parseAmount(sms.body),
        date: DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0),
        description: sms.body ?? '',
        isExpense: true,
      );
    }).toList();

    // Now save transactions to DB (Isar or whatever you use)
    // saveTransactions(transactions);

    context.pop(); // Back to home
  }

  double _parseAmount(String? body) {
    if (body == null) return 0;
    final regex = RegExp(r'(\d+[.,]?\d*)');
    final match = regex.firstMatch(body);
    if (match != null) {
      return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }
}
