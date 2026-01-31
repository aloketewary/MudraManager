import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/recurring_bill.dart';
import 'package:mudra_manager/service/bill_service.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

final billsProvider = StreamProvider<List<RecurringBill>>((ref) {
  final isar = Isar.getInstance()!;
  return isar.recurringBills.where().watch(fireImmediately: true);
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
      ),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color.primaryContainer, color.secondaryContainer],
                      ),
                    ),
                    child: Icon(Icons.receipt_long_outlined, size: 64, color: color.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('No bills yet', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Add your recurring bills to track them', style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _buildBillCard(context, bill, color, textTheme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, RecurringBill bill, ColorScheme color, TextTheme textTheme) {
    final daysUntilDue = bill.nextDueDate?.difference(DateTime.now()).inDays ?? 0;
    final isOverdue = daysUntilDue < 0;
    final isDueSoon = daysUntilDue <= 3 && daysUntilDue >= 0;

    final gradientColors = isOverdue 
        ? [Colors.red.shade400, Colors.red.shade600]
        : isDueSoon 
            ? [Colors.orange.shade400, Colors.orange.shade600]
            : [color.primary, color.secondary];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.name, style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('₹${bill.amount.toStringAsFixed(0)}', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      if (bill.nextDueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(bill.nextDueDate!),
                              style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bill.frequency.name.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'paid', child: Row(children: [Icon(Icons.check_circle_outline), SizedBox(width: 8), Text('Mark as Paid')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline), SizedBox(width: 8), Text('Delete')])),
                  ],
                  onSelected: (value) async {
                    if (value == 'paid') {
                      await BillService.markBillAsPaid(bill.id);
                      SnackbarService.success('Bill marked as paid');
                    } else if (value == 'delete') {
                      final confirmed = await DialogUtils.showDeleteConfirmation(
                        context,
                        title: 'Delete Bill',
                        message: 'Are you sure you want to delete this bill?',
                      );
                      if (confirmed == true) {
                        final isar = Isar.getInstance()!;
                        await isar.writeTxn(() => isar.recurringBills.delete(bill.id));
                        SnackbarService.success('Bill deleted');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBillSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    BillFrequency selectedFrequency = BillFrequency.monthly;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.primary, color.secondary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Text('Add New Bill', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Bill Name',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillFrequency>(
                  value: selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: const Icon(Icons.repeat),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: BillFrequency.monthly, child: Text('Monthly')),
                    DropdownMenuItem(value: BillFrequency.quarterly, child: Text('Quarterly')),
                    DropdownMenuItem(value: BillFrequency.yearly, child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedFrequency = value);
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: color.primary),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Due Date', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || amountController.text.isEmpty) {
                            SnackbarService.error('Please fill all fields');
                            return;
                          }

                          final bill = RecurringBill.create(
                            name: nameController.text,
                            amount: double.parse(amountController.text),
                            dueDate: selectedDate,
                            frequency: selectedFrequency,
                          );

                          final isar = Isar.getInstance()!;
                          await isar.writeTxn(() => isar.recurringBills.put(bill));
                          
                          Navigator.pop(context);
                          SnackbarService.success('Bill added');
                        },
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Add Bill'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
