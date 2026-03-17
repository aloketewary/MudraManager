import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/icon_picker_bottom_sheet.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? existing;

  const AddEditCategoryScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _keywordsController;
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedIcon;
  late Color _selectedColor;
  Category? _selectedParent;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static const _quickColors = [
    Color(0xFFE53935),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _keywordsController = TextEditingController(
      text: widget.existing?.keywords?.join(', ') ?? '',
    );
    _selectedType = widget.existing?.categoryType ?? CategoryType.expense;
    _selectedIcon = widget.existing?.iconName;
    _selectedColor = widget.existing?.colorValue != null
        ? Color(widget.existing!.colorValue!)
        : const Color(0xFF2196F3);
    _loadParentCategory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _loadParentCategory() async {
    if (widget.existing != null) {
      await widget.existing!.parentCategory.load();
      if (mounted) {
        setState(() => _selectedParent = widget.existing!.parentCategory.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: Text(
          _isEditing ? ctxt.category_editTitle : ctxt.category_addTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _save();
                  },
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.primary,
                    ),
                  )
                : Text(
                    _isEditing ? 'UPDATE' : 'SAVE',
                    style: textTheme.titleSmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: [
            // ── HERO PREVIEW ──
            _buildHeroPreview(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),

            // ── TYPE ──
            _sectionLabel(ctxt.category_typeLabel, textTheme),
            SizedBox(height: spacing.sectionGap),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(ctxt.category_expenseLabel),
                  icon: const Icon(LucideIcons.arrowUpRight, size: 18),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(ctxt.category_incomeLabel),
                  icon: const Icon(LucideIcons.arrowDownLeft, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selected) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedType = selected.first;
                  _selectedParent = null;
                });
              },
            ),
            SizedBox(height: spacing.sectionGap),

            // ── DETAILS ──
            _sectionLabel('Details', textTheme),
            SizedBox(height: spacing.sectionGap),
            _buildDetailsCard(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),

            // ── PARENT CATEGORY ──
            _sectionLabel('Parent Category', textTheme),
            SizedBox(height: spacing.sectionGap),
            _buildParentPicker(color, textTheme),
            SizedBox(height: spacing.sectionGap),

            // ── COLOR ──
            _sectionLabel(ctxt.category_colorLabel, textTheme),
            SizedBox(height: spacing.sectionGap),
            _buildColorSection(color, textTheme),
            SizedBox(height: spacing.sectionGap),
          ],
        ),
      ),
    );
  }

  // ── HERO PREVIEW ──
  Widget _buildHeroPreview(
      ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    final name = _nameController.text.trim();
    final iconData = _selectedIcon != null
        ? IconHelper.iconFromName(_selectedIcon!)
        : LucideIcons.tag;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _pickIcon();
      },
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _selectedColor.withValues(alpha: 0.2),
              _selectedColor.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _selectedColor.withValues(alpha: 0.18),
                      _selectedColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child:
                      Icon(iconData, size: 28, color: color.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Category Name' : name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: name.isEmpty
                              ? color.onSurfaceVariant.withValues(alpha: 0.8)
                              : color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedType.name.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: _selectedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_selectedParent != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.folderOpen,
                              size: 12,
                              color: color.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedParent!.name,
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change icon',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── DETAILS CARD ──
  Widget _buildDetailsCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Category Name',
              prefixIcon: Icon(
                LucideIcons.pencil,
                size: 18,
                color: _selectedColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: textTheme.bodyLarge,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          Divider(
            height: 1,
            indent: 48,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          SizedBox(height: spacing.elementGap),
          TextFormField(
            controller: _keywordsController,
            decoration: InputDecoration(
              hintText: 'Keywords (comma-separated)',
              helperText: 'For SMS auto-detection (e.g. swiggy, zomato)',
              helperStyle: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                LucideIcons.tag,
                size: 18,
                color: _selectedColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  // ── PARENT CATEGORY PICKER ──
  Widget _buildParentPicker(ColorScheme color, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticFeedback.lightImpact();
          final categories = await ref.read(categoryListProvider.future);
          final filtered = categories.where((c) {
            if (c.categoryType != _selectedType) return false;
            if (c.id == widget.existing?.id) return false;
            c.parentCategory.loadSync();
            return c.parentCategory.value == null;
          }).toList();
          if (!mounted) return;
          final selected = await showModalBottomSheet<Category?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: color.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _ParentCategoryPicker(
              categories: filtered,
              selected: _selectedParent,
            ),
          );
          if (selected != null) {
            setState(() {
              _selectedParent =
                  selected.id == Isar.autoIncrement ? null : selected;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                LucideIcons.folderOpen,
                size: 18,
                color: _selectedColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _selectedParent?.name ?? 'None (Top-level)',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _selectedParent != null
                        ? color.onSurface
                        : color.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (_selectedParent != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedParent = null);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: color.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── COLOR SECTION ──
  Widget _buildColorSection(ColorScheme color, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickColors.map((c) {
                  final isSelected = _selectedColor.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedColor = c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: color.onSurface,
                                width: 2.5,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _pickColor();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.ellipsis,
                  size: 16,
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──

  Widget _sectionLabel(String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _pickIcon() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => IconPickerBottomSheet(backgroundColor: _selectedColor),
    );
    if (result != null) setState(() => _selectedIcon = result);
  }

  void _pickColor() async {
    final c = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (c != null) setState(() => _selectedColor = c);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final isar = await ref.read(isarServiceProvider).getInstance();

      final category = widget.existing ?? Category();
      category.name = _nameController.text.trim();
      category.categoryType = _selectedType;
      category.iconName = _selectedIcon;
      category.colorValue = _selectedColor.toARGB32();
      category.parentCategory.value = _selectedParent;

      final keywordsText = _keywordsController.text.trim();
      category.keywords = keywordsText.isNotEmpty
          ? keywordsText
              .split(',')
              .map((k) => k.trim().toLowerCase())
              .where((k) => k.isNotEmpty)
              .toList()
          : null;

      await isar.writeTxn(() async {
        await isar.categorys.put(category);
        await category.parentCategory.save();
      });
      ref.invalidate(categoryListProvider);
      if (!_isEditing) {
        ref
            .read(gamificationServiceProvider)
            ?.track(GamificationEvent.categoryCreated);
      }

      if (mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── PARENT CATEGORY PICKER ──
class _ParentCategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;

  const _ParentCategoryPicker({required this.categories, this.selected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Parent Category',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                ListTile(
                  leading: Icon(LucideIcons.minus, color: color.primary),
                  title: const Text('None (Top-level)'),
                  selected: selected == null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, Category());
                  },
                ),
                ...categories.map((c) {
                  final catColor =
                      Color(c.colorValue ?? Colors.grey.toARGB32());
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconHelper.getIconData(c.iconName),
                        color: catColor,
                        size: 20,
                      ),
                    ),
                    title: Text(c.name),
                    selected: selected?.id == c.id,
                    trailing: selected?.id == c.id
                        ? Icon(
                            LucideIcons.check,
                            size: 18,
                            color: color.primary,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, c);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
