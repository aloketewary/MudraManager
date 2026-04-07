import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_access_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/sms/data/recurring_detector_service.dart';
import 'package:mudra_manager/features/sms/data/tag_matcher_service.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/providers/smart_defaults_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/simple_calculator.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/add_transaction_widgets.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final SmsActivity? smsActivity;
  final bool initialIsIncome;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.smsActivity,
    this.initialIsIncome = false,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _amountFocus = FocusNode();

  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();

  Account? _selectedAccount;
  Category? _selectedCategory;
  List<Tag> selectedTags = [];
  Map<int, double> _balanceMap = {};
  bool _initialized = false;
  bool _saving = false;
  bool _tripManuallyCleared = false;

  Trip? _selectedTrip;
  List<TripParticipant> _selectedParticipants = [];
  TripParticipant? _paidBy;
  SplitType _splitType = SplitType.equal;
  final Map<int, double> _splitAmounts = {};
  String? _txnCurrencyCode;

  bool get _isEditing => widget.transaction != null;

  String? get _effectiveCurrency =>
      _txnCurrencyCode ?? _selectedAccount?.currencyCode;

  /// True when the FAB explicitly set income/expense — hide the toggle
  bool get _typeLockedByFab =>
      !_isEditing && widget.smsActivity == null && widget.initialIsIncome;
  final _accountScrollController = ScrollController();
  final _categoryScrollController = ScrollController();
  final _subcategoryScrollController = ScrollController();
  bool _smartDefaultsApplied = false;
  bool _accountScrolled = false;
  bool _categoryScrolled = false;
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  ProviderSubscription? _tripSubscription;

  @override
  void initState() {
    super.initState();
    _amountController.text =
        widget.transaction?.amount.toStringAsFixed(2) ?? '';
    _descController.text = widget.transaction?.description ?? '';

    final transactionDate = widget.transaction?.date ?? DateTime.now();
    final now = DateTime.now();
    _selectedDate = transactionDate.isAfter(now) ? now : transactionDate;

    _selectedAccount = widget.transaction?.account.value;
    _selectedCategory = widget.transaction?.category.value;
    _isExpense = widget.transaction?.isExpense ?? !widget.initialIsIncome;
    _txnCurrencyCode = widget.transaction?.currencyCode;

    if (widget.transaction != null) {
      _loadEditTags();
    }
    if (widget.smsActivity != null && _selectedAccount == null) {
      _matchSmsAccount();
    }
    if (widget.smsActivity != null && !_isEditing) {
      final sms = widget.smsActivity!;
      if (sms.amount != null && _amountController.text.isEmpty) {
        _amountController.text = sms.amount!.toStringAsFixed(2);
      }
      if (sms.isIncome != null) _isExpense = !sms.isIncome!;
      final smsDate = sms.date;
      final now = DateTime.now();
      _selectedDate = smsDate.isAfter(now) ? now : smsDate;
      if (sms.body.isNotEmpty && _descController.text.isEmpty) {
        _descController.text = sms.body;
      }
      // Auto-suggest tags from SMS keywords
      _autoSuggestTags(sms.body);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing) {
        _amountFocus.requestFocus();
        if (widget.smsActivity == null) {
          _applySmartDefaults();
        }
      }
    });
    // In initState:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tripSubscription = ref.listenManual(allTripsProvider, (_, next) {
        if (next case AsyncData(:final value)) {
          final List<Trip> trips = value;
          if (_tripManuallyCleared || _selectedTrip != null) return;
          final Trip? activeTrip = trips.where((t) => t.isActive && t.isTrip).firstOrNull;
          if (activeTrip != null && mounted) {
            setState(() {
              _selectedTrip = activeTrip;
              _selectedParticipants = activeTrip.participants.toList();
              _paidBy = activeTrip.participants.firstOrNull;
            });
          }
        }
      });
    });
  }

  Future<void> _autoSuggestTags(String smsBody) async {
    final suggested = await TagMatcherService.suggestTagsForSms(smsBody);
    if (suggested.isNotEmpty && mounted) {
      setState(() {
        for (final tag in suggested) {
          if (!selectedTags.any((t) => t.id == tag.id)) {
            selectedTags.add(tag);
          }
        }
      });
    }
  }

  Future<void> _applySmartDefaults() async {
    if (_smartDefaultsApplied || !mounted) return;
    final d = await ref.read(smartDefaultsProvider(_isExpense).future);
    if (!mounted) return;
    _smartDefaultsApplied = true;
    setState(() {
      if (d.suggestedAccount != null && _selectedAccount == null) {
        _selectedAccount = d.suggestedAccount;
      }
      if (d.suggestedCategory != null && _selectedCategory == null) {
        _selectedCategory = d.suggestedCategory;
      }
    });
  }

  Future<void> _loadEditTags() async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    final txn = await isar.transactions.get(widget.transaction!.id);
    if (txn == null || !mounted) return;
    await txn.tags.load();
    setState(() {
      selectedTags.addAll(txn.tags.toList());
    });
  }

  Future<void> _matchSmsAccount() async {
    final smsAccountNumber = widget.smsActivity?.account;
    if (smsAccountNumber == null || smsAccountNumber.isEmpty) return;
    final isar = await ref.read(isarServiceProvider).getInstance();
    final match = await isar.accounts
        .filter()
        .accountNumberEqualTo(smsAccountNumber)
        .isActiveEqualTo(true)
        .findFirst();
    if (match != null && mounted) {
      setState(() => _selectedAccount = match);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) setState(() => _balanceMap = val);
      });
      _initialized = true;
    }
  }

  @override
  @override
  void dispose() {
    _tripSubscription?.close();
    _amountController.dispose();
    _descController.dispose();
    _amountFocus.dispose();
    _accountScrollController.dispose();
    _categoryScrollController.dispose();
    _subcategoryScrollController.dispose();
    super.dispose();
  }

  void _showCalculator(BuildContext context, Function(double) onResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      enableDrag: true,
      showDragHandle: true,
      isDismissible: false,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SimpleCalculator(
            onResultSelected: (value) {
              context.pop();
              onResult(value);
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    final accentColor = _isExpense ? color.error : color.primary;

    return Scaffold(
      backgroundColor: color.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: Text(
          _isEditing
              ? 'Edit Transaction'
              : (_isExpense ? 'Add Expense' : 'Add Income'),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Expense/Income toggle (in body, below AppBar) ──
            if (!_typeLockedByFab)
              RepaintBoundary(
                child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.elementGap,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _isExpense = true;
                              _selectedCategory = null;
                              _smartDefaultsApplied = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isExpense
                                  ? color.error.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                spacing.radiusMedium - 2,
                              ),
                              border: Border.all(
                                color: _isExpense
                                    ? color.error.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.circleMinus,
                                  size: 16,
                                  color: _isExpense
                                      ? color.error
                                      : color.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ctxt.transaction_expenseButtonLabel,
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: _isExpense
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _isExpense
                                        ? color.error
                                        : color.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _isExpense = false;
                              _selectedCategory = null;
                              _smartDefaultsApplied = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isExpense
                                  ? color.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                spacing.radiusMedium - 2,
                              ),
                              border: Border.all(
                                color: !_isExpense
                                    ? color.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.circlePlus,
                                  size: 16,
                                  color: !_isExpense
                                      ? color.primary
                                      : color.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ctxt.transaction_incomeButtonLabel,
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: !_isExpense
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: !_isExpense
                                        ? color.primary
                                        : color.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),

            // ── Trip banner (top, outside ListView) ──
            if (_selectedTrip != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.luggage, size: 18, color: color.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTrip!.name,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_selectedParticipants.length} people',
                        style: textTheme.labelSmall?.copyWith(
                          color:
                              color.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showSplitCustomizer(),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Currency mismatch hint ──
            if (_selectedTrip?.currencyCode != null &&
                _selectedAccount != null &&
                _effectiveCurrency != _selectedTrip!.currencyCode)
              Padding(
                padding: EdgeInsets.only(
                  left: spacing.cardHorizontal,
                  right: spacing.cardHorizontal,
                  top: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 14,
                      color: color.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Trip is in ${_selectedTrip!.currencyCode} — amount will be converted',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.tertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Scrollable content (Parts 2-4 go here) ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  // ── Hero Amount ──
                  RepaintBoundary(
                    child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          focusNode: _amountFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accentColor.withValues(alpha: 0.2),
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CurrencyBadge(
                                code: _effectiveCurrency ?? BaseCurrency.code,
                                size: 28,
                                color: accentColor.withValues(alpha: 0.6),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: spacing.cardVerticalMax,
                            ),
                            filled: false,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: IconButton(
                              onPressed: () => _showCalculator(context, (v) {
                                _amountController.text = v.toString();
                              }),
                              icon: Icon(
                                LucideIcons.calculator,
                                color: accentColor.withValues(alpha: 0.6),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        // Quick amounts
                        Padding(
                          padding: EdgeInsets.only(bottom: spacing.elementGap),
                          child: QuickAmounts(
                            accentColor: accentColor,
                            onAmountSelected: (amt) {
                              _amountController.text = amt.toString();
                            },
                          ),
                        ),
                        if (!_isEditing && widget.smsActivity == null)
                          SmartDefaultsBanner(
                            isExpense: _isExpense,
                            onApply: () {
                              final d = ref.read(smartDefaultsProvider(_isExpense)).valueOrNull;
                              if (d == null) return;
                              setState(() {
                                _selectedCategory = d.suggestedCategory;
                                if (d.suggestedAccount != null && _selectedAccount == null) {
                                  _selectedAccount = d.suggestedAccount;
                                }
                                if (d.suggestedAmount != null && _amountController.text.isEmpty) {
                                  _amountController.text = d.suggestedAmount!.toStringAsFixed(0);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  // ── Account selector ──
                  AccountSelector(
                    selectedAccount: _selectedAccount,
                    balanceMap: _balanceMap,
                    scrollController: _accountScrollController,
                    alreadyScrolled: _accountScrolled,
                    smsAccountNumber: widget.smsActivity?.account,
                    smsBankName: widget.smsActivity?.fromBank,
                    addLabel: ctxt.common_addLabel,
                    onSelected: (account) {
                      setState(() {
                        _selectedAccount = account;
                        _accountScrolled = true;
                      });
                    },
                    onAddResult: () {
                      ref
                          .read(accountServiceProvider)
                          .getAccountBalanceMap()
                          .then((val) {
                        if (mounted) setState(() => _balanceMap = val);
                      });
                    },
                    onShowUnlockPrompt: _showUnlockPrompt,
                  ),

                  SizedBox(height: spacing.sectionGap),

                  // ── Category selector ──
                  CategorySelector(
                    isExpense: _isExpense,
                    selectedCategory: _selectedCategory,
                    categoryScrollController: _categoryScrollController,
                    subcategoryScrollController: _subcategoryScrollController,
                    alreadyScrolled: _categoryScrolled,
                    addLabel: ctxt.common_addLabel,
                    onSelected: (cat) {
                      setState(() {
                        _selectedCategory = cat;
                        _categoryScrolled = true;
                      });
                    },
                    expandedParentFinder: (parents) => parents,
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // ── Date & Time row ──
                  Row(
                    children: [
                      // Date chip
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final safeInitial = _selectedDate.isAfter(now)
                                ? now
                                : _selectedDate;
                            final pick = await showDatePicker(
                              context: context,
                              initialDate: safeInitial,
                              firstDate: DateTime(2000),
                              lastDate: now,
                            );
                            if (pick != null) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedDate = DateTime(
                                  pick.year,
                                  pick.month,
                                  pick.day,
                                  _selectedDate.hour,
                                  _selectedDate.minute,
                                );
                              });
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                              border: Border.all(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: color.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_selectedDate),
                                    style: textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      // Time chip
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(_selectedDate),
                            );
                            if (picked != null) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedDate = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month,
                                  _selectedDate.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                              border: Border.all(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 16,
                                  color: color.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('hh:mm a').format(_selectedDate),
                                  style: textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.elementGap),

                  // ── Note field ──
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: ctxt.transaction_addNoteHint,
                      prefixIcon: Icon(
                        Icons.edit_note,
                        size: 20,
                        color: color.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        borderSide: BorderSide(
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        borderSide: BorderSide(
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                    maxLines: 5,
                    minLines: 4,
                  ),

                  SizedBox(height: spacing.sectionGap),

                  // ── Tags ──
                  TagSelector(
                    selectedTags: selectedTags,
                    addNewTagText: ctxt.transaction_addNewTagText,
                    onToggle: (tag) {
                      setState(() {
                        if (selectedTags.any((t) => t.id == tag.id)) {
                          selectedTags.removeWhere((t) => t.id == tag.id);
                        } else {
                          selectedTags.add(tag);
                        }
                      });
                    },
                    onAddNew: () => showAddTagBottomSheet(context, ref),
                  ),
                ],
              ),
            ),
            // ── Pinned save button ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontal,
                spacing.elementGap,
                spacing.cardHorizontal,
                spacing.cardHorizontalMax +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: FilledButton(
                onPressed: _saving ? null : _saveTransaction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color.onPrimary,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Update Transaction'
                            : ctxt.transaction_saveTransactionButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      SnackbarService.error(BuddyMessages.invalidAmount);
      return;
    }
    if (_selectedAccount == null) {
      SnackbarService.error(BuddyMessages.pickAccount);
      return;
    }

    final unlocked =
        await ref.read(isAccountUnlockedProvider(_selectedAccount!.id).future);
    if (!unlocked) {
      SnackbarService.error(BuddyMessages.accountLocked);
      setState(() => _saving = false);
      return;
    }

    if (_selectedCategory == null) {
      SnackbarService.error(BuddyMessages.pickCategory);
      return;
    }

    setState(() => _saving = true);

    try {
      final amount = double.parse(_amountController.text);

      final String? saveCurrency = _effectiveCurrency;
      double? convertedAmount;
      double? rateUsed;

      if (saveCurrency != null) {
        final currencyService =
            await ref.read(currencyServiceProvider.future);
        final result = await currencyService.convertToBase(amount, saveCurrency);
        if (result != null) {
          convertedAmount = result.converted;
          rateUsed = result.rate;
        }
      }

      final txn = Transaction.create(
        date: _selectedDate,
        amount: amount,
        isExpense: _isExpense,
        description: _descController.text,
        currencyCode: saveCurrency,
        convertedAmount: convertedAmount,
        rateUsed: rateUsed,
      );

      if (_isEditing && widget.transaction!.id != Isar.autoIncrement) {
        txn.id = widget.transaction!.id;
      }

      txn.account.value = _selectedAccount;
      txn.category.value = _selectedCategory;
      txn.tags.addAll(selectedTags);

      await ref.read(transactionProvider).addTransaction(txn);

      // Add to trip if selected
      if (_selectedTrip != null &&
          _paidBy != null &&
          _selectedParticipants.isNotEmpty) {
        List<double> splitAmounts;

        if (_splitType == SplitType.equal) {
          splitAmounts = List.filled(
            _selectedParticipants.length,
            txn.amount / _selectedParticipants.length,
          );
        } else {
          splitAmounts = _selectedParticipants
              .map((p) => _splitAmounts[p.id] ?? 0.0)
              .toList();
        }

        await ref.read(tripServiceProvider).addTransactionToTrip(
              _selectedTrip!.id,
              txn,
              _paidBy!.id,
              _splitType,
              _selectedParticipants.map((p) => p.id).toList(),
              splitAmounts,
            );
        ref.invalidate(tripByIdProvider(_selectedTrip!.id));
        ref
            .read(gamificationServiceProvider)
            ?.track(GamificationEvent.expenseSplit);
      }

      // If from SMS activity, approve it
      if (widget.smsActivity != null) {
        final isar = await ref.read(isarServiceProvider).getInstance();
        await isar.writeTxn(() async {
          widget.smsActivity!.status = ActivityStatus.approved;
          widget.smsActivity!.transactionId = txn.id;
          await isar.smsActivitys.put(widget.smsActivity!);
        });

        // Detect and link to recurring bills (SMS imports only)
        await RecurringDetectorService.detectAndTagRecurring(txn);
      }

      await _checkLowBalance(txn.account.value);
      await _checkBudgetAlerts(txn);
      await WidgetService.updateWidget(ref);

      if (mounted) {
        ref.invalidate(transactionProvider);
        ref.invalidate(accountServiceProvider);
        ref.invalidate(budgetServiceProvider);
        if (widget.smsActivity != null) {
          ref.invalidate(smsActivityProvider);
          ref.invalidate(pendingCountProvider);
          ref.read(smsRefreshProvider.notifier).state++;
          ref
              .read(gamificationServiceProvider)
              ?.track(GamificationEvent.smsTransactionApproved);
        }

        context.pop(true);
        SnackbarService.success(
          widget.transaction == null
              ? BuddyMessages.txnAdded
              : BuddyMessages.txnUpdated,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void showAddTagBottomSheet(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final isarService = ref.read(isarServiceProvider);
    final ctxt = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctxt.transaction_addNewTagText,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: ctxt.transaction_tagNameControllerText,
                  hintText: 'e.g., Travel, Food, Shopping',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final navigator = Navigator.of(sheetContext);
                    final tag = Tag()..name = name;
                    final isar = await isarService.getInstance();
                    await isar.writeTxn(() async {
                      await isar.tags.put(tag);
                    });
                    if (mounted) {
                      setState(() => selectedTags.add(tag));
                      ref.invalidate(tagListProvider);
                      navigator.pop();
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  ctxt.transaction_saveTagButtonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSplitCustomizer() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final controllers = <int, TextEditingController>{};

    for (var p in _selectedParticipants) {
      controllers[p.id] = TextEditingController(
        text: (_splitAmounts[p.id] ?? 0).toString(),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final color = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          double currentSum = 0;
          for (var id in _selectedParticipants.map((p) => p.id)) {
            currentSum += double.tryParse(
                  _splitAmounts[id]?.toString() ?? '0',
                ) ??
                0;
          }
          final isPercentage = _splitType == SplitType.percentage;
          final target = isPercentage ? 100.0 : amount;
          final remaining = target - currentSum;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customize Split',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ctx.pop();
                        _showTripSelector();
                      },
                      child: const Text('Change Trip'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Split Type', style: textTheme.titleSmall),
                    if ((_splitType == SplitType.custom ||
                            _splitType == SplitType.percentage) &&
                        amount > 0)
                      Text(
                        isPercentage
                            ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
                            : 'Remaining: ${formatCurrency(remaining, decimals: 2)}',
                        style: textTheme.labelLarge?.copyWith(
                          color: remaining.abs() < 0.1
                              ? color.primary
                              : (remaining < 0 ? color.error : color.tertiary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<SplitType>(
                  segments: const [
                    ButtonSegment(
                      value: SplitType.equal,
                      label: Text('Equal'),
                      icon: Icon(Icons.pie_chart_outline, size: 16),
                    ),
                    ButtonSegment(
                      value: SplitType.percentage,
                      label: Text('%'),
                      icon: Icon(Icons.percent, size: 16),
                    ),
                    ButtonSegment(
                      value: SplitType.custom,
                      label: Text('Custom'),
                      icon: Icon(Icons.calculate, size: 16),
                    ),
                  ],
                  selected: {_splitType},
                  onSelectionChanged: (Set<SplitType> selected) {
                    setState(() => _splitType = selected.first);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Text('Participants', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _selectedTrip!.participants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = _selectedTrip!.participants.toList()[index];
                      final isSelected =
                          _selectedParticipants.any((sp) => sp.id == p.id);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _selectedParticipants
                                  .removeWhere((sp) => sp.id == p.id);
                              _splitAmounts.remove(p.id);
                            } else {
                              _selectedParticipants.add(p);
                              if (_splitType != SplitType.equal) {
                                _splitAmounts[p.id] = 0.0;
                                controllers[p.id] =
                                    TextEditingController(text: '0');
                              }
                            }
                          });
                          setModalState(() {});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.primaryContainer.withValues(alpha: 0.2)
                                : color.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? color.primary.withValues(alpha: 0.5)
                                  : color.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? color.primary
                                    : color.surfaceContainerHighest,
                                child: Text(
                                  p.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? color.onPrimary
                                        : color.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: (_splitType == SplitType.custom ||
                                            _splitType ==
                                                SplitType.percentage) &&
                                        isSelected
                                    ? Row(
                                        children: [
                                          Text(
                                            p.name,
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_splitType ==
                                                  SplitType.percentage &&
                                              amount > 0)
                                            Text(
                                              '${formatCurrency(amount * (_splitAmounts[p.id] ?? 0) / 100, decimals: 0)}  ',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          SizedBox(
                                            width: 120,
                                            child: TextField(
                                              controller: controllers[p.id],
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration: InputDecoration(
                                                prefixText: _splitType ==
                                                        SplitType.percentage
                                                    ? ''
                                                    : null,
                                                prefix: _splitType != SplitType.percentage ? Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: CurrencyBadge(code: _effectiveCurrency ?? BaseCurrency.code, size: 12),
                                                ) : null,
                                                suffixText: _splitType ==
                                                        SplitType.percentage
                                                    ? '%'
                                                    : null,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    Icons.auto_fix_high,
                                                    size: 18,
                                                    color: color.primary,
                                                  ),
                                                  tooltip:
                                                      'Auto-fill remaining',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    double othersSum = 0;
                                                    for (var sp
                                                        in _selectedParticipants) {
                                                      if (sp.id == p.id) {
                                                        continue;
                                                      }
                                                      othersSum +=
                                                          _splitAmounts[
                                                                  sp.id] ??
                                                              0;
                                                    }
                                                    final remaining =
                                                        target - othersSum;
                                                    setState(
                                                      () =>
                                                          _splitAmounts[p.id] =
                                                              remaining,
                                                    );
                                                    controllers[p.id]!.text =
                                                        remaining
                                                            .toStringAsFixed(
                                                      isPercentage ? 1 : 2,
                                                    );
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _splitAmounts[p.id] =
                                                      double.tryParse(value) ??
                                                          0.0;
                                                });
                                                setModalState(() {});
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        p.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (isSelected && _splitType == SplitType.equal)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: color.primary,
                                )
                              else if (!isSelected)
                                Icon(
                                  Icons.circle_outlined,
                                  color: color.outline,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Paid By', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedTrip!.participants.map((p) {
                    final isSelected = _paidBy?.id == p.id;
                    return ChoiceChip(
                      label: Text(p.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _paidBy = p);
                          setModalState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    for (var c in controllers.values) {
                      c.dispose();
                    }
                    ctx.pop();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTripSelector() {
    final tripsAsync = ref.read(allTripsProvider);

    if (tripsAsync case AsyncData(:final value)) {
      if (!mounted) return;
      final trips = value.where((t) => t.isTrip).toList();

      showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Trip',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('None'),
                  onTap: () {
                    setState(() {
                      _selectedTrip = null;
                      _selectedParticipants.clear();
                      _paidBy = null;
                      _tripManuallyCleared = true;
                    });
                    ctx.pop();
                  },
                ),
                ...trips.map(
                  (trip) => ListTile(
                    leading: Icon(
                      trip.isActive ? Icons.luggage : Icons.luggage_outlined,
                    ),
                    title: Text(trip.name),
                    subtitle: Text(
                      trip.isActive ? 'Active' : 'Inactive',
                    ),
                    selected: _selectedTrip?.id == trip.id,
                    onTap: () {
                      setState(() {
                        _selectedTrip = trip;
                        _selectedParticipants = trip.participants.toList();
                        _paidBy = trip.participants.firstOrNull;
                        _tripManuallyCleared = false;
                      });
                      ctx.pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _checkLowBalance(Account? account) async {
    if (account == null) return;
    final accountsService = ref.read(accountServiceProvider);
    final notificationService = ref.read(notificationRecordServiceProvider);
    final ctxt = AppLocalizations.of(context)!;
    final currentBalance = await accountsService.getAccountBalance(account.id);
    final lowBalanceThreshold =
        SharedPrefsUtil.instance.getLowBalanceThreshold();

    if (currentBalance < lowBalanceThreshold) {
      await notificationService.logNotification(
        title: 'Low Balance Alert',
        body:
            'Your account "${account.name}" has ${formatCurrency(currentBalance, decimals: 2)} remaining.',
        type: 'low_balance',
      );
      await NotificationService.showLocalNotification(
        id: 1000 + account.id,
        title: 'Low Balance Alert',
        body:
            'Your balance in ${account.name} is ${formatCurrency(currentBalance, decimals: 2)}.',
      );
    }
  }

  Future<void> _checkBudgetAlerts(Transaction txn) async {
    if (!txn.isExpense || txn.isTransfer) return;
    final alertService = BudgetAlertService(
      ref.read(isarServiceProvider),
      _notificationsPlugin,
    );

    final alerts = await alertService.checkBudgetsAfterTransaction(txn);
    if (alerts.isNotEmpty) {
      ref.read(budgetAlertsProvider.notifier).addAlerts(alerts);
    }
  }

  void _showUnlockPrompt(int lockedCount) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.lock, size: 32, color: color.primary),
            const SizedBox(height: 12),
            Text(
              'Unlock all $lockedCount accounts with Pro',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Free plan includes ${FreeTierLimits.maxAccounts} accounts. Upgrade to use all your accounts.',
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                ctx.pop();
                context.push(AppRoutes.upgrade);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'See Pro Plans',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
