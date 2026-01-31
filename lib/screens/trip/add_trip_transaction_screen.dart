import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/db/models/trip.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/providers/trip_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class AddTripTransactionScreen extends ConsumerStatefulWidget {
  final int tripId;

  const AddTripTransactionScreen({super.key, required this.tripId});

  @override
  ConsumerState<AddTripTransactionScreen> createState() => _AddTripTransactionScreenState();
}

class _AddTripTransactionScreenState extends ConsumerState<AddTripTransactionScreen> {
  int? _selectedTransactionId;
  int? _paidById;
  SplitType _splitType = SplitType.equal;
  List<int> _selectedParticipants = [];
  final Map<int, TextEditingController> _customAmountControllers = {};

  @override
  void dispose() {
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return Center(child: Text('Trip not found'));

          final transactionsAsync = ref.watch(transactionsByMonthProvider(trip.startDate));
          final participants = trip.participants.toList();
          final transactions = transactionsAsync.valueOrNull ?? [];
          final selectedTxn = _selectedTransactionId == null
              ? null
              : transactions.where((t) => t.id == _selectedTransactionId).firstOrNull;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Transaction Selection
                      _buildSectionHeader(context, 'Select Transaction', Icons.receipt_long_rounded, color.primary),
                      SizedBox(height: 16),
                      transactionsAsync.when(
                        data: (transactions) {
                          final filtered = transactions
                              .where((t) => t.date.isAfter(trip.startDate) && t.date.isBefore(trip.endDate.add(Duration(days: 1))))
                              .toList();

                          if (filtered.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(24),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: color.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.outlineVariant.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: color.outline),
                                  SizedBox(height: 12),
                                  Text(
                                    'No transactions found',
                                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Try adding expenses in the main screen first.',
                                    style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            constraints: BoxConstraints(maxHeight: 240),
                            decoration: BoxDecoration(
                              color: color.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: color.outlineVariant.withValues(alpha: 0.2)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: ListView.separated(
                                padding: EdgeInsets.all(12),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final txn = filtered[index];
                                  final isSelected = _selectedTransactionId == txn.id;
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [color.primaryContainer, color.primaryContainer.withValues(alpha: 0.6)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected ? null : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? color.primary.withValues(alpha: 0.5) : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _selectedTransactionId = txn.id;
                                            _customAmountControllers.clear();
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? color.primary : color.surfaceContainerHighest,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isSelected ? Icons.check : Icons.attach_money_rounded,
                                                  color: isSelected ? color.onPrimary : color.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      txn.description ?? 'Unknown',
                                                      style: textTheme.bodyLarge?.copyWith(
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                        color: isSelected ? color.onPrimaryContainer : color.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${txn.date.day}/${txn.date.month} • ${txn.category.value?.name ?? "Uncategorized"}',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: isSelected ? color.onPrimaryContainer.withValues(alpha: 0.7) : color.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${txn.amount.toStringAsFixed(0)}',
                                                style: textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? color.primary : color.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        loading: () => Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error loading transactions'),
                      ),

                      if (_selectedTransactionId != null) ...[
                        SizedBox(height: 32),
                        
                        // 2. Paid By
                        _buildSectionHeader(context, 'Paid By', Icons.person_rounded, color.secondary),
                        SizedBox(height: 16),
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
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color.secondary : color.surface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: isSelected ? color.secondary : color.outlineVariant,
                                      ),
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: color.secondary.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 4))]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: isSelected ? color.onSecondary : color.secondaryContainer,
                                          child: Text(
                                            p.name[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? color.secondary : color.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            color: isSelected ? color.onSecondary : color.onSurface,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

                        SizedBox(height: 32),

                        // 3. Split Type
                        _buildSectionHeader(context, 'Split Type', Icons.call_split_rounded, color.tertiary),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: SegmentedButton<SplitType>(
                            style: ButtonStyle(
                              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 16)),
                              visualDensity: VisualDensity.comfortable,
                            ),
                            segments: [
                              ButtonSegment(value: SplitType.equal, label: Text('Equally'), icon: Icon(Icons.balance_rounded)),
                              ButtonSegment(value: SplitType.custom, label: Text('Custom'), icon: Icon(Icons.tune_rounded)),
                              ButtonSegment(value: SplitType.percentage, label: Text('%'), icon: Icon(Icons.percent_rounded)),
                            ],
                            selected: {_splitType},
                            onSelectionChanged: (Set<SplitType> newSelection) {
                              HapticFeedback.mediumImpact();
                              setState(() => _splitType = newSelection.first);
                            },
                          ),
                        ),

                        SizedBox(height: 32),

                        // 4. Split With
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(context, 'Split With', Icons.group_rounded, color.primary),
                            if ((_splitType == SplitType.custom || _splitType == SplitType.percentage) && selectedTxn != null)
                              Builder(builder: (context) {
                                double currentSum = 0;
                                for (var id in _selectedParticipants) {
                                  currentSum += double.tryParse(_customAmountControllers[id]?.text ?? '0') ?? 0;
                                }

                                final isPercentage = _splitType == SplitType.percentage;
                                final target = isPercentage ? 100.0 : selectedTxn.amount;
                                final remaining = target - currentSum;
                                final text = isPercentage 
                                    ? 'Remaining: ${remaining.toStringAsFixed(1)}%' 
                                    : 'Remaining: ₹${remaining.toStringAsFixed(2)}';

                                return Text(
                                  text,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: remaining.abs() < 0.1 ? color.primary : (remaining < 0 ? color.error : color.tertiary),
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }),
                          ],
                        ),
                        SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: participants.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = participants[index];
                            final isChecked = _selectedParticipants.contains(p.id);
                            return InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (isChecked) {
                                    _selectedParticipants.remove(p.id);
                                  } else {
                                    _selectedParticipants.add(p.id);
                                    if (_splitType == SplitType.custom) {
                                      _customAmountControllers.putIfAbsent(p.id, () => TextEditingController(text: '0'));
                                    }
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isChecked ? color.primaryContainer.withValues(alpha: 0.2) : color.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isChecked ? color.primary.withValues(alpha: 0.5) : color.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isChecked ? color.primary : color.surfaceContainerHighest,
                                      child: Text(
                                        p.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: isChecked ? color.onPrimary : color.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: (_splitType == SplitType.custom || _splitType == SplitType.percentage) && isChecked
                                          ? Row(
                                              children: [
                                                Text(p.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                                Spacer(),
                                                if (_splitType == SplitType.percentage && selectedTxn != null)
                                                  Text(
                                                    '₹${(selectedTxn.amount * (double.tryParse(_customAmountControllers[p.id]?.text ?? '0') ?? 0) / 100).toStringAsFixed(0)}  ',
                                                    style: textTheme.bodySmall?.copyWith(color: color.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                SizedBox(
                                                  width: 140,
                                                  child: TextField(
                                                    controller: _customAmountControllers.putIfAbsent(p.id, () => TextEditingController(text: '0')),
                                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                    decoration: InputDecoration(
                                                      prefixText: _splitType == SplitType.percentage ? '' : '₹',
                                                      suffixText: _splitType == SplitType.percentage ? '%' : null,
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(Icons.auto_fix_high, size: 18, color: color.primary),
                                                        tooltip: 'Distribute remaining',
                                                        padding: EdgeInsets.zero,
                                                        constraints: BoxConstraints(),
                                                        onPressed: () {
                                                          if (selectedTxn == null) return;
                                                          double othersSum = 0;
                                                          for (var id in _selectedParticipants) {
                                                            if (id == p.id) continue;
                                                            othersSum += double.tryParse(_customAmountControllers[id]?.text ?? '0') ?? 0;
                                                          }
                                                          final isPercentage = _splitType == SplitType.percentage;
                                                          final target = isPercentage ? 100.0 : selectedTxn.amount;
                                                          final remaining = target - othersSum;
                                                          _customAmountControllers[p.id]?.text = remaining.toStringAsFixed(isPercentage ? 1 : 2);
                                                          setState(() {});
                                                        },
                                                      ),
                                                    ),
                                                    onChanged: (_) => setState(() {}), // Rebuild for remaining calc
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              p.name,
                                              style: textTheme.titleMedium?.copyWith(
                                                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                    ),
                                    if (isChecked)
                                      (_splitType == SplitType.custom || _splitType == SplitType.percentage) ? SizedBox.shrink() : Icon(Icons.check_circle_rounded, color: color.primary)
                                    else
                                      Icon(Icons.circle_outlined, color: color.outline),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: color.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    )
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _selectedTransactionId != null && _paidById != null && _selectedParticipants.isNotEmpty
                        ? LinearGradient(
                            colors: [color.primary, color.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _selectedTransactionId != null && _paidById != null && _selectedParticipants.isNotEmpty
                        ? null
                        : color.surfaceContainerHighest,
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedTransactionId != null && _paidById != null && _selectedParticipants.isNotEmpty ? _saveExpense : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'ADD TO TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: _selectedTransactionId != null && _paidById != null && _selectedParticipants.isNotEmpty
                            ? color.onPrimary
                            : color.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _saveExpense() async {
    HapticFeedback.mediumImpact();
    final transaction = await ref.read(transactionProvider).getAll().then((txns) => txns.firstWhere((t) => t.id == _selectedTransactionId));
    
    List<double> splitAmounts = [];

    if (_splitType == SplitType.equal) {
      final amount = transaction.amount;
      splitAmounts = List.filled(_selectedParticipants.length, amount / _selectedParticipants.length);
    } else if (_splitType == SplitType.custom) {
      double sum = 0;
      for (var pId in _selectedParticipants) {
        final val = double.tryParse(_customAmountControllers[pId]?.text ?? '0') ?? 0.0;
        splitAmounts.add(val);
        sum += val;
      }

      if ((sum - transaction.amount).abs() > 0.1) {
        SnackbarService.error('Total split (₹$sum) must match transaction amount (₹${transaction.amount})');
        return;
      }
    } else if (_splitType == SplitType.percentage) {
      double sum = 0;
      for (var pId in _selectedParticipants) {
        final val = double.tryParse(_customAmountControllers[pId]?.text ?? '0') ?? 0.0;
        splitAmounts.add(transaction.amount * (val / 100));
        sum += val;
      }

      if ((sum - 100).abs() > 0.1) {
        SnackbarService.error('Total percentage ($sum%) must equal 100%');
        return;
      }
    }

    await ref.read(tripServiceProvider).addTransactionToTrip(widget.tripId, transaction, _paidById!, _splitType, _selectedParticipants, splitAmounts);
    
    ref.invalidate(tripByIdProvider(widget.tripId));
    if (mounted) {
      SnackbarService.success('Expense added to trip');
      context.pop();
    }
  }
}
