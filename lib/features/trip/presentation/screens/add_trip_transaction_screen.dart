import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';

class AddTripTransactionScreen extends ConsumerStatefulWidget {
  final int tripId;

  const AddTripTransactionScreen({super.key, required this.tripId});

  @override
  ConsumerState<AddTripTransactionScreen> createState() =>
      _AddTripTransactionScreenState();
}

class _AddTripTransactionScreenState
    extends ConsumerState<AddTripTransactionScreen> {
  // ── Group mode (create split expense) ──
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  // ── Shared split fields ──
  int? _paidById;
  SplitType _splitType = SplitType.equal;
  final List<int> _selectedParticipants = [];
  final Map<int, TextEditingController> _customAmountControllers = {};
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    for (var c in _customAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The amount used for split calculations.
  double? get _resolvedAmount {
    // Group mode: from text field
    if (_amountController.text.isNotEmpty) {
      return double.tryParse(_amountController.text);
    }
    return null;
  }

  bool get _canSave {
    if (_saving) return false;
    if (_paidById == null || _selectedParticipants.isEmpty) return false;
    // Group mode needs amount
    return _resolvedAmount != null && _resolvedAmount! > 0;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) return const Center(child: Text('Trip not found'));

        final participants = trip.participants.toList();
        final amount = _resolvedAmount ?? 0.0;

        final tripCurrency = trip.currencyCode;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Add Split Expense',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  children: [
                    // ── Amount ──
                    _buildSectionHeader(
                      context,
                      'Amount',
                      currencyIcon(tripCurrency),
                      color.primary,
                    ),
                    SizedBox(height: spacing.elementGap),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color.primary,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefix: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CurrencyBadge(code: tripCurrency ?? BaseCurrency.code, size: 24, color: color.primary.withValues(alpha: 0.6)),
                      ),
                        hintText: '0',
                        hintStyle: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.primary.withValues(alpha: 0.2),
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: color.primary.withValues(alpha: 0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.elementGap),

                    // ── Description ──
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        prefixIcon: Icon(LucideIcons.fileText,
                            size: 18, color: color.onSurfaceVariant,),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color:
                                color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color:
                                color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // ── Paid By ──
                    _buildSectionHeader(
                      context,
                      'Paid By',
                      LucideIcons.user,
                      color.secondary,
                    ),
                    SizedBox(height: spacing.elementGap),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: participants.map((p) {
                          final isSelected = _paidById == p.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _paidById = p.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.secondary
                                      : color.surface,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? color.secondary
                                        : color.outlineVariant,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.secondary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isSelected
                                          ? color.onSecondary
                                          : color.secondaryContainer,
                                      child: Text(
                                        p.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? color.secondary
                                              : color.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? color.onSecondary
                                            : color.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // ── Split Type ──
                    _buildSectionHeader(
                      context,
                      'Split Type',
                      LucideIcons.split,
                      color.tertiary,
                    ),
                    SizedBox(height: spacing.elementGap),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: SegmentedButton<SplitType>(
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                          visualDensity: VisualDensity.comfortable,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: SplitType.equal,
                            label: Text('Equally'),
                            icon: Icon(LucideIcons.scale),
                          ),
                          ButtonSegment(
                            value: SplitType.custom,
                            label: Text('Custom'),
                            icon: Icon(LucideIcons.slidersHorizontal),
                          ),
                          ButtonSegment(
                            value: SplitType.percentage,
                            label: Text('%'),
                            icon: Icon(LucideIcons.percent),
                          ),
                        ],
                        selected: {_splitType},
                        onSelectionChanged: (s) {
                          HapticFeedback.mediumImpact();
                          setState(() => _splitType = s.first);
                        },
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // ── Split With ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          context,
                          'Split With',
                          LucideIcons.users,
                          color.primary,
                        ),
                        if ((_splitType == SplitType.custom ||
                                _splitType == SplitType.percentage) &&
                            amount > 0)
                          Builder(
                            builder: (_) {
                              double sum = 0;
                              for (var id in _selectedParticipants) {
                                sum += double.tryParse(
                                        _customAmountControllers[id]?.text ??
                                            '0',) ??
                                    0;
                              }
                              final isPercent =
                                  _splitType == SplitType.percentage;
                              final target = isPercent ? 100.0 : amount;
                              final remaining = target - sum;
                              return Text(
                                isPercent
                                    ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
                                    : 'Remaining: ${formatCurrency(remaining, code: tripCurrency, decimals: 2)}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: remaining.abs() < 0.1
                                      ? color.primary
                                      : (remaining < 0
                                          ? color.error
                                          : color.tertiary),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGap),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: participants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = participants[index];
                        final isChecked =
                            _selectedParticipants.contains(p.id);
                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isChecked) {
                                _selectedParticipants.remove(p.id);
                              } else {
                                _selectedParticipants.add(p.id);
                                if (_splitType != SplitType.equal) {
                                  _customAmountControllers.putIfAbsent(
                                    p.id,
                                    () => TextEditingController(text: '0'),
                                  );
                                }
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? color.primaryContainer
                                      .withValues(alpha: 0.2)
                                  : color.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isChecked
                                    ? color.primary.withValues(alpha: 0.5)
                                    : color.outlineVariant
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isChecked
                                      ? color.primary
                                      : color.surfaceContainerHighest,
                                  child: Text(
                                    p.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isChecked
                                          ? color.onPrimary
                                          : color.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: (_splitType != SplitType.equal &&
                                          isChecked)
                                      ? _buildCustomSplitRow(
                                          p, amount, color, textTheme,)
                                      : Text(
                                          p.name,
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            fontWeight: isChecked
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                ),
                                if (isChecked &&
                                    _splitType == SplitType.equal)
                                  Icon(LucideIcons.circleCheck,
                                      color: color.primary,)
                                else if (!isChecked)
                                  Icon(LucideIcons.circle,
                                      color: color.outline,),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Save ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardHorizontal,
                  spacing.elementGap,
                  spacing.cardHorizontal,
                  spacing.cardHorizontalMax +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: FilledButton(
                  onPressed: _canSave ? () => _save(trip) : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
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
                          trip.isTrip ? 'Add to Trip' : 'Add to Group',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        body: ListView(children: List.generate(3, (_) => const DashboardCardSkeleton())),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildCustomSplitRow(
    TripParticipant p,
    double amount,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final isPercent = _splitType == SplitType.percentage;
    return Row(
      children: [
        Text(
          p.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (isPercent && amount > 0)
          Text(
            '${formatCurrency((amount * (double.tryParse(_customAmountControllers[p.id]?.text ?? '0') ?? 0) / 100), decimals: 0)}  ',
            style: textTheme.bodySmall?.copyWith(
              color: color.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _customAmountControllers.putIfAbsent(
              p.id,
              () => TextEditingController(text: '0'),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefix: isPercent ? null : Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CurrencyBadge(code: BaseCurrency.code, size: 12),
                ),
              suffixText: isPercent ? '%' : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(LucideIcons.wand,
                    size: 18, color: color.primary,),
                tooltip: 'Auto-fill remaining',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  double othersSum = 0;
                  for (var id in _selectedParticipants) {
                    if (id == p.id) continue;
                    othersSum += double.tryParse(
                            _customAmountControllers[id]?.text ?? '0',) ??
                        0;
                  }
                  final target = isPercent ? 100.0 : amount;
                  final remaining = target - othersSum;
                  _customAmountControllers[p.id]?.text =
                      remaining.toStringAsFixed(isPercent ? 1 : 2);
                  setState(() {});
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _save(Trip trip) async {
    final amount = _resolvedAmount;
    if (amount == null || amount <= 0) {
      SnackbarService.error(BuddyMessages.invalidAmount);
      return;
    }
    if (_paidById == null) {
      SnackbarService.error(BuddyMessages.fillAllFields);
      return;
    }
    if (_selectedParticipants.isEmpty) {
      SnackbarService.error(BuddyMessages.addParticipant);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final splitAmounts = _computeSplitAmounts(amount);
      if (splitAmounts == null) return; // validation error shown inside

      final expense = SplitExpense.create(
        amount: amount,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        date: DateTime.now(),
      );

      // Snapshot currency conversion
      if (trip.currencyCode != null) {
        expense.currencyCode = trip.currencyCode;
        final currencyService =
            await ref.read(currencyServiceProvider.future);
        final result =
            await currencyService.convertToBase(amount, trip.currencyCode!);
        if (result != null) {
          expense.convertedAmount = result.converted;
          expense.rateUsed = result.rate;
        }
      }

      await ref.read(tripServiceProvider).addSplitExpenseToTrip(
            widget.tripId,
            expense,
            _paidById!,
            _splitType,
            _selectedParticipants,
            splitAmounts,
          );

      ref.invalidate(tripByIdProvider(widget.tripId));
      if (mounted) {
        SnackbarService.success(
          BuddyMessages.expenseAddedToTrip(trip.isTrip),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<double>? _computeSplitAmounts(double amount) {
    if (_splitType == SplitType.equal) {
      return List.filled(
        _selectedParticipants.length,
        amount / _selectedParticipants.length,
      );
    }

    if (_splitType == SplitType.custom) {
      double sum = 0;
      final amounts = <double>[];
      for (var id in _selectedParticipants) {
        final val = double.tryParse(
                _customAmountControllers[id]?.text ?? '0',) ??
            0.0;
        amounts.add(val);
        sum += val;
      }
      if ((sum - amount).abs() > 0.1) {
        SnackbarService.error(
          'Total split (${formatCurrency(sum, decimals: 0)}) must match ${formatCurrency(amount, decimals: 0)}',
        );
        setState(() => _saving = false);
        return null;
      }
      return amounts;
    }

    if (_splitType == SplitType.percentage) {
      double sum = 0;
      final amounts = <double>[];
      for (var id in _selectedParticipants) {
        final pct = double.tryParse(
                _customAmountControllers[id]?.text ?? '0',) ??
            0.0;
        amounts.add(amount * (pct / 100));
        sum += pct;
      }
      if ((sum - 100).abs() > 0.1) {
        SnackbarService.error(
            'Total percentage (${sum.toStringAsFixed(1)}%) must equal 100%',);
        setState(() => _saving = false);
        return null;
      }
      return amounts;
    }

    return null;
  }
}
