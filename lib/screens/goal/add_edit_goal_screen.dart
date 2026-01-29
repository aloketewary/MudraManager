import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/util/icon_helper.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _currentAmountController;
  DateTime? _targetDate;
  String _selectedIcon = 'savings';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name);
    _amountController = TextEditingController(
      text: widget.goal?.targetAmount.toString(),
    );
    _currentAmountController = TextEditingController(
      text: widget.goal?.currentAmount.toString(),
    );
    _targetDate = widget.goal?.targetDate;
    _selectedIcon = widget.goal?.iconName ?? 'savings';
    if (widget.goal?.colorValue != null) {
      _selectedColor = Color(widget.goal!.colorValue!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final goal = widget.goal ?? Goal();
    goal.name = _nameController.text;
    goal.targetAmount = double.parse(_amountController.text);
    goal.currentAmount = double.parse(
      _currentAmountController.text.isEmpty
          ? '0'
          : _currentAmountController.text,
    );
    goal.targetDate = _targetDate;
    goal.iconName = _selectedIcon;
    goal.colorValue = _selectedColor.value;

    final service = ref.read(goalServiceProvider);
    if (widget.goal == null) {
      await service.addGoal(goal);
    } else {
      await service.updateGoal(goal);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.goal == null ? "Add Goal" : "Edit Goal",
          style: textTheme.titleLarge,
        ),
        actions: [
          if (widget.goal != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Delete Goal?"),
                        content: const Text("This action cannot be undone."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                );
                if (confirmed == true) {
                  await ref
                      .read(goalServiceProvider)
                      .deleteGoal(widget.goal!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Goal Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Target Amount",
                border: OutlineInputBorder(),
                prefixText: "₹",
              ),
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      v == null || double.tryParse(v) == null
                          ? "Invalid"
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentAmountController,
              decoration: const InputDecoration(
                labelText: "Current Savings",
                border: OutlineInputBorder(),
                prefixText: "₹",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Target Date"),
              subtitle: Text(
                _targetDate == null
                    ? "Not set"
                    : DateFormat.yMMMd(ctxt.localeName).format(_targetDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            const SizedBox(height: 16),
            const Text("Select Icon"),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                      'savings',
                      'home',
                      'directions_car',
                      'flight',
                      'laptop',
                      'school',
                      'travel',
                      'entertainment',
                    ].map((icon) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _selectedIcon == icon
                                    ? color.primaryContainer
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  _selectedIcon == icon
                                      ? color.primary
                                      : color.outline,
                            ),
                          ),
                          child: Icon(
                            IconHelper.getIconData(icon),
                            color:
                                _selectedIcon == icon
                                    ? color.primary
                                    : color.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Select Color"),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    Colors.primaries.map((c) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: Border.all(
                              color:
                                  _selectedColor == c
                                      ? Colors.black
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveGoal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: color.primary,
                foregroundColor: color.onPrimary,
              ),
              child: const Text("Save Goal"),
            ),
          ],
        ),
      ),
    );
  }
}
