import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/bill_control_center_provider.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/transaction_form/transaction_form_widgets.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? recurring;

  const AddRecurringTransactionScreen({super.key, this.recurring});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends ConsumerState<AddRecurringTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isExpense = true;
  bool _saving = false;
  DateTime _startDate = DateTime.now();
  Frequency _frequency = Frequency.monthly;
  Account? _selectedAccount;
  Category? _selectedCategory;

  final _categoryScrollController = ScrollController();
  final _subcategoryScrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _deleting = false;

  bool get _isEditing => widget.recurring != null;
  final _accountScrollController = ScrollController();
  bool _accountScrolled = false;
  bool _categoryScrolled = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_handleAmountChanged);
    if (_isEditing) {
      _amountController.text = widget.recurring!.amount.toString();
      _descController.text = widget.recurring!.description ?? '';
      _isExpense = widget.recurring!.isExpense;
      _startDate = widget.recurring!.startDate;
      _frequency = widget.recurring!.frequency;
      _selectedAccount = widget.recurring!.account.value;
      _selectedCategory = widget.recurring!.category.value;
    }
  }

  void _handleAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_handleAmountChanged);
    _amountController.dispose();
    _descController.dispose();
    _categoryScrollController.dispose();
    _subcategoryScrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        appBarMode: AppBarMode.none,
        customAppBar: _RecurringFormAppBar(
          title:
              _isEditing ? ctxt.common_edit : ctxt.title_recurringTransactions,
          step: _step,
          stepLabel: _stepLabel(ctxt),
          spacing: spacing,
        ),
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontal,
                spacing.cardVertical,
                spacing.cardHorizontal,
                spacing.touchTarget + spacing.cardInner * 2,
              ),
              children: [
                _buildRecurringPreview(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap * 1.5),
                AnimatedSwitcher(
                  duration: spacing.animNormal,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildStepContent(color, textTheme, spacing, ctxt),
                ),
                if (_isEditing && _step == 2) ...[
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildDangerZone(color, textTheme, spacing, ctxt),
                ],
                SizedBox(height: spacing.touchTarget + spacing.cardInner),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildWizardActions(color, spacing, ctxt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return switch (_step) {
      0 => _buildBasicsStep(color, textTheme, spacing, ctxt),
      1 => _buildScheduleStep(color, textTheme, spacing, ctxt),
      _ => _buildAssignmentStep(color, textTheme, spacing, ctxt),
    };
  }

  Widget _buildBasicsStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final accentColor = _isExpense ? color.error : color.primary;
    return Column(
      key: const ValueKey('recurring-basics-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.label_type,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.title_recurringTransactions,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        TypeToggle(
          isExpense: _isExpense,
          onChanged: (value) {
            setState(() {
              _isExpense = value;
              _selectedCategory = null;
              _categoryScrolled = false;
            });
          },
        ),
        SizedBox(height: spacing.sectionGap),
        HeroAmountInput(
          controller: _amountController,
          accentColor: accentColor,
        ),
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _descController,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: ctxt.label_description,
            hintText: ctxt.label_description,
            prefixIcon: Icon(
              LucideIcons.fileText,
              size: spacing.iconSM,
              color: color.onSurfaceVariant,
            ),
            filled: true,
            fillColor: color.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: color.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: color.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: color.primary, width: 1.5),
            ),
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildScheduleStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('recurring-schedule-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.label_frequency,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.label_frequency,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        Wrap(
          spacing: spacing.elementGapMin,
          runSpacing: spacing.elementGapMin,
          children: Frequency.values.map((frequency) {
            final selected = _frequency == frequency;
            return ChoiceChip(
              label: Text(_frequencyLabel(frequency, ctxt)),
              selected: selected,
              avatar: Icon(
                _frequencyIcon(frequency),
                size: spacing.iconSM,
                color: selected ? color.primary : color.onSurfaceVariant,
              ),
              showCheckmark: false,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _frequency = frequency);
              },
            );
          }).toList(),
        ),
        SizedBox(height: spacing.sectionGap),
        _buildSectionLabel(
          ctxt.budget_startDate,
          LucideIcons.calendar,
          color,
          textTheme,
        ),
        SizedBox(height: spacing.elementGap),
        _buildDatePicker(color, textTheme, spacing, ctxt),
      ],
    );
  }

  Widget _buildAssignmentStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('recurring-assignment-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.transaction_selectAccountLabel,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.transaction_selectCategoryLabel,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        _buildSectionLabel(
          ctxt.transaction_selectAccountLabel,
          LucideIcons.landmark,
          color,
          textTheme,
        ),
        SizedBox(height: spacing.elementGap),
        _buildAccountSelector(color, textTheme, spacing),
        SizedBox(height: spacing.sectionGap),
        _buildSectionLabel(
          ctxt.transaction_selectCategoryLabel,
          LucideIcons.tag,
          color,
          textTheme,
        ),
        SizedBox(height: spacing.elementGap),
        _buildCategorySelector(color, textTheme, spacing),
      ],
    );
  }

  Widget _buildRecurringPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final category = _selectedCategory;
    final accent = _isExpense ? color.error : color.primary;
    final title = _descController.text.trim().isEmpty
        ? category?.name ?? ctxt.title_recurringTransactions
        : _descController.text.trim();
    final amount = double.tryParse(
          _amountController.text.trim().replaceAll(',', ''),
        ) ??
        0;

    return AnimatedContainer(
      duration: spacing.animFast,
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            color.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: spacing.touchTargetSmall,
            height: spacing.touchTargetSmall,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            alignment: Alignment.center,
            child: Icon(
              category == null
                  ? LucideIcons.repeat
                  : IconHelper.iconFromName(category.iconName ?? 'category'),
              color: accent,
              size: spacing.iconLG,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Text(
                  '${_frequencyLabel(_frequency, ctxt)} • ${DateFormat.yMMMd(ctxt.localeName).format(_startDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.elementGap),
          CurrencyText(
            amount: amount,
            fixedLength: 0,
            compact: false,
            style: textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinueForStep() {
    if (_step == 0) {
      final amount = double.tryParse(
        _amountController.text.trim().replaceAll(',', ''),
      );
      return amount != null && amount.isFinite && amount > 0;
    }
    if (_step == 2) {
      return _selectedAccount != null && _selectedCategory != null;
    }
    return true;
  }

  void _nextStep(AppSpacing spacing) {
    final ctxt = AppLocalizations.of(context)!;
    if (!_canContinueForStep()) {
      SnackbarService.warning(
        _step == 0
            ? ctxt.transaction_amountControllerErrorText
            : BuddyMessages.selectAccountAndCategory,
        spacing,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _step = (_step - 1).clamp(0, 2));
  }

  String _stepLabel(AppLocalizations ctxt) {
    return switch (_step) {
      0 => ctxt.label_type,
      1 => ctxt.label_frequency,
      _ => ctxt.transaction_selectAccountLabel,
    };
  }

  Widget _buildWizardActions(
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isLastStep = _step == 2;
    final canContinue = _canContinueForStep() && !_saving && !_deleting;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.elementGap,
        spacing.cardHorizontal,
        spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: color.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: _saving || _deleting ? null : _previousStep,
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: Text(ctxt.common_back),
              )
            else
              SizedBox(width: spacing.touchTargetSmall),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: FilledButton.icon(
                onPressed: canContinue
                    ? (isLastStep
                        ? () => _save(spacing)
                        : () => _nextStep(spacing))
                    : null,
                icon: _saving
                    ? SizedBox(
                        width: spacing.iconSM,
                        height: spacing.iconSM,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color.onPrimary,
                        ),
                      )
                    : Icon(
                        isLastStep ? LucideIcons.check : LucideIcons.arrowRight,
                        size: 18,
                      ),
                label: Text(
                  isLastStep
                      ? (_isEditing ? ctxt.common_update : ctxt.common_save)
                      : ctxt.common_next,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, spacing.touchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: _saving || _deleting ? null : () => _delete(spacing),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Icon(
                LucideIcons.trash2,
                size: spacing.iconSM,
                color: color.error,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.common_delete,
                style: textTheme.bodyMedium?.copyWith(color: color.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _frequencyLabel(Frequency f, AppLocalizations ctxt) {
    return switch (f) {
      Frequency.daily => ctxt.label_daily,
      Frequency.weekly => ctxt.label_weekly,
      Frequency.monthly => ctxt.label_monthly,
      Frequency.yearly => ctxt.label_yearly,
    };
  }

  Widget _buildDatePicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final pick = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
          lastDate: DateTime.now().add(const Duration(days: 36500)),
        );
        if (pick != null && mounted) {
          setState(
            () => _startDate = DateTime(pick.year, pick.month, pick.day),
          );
        }
      },
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: spacing.iconSM,
              color: color.onSurfaceVariant,
            ),
            SizedBox(width: spacing.elementGap),
            Text(
              DateFormat.yMMMd(ctxt.localeName).format(_startDate),
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final accountsAsync = ref.watch(accountsProvider);
    return accountsAsync.when(
      data: (accounts) => SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          controller: _accountScrollController,
          itemCount: accounts.length,
          separatorBuilder: (_, __) => SizedBox(width: spacing.elementGap),
          itemBuilder: (context, index) {
            final account = accounts[index];
            final isSelected = _selectedAccount?.id == account.id;
            final acColor =
                Color(account.colorValue ?? color.primary.toARGB32());
            if (_selectedAccount != null && !_accountScrolled) {
              _accountScrolled = true;
              final idx =
                  accounts.indexWhere((a) => a.id == _selectedAccount!.id);
              if (idx > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_accountScrollController.hasClients) {
                    _accountScrollController.animateTo(
                      idx * 160.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedAccount = account);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? acColor.withValues(alpha: 0.1)
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? acColor.withValues(alpha: 0.5)
                        : color.outlineVariant.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: acColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(LucideIcons.landmark, size: 16, color: acColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      account.name,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? color.onSurface
                            : color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
        child: const LinearProgressIndicator(),
      ),
      error: (error, _) => _buildSelectorError(
        message: BuddyMessages.errorWith('$error'),
        onRetry: () => ref.invalidate(accountsProvider),
        spacing: spacing,
        color: color,
        textTheme: textTheme,
      ),
    );
  }

  Widget _buildSelectorError({
    required String message,
    required VoidCallback onRetry,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: color.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.common_retry),
          ),
        ],
      ),
    );
  }

  Category? _expandedParent(List<Category> parents) {
    if (_selectedCategory == null) return null;
    if (parents.any((p) => p.id == _selectedCategory!.id)) {
      return _selectedCategory;
    }
    final parentId = _selectedCategory!.parentCategory.value?.id;
    if (parentId != null) {
      return parents.where((p) => p.id == parentId).firstOrNull;
    }
    return null;
  }

  Widget _buildCategorySelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final categoriesAsync = ref.watch(categoryListProvider);
    return categoriesAsync.when(
      data: (categories) {
        final parents = categories
            .where(
              (c) =>
                  (_isExpense
                      ? c.categoryType == CategoryType.expense
                      : c.categoryType == CategoryType.income) &&
                  c.parentCategory.value == null,
            )
            .toList();

        final expanded = _expandedParent(parents);
        final hasChildren = expanded != null &&
            categories.any((c) => c.parentCategory.value?.id == expanded.id);
        final children = hasChildren
            ? categories
                .where((c) => c.parentCategory.value?.id == expanded.id)
                .toList()
            : <Category>[];
        if (_selectedCategory != null && !_categoryScrolled) {
          _categoryScrolled = true;
          final parentId = _selectedCategory!.parentCategory.value?.id ??
              _selectedCategory!.id;
          final idx = parents.indexWhere((c) => c.id == parentId);
          if (idx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_categoryScrollController.hasClients) {
                _categoryScrollController.animateTo(
                  idx * 120.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
        // Inside _buildCategorySelector, after building the children list:
        if (_selectedCategory != null &&
            _selectedCategory!.parentCategory.value != null &&
            children.isNotEmpty) {
          final subIdx =
              children.indexWhere((c) => c.id == _selectedCategory!.id);
          if (subIdx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_subcategoryScrollController.hasClients) {
                _subcategoryScrollController.animateTo(
                  subIdx * 100.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedCategory != null)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 16,
                      color: Color(
                        _selectedCategory!.colorValue ??
                            color.primary.toARGB32(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory!.name,
                      style: textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_selectedCategory!.parentCategory.value != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\u00b7 ${_selectedCategory!.parentCategory.value?.name ?? ""}',
                        style: textTheme.labelMedium
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: parents.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: spacing.elementGap),
                itemBuilder: (context, index) {
                  final cat = parents[index];
                  final catColor =
                      Color(cat.colorValue ?? color.primary.toARGB32());
                  final isExpanded = expanded?.id == cat.id;
                  final isDirectlySelected = _selectedCategory?.id == cat.id;
                  final isSelected = isExpanded || isDirectlySelected;
                  final hasSubs = categories
                      .any((c) => c.parentCategory.value?.id == cat.id);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.1)
                            : color.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.5)
                              : color.outlineVariant.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconHelper.iconFromName(
                              cat.iconName ?? 'category',
                            ),
                            size: 16,
                            color: catColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat.name,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color.onSurface
                                  : color.onSurfaceVariant,
                            ),
                          ),
                          if (hasSubs) ...[
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                                color: isSelected
                                    ? catColor
                                    : color.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: hasChildren
                  ? Padding(
                      padding: EdgeInsets.only(top: spacing.elementGap),
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          controller: _subcategoryScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: children.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: spacing.elementGap),
                          itemBuilder: (context, index) {
                            final sub = children[index];
                            final subColor = Color(
                              sub.colorValue ?? color.primary.toARGB32(),
                            );
                            final isSubSelected =
                                _selectedCategory?.id == sub.id;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = sub);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSubSelected
                                      ? subColor.withValues(alpha: 0.12)
                                      : color.surfaceContainerHighest
                                          .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color: isSubSelected
                                        ? subColor.withValues(alpha: 0.5)
                                        : color.outlineVariant
                                            .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconHelper.iconFromName(
                                        sub.iconName ?? 'category',
                                      ),
                                      size: 14,
                                      color: subColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sub.name,
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: isSubSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSubSelected
                                            ? color.onSurface
                                            : color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
        child: const LinearProgressIndicator(),
      ),
      error: (error, _) => _buildSelectorError(
        message: BuddyMessages.errorWith('$error'),
        onRetry: () => ref.invalidate(categoryListProvider),
        spacing: spacing,
        color: color,
        textTheme: textTheme,
      ),
    );
  }

  IconData _frequencyIcon(Frequency f) {
    return switch (f) {
      Frequency.daily => LucideIcons.calendarDays,
      Frequency.weekly => LucideIcons.calendarRange,
      Frequency.monthly => LucideIcons.calendar,
      Frequency.yearly => LucideIcons.calendarClock,
    };
  }

  Future<void> _save(AppSpacing spacing) async {
    if (_saving || _deleting) return;
    final ctxt = AppLocalizations.of(context)!;
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || !amount.isFinite || amount <= 0) {
      SnackbarService.error(
        ctxt.transaction_amountControllerErrorText,
        spacing,
      );
      return;
    }
    if (_selectedAccount == null || _selectedCategory == null) {
      SnackbarService.error(BuddyMessages.selectAccountAndCategory, spacing);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final recurring = widget.recurring ?? RecurringTransaction();
      recurring.amount = amount;
      recurring.description = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();
      recurring.isExpense = _isExpense;
      recurring.frequency = _frequency;
      recurring.startDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
      if (!_isEditing) {
        recurring.nextDueDate = recurring.startDate;
      } else {
        // Preserve current next due date when editing. Schedule semantics are
        // intentionally unchanged by this UX refactor.
        recurring.nextDueDate = widget.recurring!.nextDueDate;
      }
      recurring.isActive = true;
      recurring.account.value = _selectedAccount;
      recurring.category.value = _selectedCategory;

      await ref.read(recurringTransactionServiceProvider).save(recurring);
      ref.invalidate(recurringTransactionsProvider);
      ref.invalidate(billControlCenterProvider);

      if (!mounted) return;
      SnackbarService.success(
        _isEditing ? BuddyMessages.txnUpdated : BuddyMessages.txnAdded,
        spacing,
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.error(BuddyMessages.errorWith('$error'), spacing);
    }
  }

  Future<void> _delete(AppSpacing spacing) async {
    if (_saving || _deleting || widget.recurring == null) return;
    final ctxt = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: ctxt.common_delete,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(recurringTransactionServiceProvider)
          .delete(widget.recurring!.id);
      ref.invalidate(recurringTransactionsProvider);
      ref.invalidate(billControlCenterProvider);

      if (!mounted) return;
      SnackbarService.success(BuddyMessages.txnDeleted, spacing);
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      SnackbarService.error(BuddyMessages.errorWith('$error'), spacing);
    }
  }
}

class _RecurringFormAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _RecurringFormAppBar({
    required this.title,
    required this.step,
    required this.stepLabel,
    required this.spacing,
  });

  final String title;
  final int step;
  final String stepLabel;
  final AppSpacing spacing;

  @override
  Size get preferredSize => Size.fromHeight(80 + spacing.cardInner * 2.5);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: true,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(spacing.cardInner * 2.5),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            0,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stepLabel,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${step + 1} / 3',
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 2 ? 0 : spacing.elementGapMin,
                      ),
                      child: AnimatedContainer(
                        duration: spacing.animFast,
                        height: spacing.progressThin,
                        decoration: BoxDecoration(
                          color: index <= step
                              ? color.primary
                              : color.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
