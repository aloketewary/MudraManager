import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.sms_selectTransactions),
        actions: [
          FilledButton.icon(
            onPressed: _onAddSelected,
            icon: const Icon(Icons.check, size: 18),
            label: Text(ctxt.common_addLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final sms = widget.messages[index];
          final isSelected = _selectedMessages.contains(sms);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: isSelected 
                ? color.secondaryContainer 
                : color.surfaceContainerLow,
            surfaceTintColor: color.surfaceTint,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMessages.remove(sms);
                  } else {
                    _selectedMessages.add(sms);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sms.address ?? 'Unknown Sender',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? color.onSecondaryContainer 
                                  : color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sms.body?.split('\n').first ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isSelected 
                                  ? color.onSecondaryContainer.withValues(alpha: 0.8)
                                  : color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? color.secondary.withValues(alpha: 0.12)
                            : color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd MMM').format(
                          DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0),
                        ),
                        style: textTheme.labelSmall?.copyWith(
                          color: isSelected 
                              ? color.onSecondaryContainer
                              : color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onAddSelected() {
    if (_selectedMessages.isEmpty) {
      SnackbarService.warning(ctxt.sms_selectAtLeastOneMessage);
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
