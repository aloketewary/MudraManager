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
import 'package:mudra_manager/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = AppColors.glassGradient(headerColor, isDark);

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
                      color: color.surface,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'TAP TO CHANGE ICON',
                  style: textTheme.labelMedium?.copyWith(
                    color: color.surface.withValues(alpha: 0.7),
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
                borderRadius: BorderRadius.vertical(top: Radius.zero),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.zero),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: headerColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter category name',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            icon: Icon(Icons.edit, color: headerColor),
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
                                    right: type == CategoryType.expense ? 0 : 8,
                                    left: type == CategoryType.income ? 0 : 8,
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
                                        gradient:
                                            isSelected
                                                ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: gradientColors,
                                                )
                                                : null,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? headerColor.withValues(
                                                    alpha: 0.3,
                                                  )
                                                  : color.outlineVariant
                                                      .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? AppColors.glassShadow(
                                                  headerColor,
                                                  isDark,
                                                )
                                                : [],
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
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: headerColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: AppColors.glassShadow(
                              headerColor,
                              isDark,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.palette, color: headerColor),
                              SizedBox(width: 12),
                              Text(
                                'TAP TO CHANGE COLOR',
                                style: textTheme.titleSmall?.copyWith(
                                  color: headerColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 48),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await _save();
                          context.pop(true);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: headerColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: AppColors.glassShadow(
                              headerColor,
                              isDark,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (widget.existing == null
                                  ? 'SAVE CATEGORY'
                                  : 'UPDATE CATEGORY'),
                              style: textTheme.titleMedium?.copyWith(
                                color: headerColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
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
