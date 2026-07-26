import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/category_keyword_suggestions.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/domain/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/icon_picker_bottom_sheet.dart';
import 'package:mudra_manager/shared/widgets/category_color_picker.dart';
import 'package:mudra_manager/shared/widgets/glass_text_field.dart';
import 'package:mudra_manager/shared/widgets/parent_category_picker.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? existing;
  final Category? initialParent;
  final CategoryType? initialType;

  const AddEditCategoryScreen({
    super.key,
    this.existing,
    this.initialParent,
    this.initialType,
  });

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _keywordsController;
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedIcon;
  late Color _accentColor;
  Category? _selectedParent;
  bool _saving = false;
  bool _themeResolved = false;

  /// Suggested keywords for the current name, minus ones already added
  /// or explicitly dismissed by the user this session.
  List<String> _keywordSuggestions = const [];
  final Set<String> _dismissedSuggestions = {};

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
    _selectedType = widget.existing?.categoryType ??
        widget.initialType ??
        CategoryType.expense;
    _selectedIcon = widget.existing?.iconName;
    _accentColor = widget.existing?.colorValue != null
        ? Color(widget.existing!.colorValue!)
        : Colors.grey; // Placeholder, will be resolved in didChangeDependencies
    _selectedParent = widget.initialParent;
    _loadParentCategory();
    _updateKeywordSuggestions();
    _nameController.addListener(_updateKeywordSuggestions);
  }

  void _updateKeywordSuggestions() {
    final suggestions = CategoryKeywordSuggestions.suggest(_nameController.text)
        .where((k) => !_dismissedSuggestions.contains(k))
        .where((k) => !_currentKeywords.contains(k))
        .toList();
    if (!listEquals(suggestions, _keywordSuggestions)) {
      setState(() => _keywordSuggestions = suggestions);
    }
  }

  List<String> get _currentKeywords => _keywordsController.text
      .split(',')
      .map((k) => k.trim().toLowerCase())
      .where((k) => k.isNotEmpty)
      .toList();

  void _addSuggestedKeyword(String keyword) {
    HapticFeedback.lightImpact();
    final current = _keywordsController.text.trim();
    _keywordsController.text = current.isEmpty ? keyword : '$current, $keyword';
    setState(() {
      _keywordSuggestions = _keywordSuggestions.where((k) => k != keyword).toList();
    });
  }

  void _dismissSuggestion(String keyword) {
    HapticFeedback.lightImpact();
    setState(() {
      _dismissedSuggestions.add(keyword);
      _keywordSuggestions = _keywordSuggestions.where((k) => k != keyword).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeResolved) {
      _accentColor = widget.existing?.colorValue != null
          ? Color(widget.existing!.colorValue!)
          : Theme.of(context).colorScheme.primary;
      _themeResolved = true;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateKeywordSuggestions);
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth > 600 ? spacing.cardHorizontalMax : spacing.cardHorizontal;

        return ScreenShell(
          config: ScreenShellConfig(
            title: _isEditing ? ctxt.category_editTitle : ctxt.category_addTitle,
            appBarMode: AppBarMode.standard,
            enableRefresh: false,
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
          actions: ScreenActions.build(
            trailing: ScreenTextAction(
              id: 'save_category',
              label: _isEditing ? ctxt.common_update : ctxt.category_save,
              onTap: _saving ? null : _save,
              isLoading: _saving,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: spacing.cardVertical,
              ),
              children: [
                _buildHeroPreview(
                  color,
                  textTheme,
                  spacing,
                  ctxt,
                  reduceMotion,
                ),
                SizedBox(height: spacing.sectionGap),
                _buildTypeSection(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap),
                _buildDetailsSection(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap),
                _buildParentSection(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap),
                _buildColorSection(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── HERO PREVIEW ──
  Widget _buildHeroPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool reduceMotion,
  ) {
    final name = _nameController.text.trim();
    final iconData = _selectedIcon != null
        ? IconHelper.iconFromName(_selectedIcon!)
        : LucideIcons.tag;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Category preview',
      container: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _pickIcon();
        },
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.2),
                radius: 1.2,
                colors: [
                  _accentColor.withValues(alpha: isDark ? 0.25 : 0.2),
                  _accentColor.withValues(alpha: isDark ? 0.1 : 0.06),
                  color.surface.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                // Ambient glow
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _accentColor.withValues(alpha: isDark ? 0.2 : 0.15),
                          _accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Identity block (glass surface like AccountScreen)
                Padding(
                  padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      RepaintBoundary(
                        child: Container(
                          padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            iconData,
                            size: 32,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.sectionGap),
                      // Name display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontalMax,
                          vertical: spacing.elementGap,
                        ),
                        decoration: BoxDecoration(
                          color: color.surface.withValues(alpha: isDark ? 0.1 : 0.15),
                          borderRadius: BorderRadius.circular(spacing.radiusMedium),
                          border: Border.all(
                            color: color.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name.isEmpty ? ctxt.category_nameHint : name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
                      // Type and parent info
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.elementGap,
                              vertical: spacing.elementGapUltraMin,
                            ),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(spacing.radiusMedium),
                              border: Border.all(
                                color: color.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              _selectedType.name.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_selectedParent != null) ...[
                            SizedBox(width: spacing.elementGap),
                            Icon(
                              LucideIcons.folderOpen,
                              size: 12,
                              color: color.onSurfaceVariant,
                            ),
                            SizedBox(width: spacing.elementGapMin),
                            Text(
                              _selectedParent!.name,
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: spacing.sectionGap),
                      Text(
                        ctxt.category_tapToChangeIcon,
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
          ),
        ),
      ),
    );
  }

  // ── TYPE SECTION ──
  Widget _buildTypeSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: ctxt.category_typeLabel,
          icon: LucideIcons.tag,
          accentColor: color.primary,
        ),
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
          style: SegmentedButton.styleFrom(
            backgroundColor: color.surfaceContainerLow,
            selectedBackgroundColor: color.primary.withValues(alpha: 0.15),
            selectedForegroundColor: color.primary,
            foregroundColor: color.onSurfaceVariant,
            side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  // ── DETAILS SECTION ──
  Widget _buildDetailsSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: color.surface.withValues(alpha: isDark ? 0.6 : 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: ctxt.category_detailsLabel,
          icon: LucideIcons.formInput,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        GlassTextField(
          controller: _nameController,
          decoration: inputDecoration.copyWith(
            labelText: ctxt.category_nameHint,
            prefixIcon: Icon(LucideIcons.pencil, size: 18, color: color.primary),
          ),
          textTheme: textTheme,
          validator: (v) =>
              v == null || v.trim().isEmpty ? ctxt.common_required : null,
        ),
        SizedBox(height: spacing.sectionGap),
        GlassTextField(
          controller: _keywordsController,
          decoration: inputDecoration.copyWith(
            labelText: ctxt.category_keywordsHint,
            helperText: ctxt.category_keywordsHelper,
            helperStyle: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(LucideIcons.tag, size: 18, color: color.primary),
          ),
          textTheme: textTheme,
          onChanged: (_) => _updateKeywordSuggestions(),
        ),
        if (_keywordSuggestions.isNotEmpty) ...[
          SizedBox(height: spacing.elementGap),
          _buildKeywordSuggestions(color, textTheme, spacing, ctxt),
        ],
      ],
    );
  }

  // ── KEYWORD SUGGESTIONS ──
  Widget _buildKeywordSuggestions(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: spacing.elementGapMin),
          child: Text(
            ctxt.category_suggestedKeywords,
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Wrap(
          spacing: spacing.elementGap,
          runSpacing: spacing.elementGapMin,
          children: _keywordSuggestions.map((keyword) {
            return InputChip(
              label: Text(
                keyword,
                style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              avatar: Icon(LucideIcons.plus, size: 14, color: color.primary),
              onPressed: () => _addSuggestedKeyword(keyword),
              onDeleted: () => _dismissSuggestion(keyword),
              deleteIcon: Icon(LucideIcons.x, size: 14, color: color.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: color.primary.withValues(alpha: 0.08),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── PARENT SECTION ──
  Widget _buildParentSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: ctxt.category_parentLabel,
          icon: LucideIcons.folderOpen,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              onTap: _pickParent,
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Row(
                  children: [
                    Icon(LucideIcons.folderOpen, size: 18, color: color.primary),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Text(
                        _selectedParent?.name ?? ctxt.category_noneTopLevel,
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
          ),
        ),
      ],
    );
  }

  // ── COLOR SECTION ──
  Widget _buildColorSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: ctxt.category_colorLabel,
          icon: LucideIcons.palette,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        CategoryColorPicker(
          selectedColor: _accentColor,
          onColorChanged: (c) => setState(() => _accentColor = c),
          onCustomPick: _pickColor,
          quickColors: _quickColors,
        ),
      ],
    );
  }

  // ── HELPERS ──
  void _pickIcon() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => IconPickerBottomSheet(backgroundColor: _accentColor),
    );
    if (result != null) {
      setState(() => _selectedIcon = result);
    }
  }

  void _pickColor() async {
    final c = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _accentColor),
    );
    if (c != null && mounted) {
      setState(() => _accentColor = c);
    }
  }

  void _pickParent() async {
    final categories = await ref.read(categoryListProvider.future);
    final filtered = categories.where((c) {
      if (c.categoryType != _selectedType) return false;
      if (c.id == widget.existing?.id) return false;
      c.parentCategory.loadSync();
      return c.parentCategory.value == null;
    }).toList();

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ParentCategoryPicker(
        categories: filtered,
        selected: _selectedParent,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedParent =
            selected.id == Isar.autoIncrement ? null : selected;
      });
    }
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
      category.colorValue = _accentColor.toARGB32();
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

      if (context.mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}