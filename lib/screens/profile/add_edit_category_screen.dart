import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final headerColor = _selectedColor ?? color.primary;

    return Scaffold(
      backgroundColor: headerColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          widget.existing == null ? 'Add Category' : 'Edit Category',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _pickIcon();
                  },
                  child: Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedIcon != null
                          ? IconHelper.iconFromName(_selectedIcon!)
                          : Icons.category,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'TAP TO CHANGE ICON',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 32,
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    children: [
                      Text(
                        'Category Name',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: color.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter category name',
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.edit,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          validator:
                              (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Category Type',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children:
                            CategoryType.values.map((type) {
                              final isSelected = _selectedType == type;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: type == CategoryType.expense ? 8 : 0,
                                    left: type == CategoryType.income ? 8 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() => _selectedType = type);
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? headerColor.withValues(
                                                  alpha: 0.1,
                                                )
                                                : color.surfaceContainer,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? headerColor
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            type == CategoryType.expense
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            color:
                                                isSelected
                                                    ? headerColor
                                                    : color.onSurfaceVariant,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            type.name.capitalize(),
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                  color:
                                                      isSelected
                                                          ? headerColor
                                                          : color
                                                              .onSurfaceVariant,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Color',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _pickColor();
                        },
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                headerColor.withValues(alpha: 0.8),
                                headerColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: headerColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.palette, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'TAP TO CHANGE COLOR',
                                style: textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 48),
                      FilledButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await _save();
                          context.pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: headerColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          minimumSize: Size(double.infinity, 52),
                        ),
                        child: Text(
                          (widget.existing == null
                              ? 'SAVE CATEGORY'
                              : 'UPDATE CATEGORY'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
