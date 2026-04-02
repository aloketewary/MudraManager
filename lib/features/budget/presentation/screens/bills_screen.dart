import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/bill_service.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';

final billsProvider = StreamProvider<List<RecurringBill>>((ref) {
  final isar = Isar.getInstance()!;
  return isar.recurringBills.where().watch(fireImmediately: true);
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(Icons.receipt_long, size: 64, color: color.primary),
                      const SizedBox(height: 16),
                      Text(
                        'How Bills Work',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Track recurring bills like rent, subscriptions, and utilities. Get reminders before due dates and mark bills as paid.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => ctx.pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
      ),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noBills,
              iconData: Icons.receipt_long_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _buildBillCard(context, bill, color, textTheme, isGuestMode);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) => const TransactionCardSkeleton(),
        ),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildBillCard(
    BuildContext context,
    RecurringBill bill,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
  ) {
    final displayAmount = GuestModeUtil.applyGuestMode(bill.amount, isGuestMode);
    final daysUntilDue =
        bill.nextDueDate?.difference(DateTime.now()).inDays ?? 0;
    final isOverdue = daysUntilDue < 0;
    final isDueSoon = daysUntilDue <= 3 && daysUntilDue >= 0;

    final billColor = isOverdue
        ? color.error
        : isDueSoon
        ? color.tertiary
        : color.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: billColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: billColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${displayAmount.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(
                        color: billColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bill.nextDueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: color.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(bill.nextDueDate!),
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: billColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bill.frequency.name.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: billColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: color.onSurfaceVariant),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'paid',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: color.primary),
                        const SizedBox(width: 8),
                        const Text('Mark as Paid'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: color.error),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: color.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'paid') {
                    await BillService.markBillAsPaid(bill.id);
                    SnackbarService.success(BuddyMessages.billPaid);
                  } else if (value == 'delete') {
                    final confirmed = await DialogUtils.showDeleteConfirmation(
                      context,
                      title: 'Delete Bill',
                      
                    );
                    if (confirmed == true) {
                      final isar = Isar.getInstance()!;
                      await isar.writeTxn(
                        () => isar.recurringBills.delete(bill.id),
                      );
                      SnackbarService.success(BuddyMessages.billDeleted);
                    }
                  }
                },
              ),
            ],
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                          color: color.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: color.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Add New Bill',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Bill Name',
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: color.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: color.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BillFrequency>(
                    initialValue: selectedFrequency,
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      prefixIcon: Icon(Icons.repeat, color: color.primary),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: BillFrequency.monthly,
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: BillFrequency.quarterly,
                        child: Text('Quarterly'),
                      ),
                      DropdownMenuItem(
                        value: BillFrequency.yearly,
                        child: Text('Yearly'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setState(() => selectedFrequency = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHighest,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: color.primary),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(selectedDate),
                                  style: textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (nameController.text.isEmpty ||
                                  amountController.text.isEmpty) {
                                SnackbarService.error(BuddyMessages.fillAllFields);
                                return;
                              }

                              final bill = RecurringBill.create(
                                name: nameController.text,
                                amount: double.parse(amountController.text),
                                dueDate: selectedDate,
                                frequency: selectedFrequency,
                              );

                              final isar = Isar.getInstance()!;
                              await isar.writeTxn(
                                () => isar.recurringBills.put(bill),
                              );

                              Navigator.pop(context);
                              SnackbarService.success(BuddyMessages.billAdded);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Add Bill'),
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
      ),
    );
  }
}
