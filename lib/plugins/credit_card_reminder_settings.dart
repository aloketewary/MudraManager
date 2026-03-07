import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditCardReminderSettings extends StatefulWidget {
  const CreditCardReminderSettings({super.key});

  @override
  State<CreditCardReminderSettings> createState() => _CreditCardReminderSettingsState();
}

class _CreditCardReminderSettingsState extends State<CreditCardReminderSettings> {
  int _reminderDays = 1;
  List<CreditCardBill> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('credit_card_reminder_days') ?? 1;
    final billDates = prefs.getStringList('credit_card_bill_dates') ?? [];

    setState(() {
      _reminderDays = reminderDays;
      _cards = billDates.map((e) {
        final parts = e.split('|');
        return CreditCardBill(
          name: parts[0],
          billDay: int.tryParse(parts[1]) ?? 15,
        );
      }).toList();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('credit_card_reminder_days', _reminderDays);
    await prefs.setStringList(
      'credit_card_bill_dates',
      _cards.map((c) => '${c.name}|${c.billDay}').toList(),
    );
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (context) => _CardDialog(
        onSave: (name, day) {
          setState(() => _cards.add(CreditCardBill(name: name, billDay: day)));
          _saveSettings();
        },
      ),
    );
  }

  void _editCard(int index) {
    showDialog(
      context: context,
      builder: (context) => _CardDialog(
        card: _cards[index],
        onSave: (name, day) {
          setState(() => _cards[index] = CreditCardBill(name: name, billDay: day));
          _saveSettings();
        },
      ),
    );
  }

  void _deleteCard(int index) {
    setState(() => _cards.removeAt(index));
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Card Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remind me before', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Slider(
                    value: _reminderDays.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$_reminderDays day${_reminderDays > 1 ? 's' : ''}',
                    onChanged: (value) {
                      setState(() => _reminderDays = value.toInt());
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Credit Cards', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addCard,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_cards.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No credit cards added')),
              ),
            )
          else
            ..._cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: Text(card.name),
                  subtitle: Text('Bill due on ${card.billDay}${_getDaySuffix(card.billDay)} of every month'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCard(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCard(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class CreditCardBill {
  final String name;
  final int billDay;

  CreditCardBill({required this.name, required this.billDay});
}

class _CardDialog extends StatefulWidget {
  final CreditCardBill? card;
  final Function(String name, int day) onSave;

  const _CardDialog({this.card, required this.onSave});

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  late TextEditingController _nameController;
  late int _billDay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _billDay = widget.card?.billDay ?? 15;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.card == null ? 'Add Credit Card' : 'Edit Credit Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Card Name',
              hintText: 'e.g., HDFC Regalia',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Bill Day: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<int>(
                  value: _billDay,
                  isExpanded: true,
                  items: List.generate(31, (i) => i + 1)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text('$day'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _billDay = value!),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onSave(_nameController.text.trim(), _billDay);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
