import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/screens/profile/icon_picker_bottom_sheet.dart'
    show IconPickerBottomSheet;
import 'package:mudra_manager/components/adaptive_text.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/simple_color_picker.dart'
    show SimpleColorPickerDialog;

final _formKey = GlobalKey<FormState>();

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? existing;

  const AddEditCategoryScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  late TextEditingController _nameController;
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedIcon;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedType = widget.existing?.categoryType ?? CategoryType.expense;
    _selectedIcon = widget.existing?.iconName;
    _selectedColor =
        widget.existing?.colorValue != null
            ? Color(widget.existing!.colorValue!)
            : Colors.blue;
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isar = await ref.read(isarServiceProvider).getInstance();

    final category = widget.existing ?? Category();
    category.name = _nameController.text.trim();
    category.categoryType = _selectedType;
    category.iconName = _selectedIcon;
    category.colorValue = _selectedColor?.toARGB32();

    await isar.writeTxn(() => isar.categorys.put(category));
    ref.invalidate(categoryListProvider);
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    final selectedColor = _selectedColor ?? color.primary;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: AdaptiveText(
          widget.existing == null ? ctxt.category_addTitle : ctxt.category_editTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
                    _selectedIcon != null
                        ? IconHelper.iconFromName(_selectedIcon!)
                        : Icons.category,
                    size: 64,
                    color: selectedColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                ctxt.category_tapToChangeIcon,
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: ctxt.category_nameLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? ctxt.category_nameRequired : null,
            ),
            const SizedBox(height: 24),
            Text(
              ctxt.category_typeLabel,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(ctxt.category_expenseLabel),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(ctxt.category_incomeLabel),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<CategoryType> selected) {
                HapticFeedback.mediumImpact();
                setState(() => _selectedType = selected.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              ctxt.category_colorLabel,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                      ctxt.category_tapToChangeColor,
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
            FilledButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await _save();
                if (mounted) context.pop(true);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                (widget.existing == null ? ctxt.category_saveButton : ctxt.category_updateButton),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
