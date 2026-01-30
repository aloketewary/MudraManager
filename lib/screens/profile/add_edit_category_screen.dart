import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/screens/profile/icon_picker_bottom_sheet.dart'
    show IconPickerBottomSheet;
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_color_button.dart';
import 'package:mudra_manager/screens/reusable/common_dropdown_field.dart';
import 'package:mudra_manager/screens/reusable/common_icon_button.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Category' : 'Edit Category',
          style: textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    CommonTextInputField(
                      controller: _nameController,
                      labelText: 'Category Name',
                      hintText: 'Enter category name',
                      iconData: Icons.category,
                      validateField:
                          (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    CommonDropdownField<CategoryType>(
                      value: _selectedType,
                      items: CategoryType.values,
                      labelText: 'Category Type',
                      onChanged:
                          (value) => setState(() => _selectedType = value!),
                      itemBuilder:
                          (CategoryType type) =>
                              Row(children: [Text(type.name.capitalize())]),
                    ),

                    Row(
                      children: [
                        CommonIconPickerButton(
                          label: 'Icon:',
                          selectedIcon:
                              _selectedIcon != null
                                  ? IconHelper.iconFromName(_selectedIcon!)
                                  : Icons.add,
                          onPressed: _pickIcon,
                          backgroundColor: color.onPrimary,
                          textColor: color.onPrimaryContainer,
                          iconBackGroundColor: _selectedColor,
                        ),
                        const Spacer(),
                        CommonColorPickerButton(
                          label: 'Pick Color',
                          onPressed: _pickColor,
                          backgroundColor: _selectedColor,
                          textColor: color.onPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            CommonButton(
              text: widget.existing == null ? 'save' : 'update',
              backGroundColor: color.primary,
              textColor: color.onPrimary,
              onPressed: () async {
                await _save();
                context.pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
