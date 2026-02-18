import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/screens/profile/icon_picker_bottom_sheet.dart';
import 'package:mudra_manager/util/simple_color_picker.dart';
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
  late TextEditingController _descriptionController;
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
    _descriptionController = TextEditingController(text: widget.goal?.description);
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
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickIcon() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => IconPickerBottomSheet(backgroundColor: _selectedColor),
    );
    if (result != null) setState(() => _selectedIcon = result);
  }

  void _pickColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (color != null) setState(() => _selectedColor = color);
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
    goal.description = _descriptionController.text.isEmpty ? null : _descriptionController.text;

    final service = ref.read(goalServiceProvider);
    if (widget.goal == null) {
      await service.addGoal(goal);
    } else {
      await service.updateGoal(goal);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final selectedColor = _selectedColor;

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
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Goal?"),
                    content: const Text("This action cannot be undone."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.pop(false);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.pop(true);
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(goalServiceProvider).deleteGoal(widget.goal!.id);
                  if (mounted) context.pop();
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
            Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _pickIcon();
                },
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedIcon != null ? IconHelper.getIconData(_selectedIcon!) : Icons.savings,
                    size: 64,
                    color: selectedColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap to change icon',
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            const SizedBox(height: 24),
            Text(
              'Color',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _pickColor();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selectedColor, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette, color: selectedColor),
                    const SizedBox(width: 12),
                    Text(
                      'Tap to change color',
                      style: textTheme.titleSmall?.copyWith(
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
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
