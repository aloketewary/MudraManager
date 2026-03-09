import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final int expenseId;
  final int tripId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.tripId,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  List<TripParticipant> _selectedParticipants = [];
  TripParticipant? _paidBy;
  SplitType _splitType = SplitType.equal;
  Map<int, double> _splitAmounts = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _initializeData(TripTransaction tripTxn, Trip trip) {
    if (_isInitialized) return;
    final txn = tripTxn.transaction.value;
    if (txn == null) return;
    _amountController.text = txn.amount.toString();
    _descController.text = txn.description ?? '';
    _selectedParticipants = trip.participants.toList();
    _paidBy = trip.participants.firstOrNull;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: color.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: color.error)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'delete') _deleteExpense();
            },
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return const Center(child: Text('Trip not found'));
          final tripTxn = trip.transactions
              .where((t) => t.id == widget.expenseId)
              .firstOrNull;
          if (tripTxn == null) {
            return const Center(child: Text('Expense not found'));
          }
          
          final expense = tripTxn.transaction.value;
          if (expense == null) {
            return const Center(child: Text('Expense not found'));
          }

          _initializeData(tripTxn, trip);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.primaryContainer,
                          child: Icon(
                            Icons.receipt_long,
                            color: color.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.category.value?.name ?? 'Expense',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: color.surface,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.notes),
                            hintText: 'Optional',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: color.surface,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Split Details',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _editSplit(trip),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Split'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Split ${_selectedParticipants.length} ways',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedParticipants
                                    .map((p) => p.name)
                                    .join(', '),
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              if (_amountController.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '₹${(double.tryParse(_amountController.text) ?? 0) / _selectedParticipants.length} per person',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _saveExpense(tripTxn, trip),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _editSplit(Trip trip) {
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
        builder: (ctx, setModalState) {
          final color = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          
          double currentSum = 0;
          for (var id in _selectedParticipants.map((p) => p.id)) {
            currentSum += _splitAmounts[id] ?? 0;
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
                Text(
                  'Edit Split',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Split Type', style: textTheme.titleSmall),
                    if ((_splitType == SplitType.custom || _splitType == SplitType.percentage) && amount > 0)
                      Text(
                        isPercentage
                            ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
                            : 'Remaining: ₹${remaining.toStringAsFixed(2)}',
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
                    itemCount: trip.participants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = trip.participants.toList()[index];
                      final isSelected = _selectedParticipants.any((sp) => sp.id == p.id);
                      
                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _selectedParticipants.removeWhere((sp) => sp.id == p.id);
                              _splitAmounts.remove(p.id);
                            } else {
                              _selectedParticipants.add(p);
                              if (_splitType != SplitType.equal) {
                                _splitAmounts[p.id] = 0.0;
                                controllers[p.id] = TextEditingController(text: '0');
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
                                child: (_splitType == SplitType.custom || _splitType == SplitType.percentage) && isSelected
                                    ? Row(
                                        children: [
                                          Text(
                                            p.name,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_splitType == SplitType.percentage && amount > 0)
                                            Text(
                                              '₹${(amount * (_splitAmounts[p.id] ?? 0) / 100).toStringAsFixed(0)}  ',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: color.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          SizedBox(
                                            width: 120,
                                            child: TextField(
                                              controller: controllers[p.id],
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                prefixText: _splitType == SplitType.percentage ? '' : '₹',
                                                suffixText: _splitType == SplitType.percentage ? '%' : null,
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(Icons.auto_fix_high, size: 18, color: color.primary),
                                                  tooltip: 'Auto-fill remaining',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    double othersSum = 0;
                                                    for (var sp in _selectedParticipants) {
                                                      if (sp.id == p.id) continue;
                                                      othersSum += _splitAmounts[sp.id] ?? 0;
                                                    }
                                                    final remaining = target - othersSum;
                                                    setState(() => _splitAmounts[p.id] = remaining);
                                                    controllers[p.id]!.text = remaining.toStringAsFixed(
                                                      isPercentage ? 1 : 2,
                                                    );
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _splitAmounts[p.id] = double.tryParse(value) ?? 0.0;
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
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (isSelected && _splitType == SplitType.equal)
                                Icon(Icons.check_circle_rounded, color: color.primary)
                              else if (!isSelected)
                                Icon(Icons.circle_outlined, color: color.outline),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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

  Future<void> _saveExpense(TripTransaction tripTxn, Trip trip) async {
    final expense = tripTxn.transaction.value;
    if (expense == null) return;
    
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      SnackbarService.error('Enter valid amount');
      return;
    }
    if (_selectedParticipants.isEmpty) {
      SnackbarService.error('Select at least one participant');
      return;
    }

    HapticFeedback.mediumImpact();

    expense.amount = amount;
    expense.description = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();

    final isar = await ref.read(tripServiceProvider).isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.transactions.put(expense);
    });

    ref.invalidate(tripByIdProvider(widget.tripId));

    SnackbarService.success('Recalculating group debts...');
    if (mounted) context.pop();
  }

  Future<void> _deleteExpense() async {
    final confirm = await DialogUtils.showConfirmation(
      context,
      title: 'Delete Expense',
      message: 'This will adjust everyone\'s balance. Continue?',
      confirmText: 'Delete',
      icon: Icons.delete_forever,
    );
    if (confirm != true) return;

    await ref.read(tripServiceProvider).removeTripTransaction(
      widget.tripId,
      widget.expenseId,
    );
    ref.invalidate(tripByIdProvider(widget.tripId));

    SnackbarService.success('Expense deleted');
    if (mounted) context.pop();
  }
}
