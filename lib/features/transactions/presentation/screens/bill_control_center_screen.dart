import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class BillControlCenterScreen extends ConsumerStatefulWidget {
  const BillControlCenterScreen({super.key});

  @override
  ConsumerState<BillControlCenterScreen> createState() =>
      _BillControlCenterScreenState();
}

class _BillControlCenterScreenState
    extends ConsumerState<BillControlCenterScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: recurringAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Bill Control Center'),
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.plus),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.addRecurring);
                      },
                    ),
                  ],
                ),
                SliverFillRemaining(
                  child: NoDataFound(
                    message: BuddyMessages.noBills,
                    iconData: LucideIcons.receipt,
                  ),
                ),
              ],
            );
          }

          final activeBills = bills.where((b) => b.isActive).toList();
          final now = DateTime.now();
          final overdueBills =
              activeBills.where((b) => b.nextDueDate.isBefore(now)).toList();
          final dueSoonBills = activeBills
              .where(
                (b) =>
                    b.nextDueDate.isAfter(now) &&
                    b.nextDueDate.difference(now).inDays <= 7,
              )
              .toList();
          final upcomingBills = activeBills
              .where((b) => b.nextDueDate.difference(now).inDays > 7)
              .toList();

          // Sort by due date
          overdueBills.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          dueSoonBills.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          upcomingBills.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

          return accountsAsync.when(
            data: (accounts) {
              final totalBalance =
                  accounts.fold(0.0, (sum, a) => sum + a.initialBalance);
              final upcomingTotal =
                  activeBills.fold(0.0, (sum, b) => sum + b.amount);
              final safeToSpend = totalBalance - upcomingTotal;
              final overdueTotal =
                  overdueBills.fold(0.0, (sum, b) => sum + b.amount);
              final dueSoonTotal =
                  dueSoonBills.fold(0.0, (sum, b) => sum + b.amount);

              return CustomScrollView(
                slivers: [
                  // Modern SliverAppBar with Stats
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    elevation: 0,
                    title: LayoutBuilder(
                      builder: (context, constraints) {
                        return const Text(
                          'Bill Control Center',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.push(AppRoutes.addRecurring);
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Opacity(
                                opacity:
                                    constraints.maxHeight > 100 ? 1.0 : 0.0,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    spacing.cardHorizontal,
                                    spacing.sectionGap * 3,
                                    spacing.cardHorizontal,
                                    spacing.sectionGap,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                              spacing.elementGap,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                spacing.radiusMedium,
                                              ),
                                            ),
                                            child: Icon(
                                              LucideIcons.receiptText,
                                              color: colorScheme.primary,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: spacing.elementGap),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Text(
                                                //   'Bill Control Center',
                                                //   style: textTheme.headlineSmall
                                                //       ?.copyWith(
                                                //     fontWeight: FontWeight.bold,
                                                //     color: colorScheme
                                                //         .onPrimaryContainer,
                                                //   ),
                                                // ),
                                                Text(
                                                  '${activeBills.length} Active Bills',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onPrimaryContainer
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding:
                                            EdgeInsets.all(spacing.cardInner),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusLarge,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Safe to Spend',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          spacing.elementGap *
                                                              0.5,
                                                    ),
                                                    CurrencyText(
                                                      amount: safeToSpend,
                                                      fixedLength: 0,
                                                      compact: false,
                                                      showSign: true,
                                                      showPositiveSign: false,
                                                      style: textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: safeToSpend < 0
                                                            ? colorScheme.error
                                                            : const Color(
                                                                0xFF10B981,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(
                                                    spacing.elementGap,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (safeToSpend < 0
                                                            ? colorScheme.error
                                                            : const Color(
                                                                0xFF10B981,
                                                              ))
                                                        .withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      spacing.radiusMedium,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    safeToSpend < 0
                                                        ? LucideIcons
                                                            .triangleAlert
                                                        : LucideIcons
                                                            .circleCheck,
                                                    color: safeToSpend < 0
                                                        ? colorScheme.error
                                                        : const Color(
                                                            0xFF10B981,
                                                          ),
                                                    size: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: spacing.elementGap,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildQuickStat(
                                                    'Balance',
                                                    totalBalance,
                                                    colorScheme,
                                                    textTheme,
                                                    spacing,
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 30,
                                                  color: colorScheme
                                                      .outlineVariant
                                                      .withValues(alpha: 0.5),
                                                ),
                                                Expanded(
                                                  child: _buildQuickStat(
                                                    'Total Bills',
                                                    upcomingTotal,
                                                    colorScheme,
                                                    textTheme,
                                                    spacing,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alert Cards
                  if (overdueBills.isNotEmpty || dueSoonBills.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontal,
                          vertical: spacing.cardVertical,
                        ),
                        child: Column(
                          children: [
                            if (overdueBills.isNotEmpty)
                              _buildAlertCard(
                                'Overdue Bills',
                                '${overdueBills.length} bills • ₹${overdueTotal.toStringAsFixed(0)}',
                                LucideIcons.circleAlert,
                                colorScheme.error,
                                colorScheme,
                                textTheme,
                                spacing,
                              ),
                            if (overdueBills.isNotEmpty &&
                                dueSoonBills.isNotEmpty)
                              SizedBox(height: spacing.elementGap),
                            if (dueSoonBills.isNotEmpty)
                              _buildAlertCard(
                                'Due This Week',
                                '${dueSoonBills.length} bills • ₹${dueSoonTotal.toStringAsFixed(0)}',
                                LucideIcons.clock,
                                colorScheme.tertiary,
                                colorScheme,
                                textTheme,
                                spacing,
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'All',
                              activeBills.length,
                              colorScheme,
                              textTheme,
                              spacing,
                            ),
                            SizedBox(width: spacing.elementGap),
                            _buildFilterChip(
                              'Overdue',
                              overdueBills.length,
                              colorScheme,
                              textTheme,
                              spacing,
                            ),
                            SizedBox(width: spacing.elementGap),
                            _buildFilterChip(
                              'Due Soon',
                              dueSoonBills.length,
                              colorScheme,
                              textTheme,
                              spacing,
                            ),
                            SizedBox(width: spacing.elementGap),
                            _buildFilterChip(
                              'Upcoming',
                              upcomingBills.length,
                              colorScheme,
                              textTheme,
                              spacing,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bills List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          List<RecurringTransaction> filteredBills;
                          switch (_selectedFilter) {
                            case 'Overdue':
                              filteredBills = overdueBills;
                              break;
                            case 'Due Soon':
                              filteredBills = dueSoonBills;
                              break;
                            case 'Upcoming':
                              filteredBills = upcomingBills;
                              break;
                            default:
                              filteredBills = activeBills
                                ..sort(
                                  (a, b) =>
                                      a.nextDueDate.compareTo(b.nextDueDate),
                                );
                          }

                          if (index >= filteredBills.length) return null;

                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: spacing.elementGap),
                            child: _buildBillCard(
                              filteredBills[index],
                              colorScheme,
                              textTheme,
                              spacing,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: spacing.sectionGap * 5),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Center(child: Text(BuddyMessages.genericError)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    double value,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.elementGap * 0.5),
          CurrencyText(
            amount: value,
            fixedLength: 0,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String subtitle,
    IconData icon,
    Color alertColor,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            alertColor.withValues(alpha: 0.15),
            alertColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Icon(
              icon,
              color: alertColor,
              size: 24,
            ),
          ),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: alertColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int count,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: isSelected ? 2 : 1,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGap * 0.5,
      ),
    );
  }

  Widget _buildBillCard(
    RecurringTransaction bill,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final now = DateTime.now();
    final daysUntil = bill.nextDueDate.difference(now).inDays;
    final isOverdue = daysUntil < 0;
    final isDueSoon = daysUntil >= 0 && daysUntil <= 7;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOverdue) {
      statusColor = colorScheme.error;
      statusText = '${daysUntil.abs()} days overdue';
      statusIcon = LucideIcons.circleAlert;
    } else if (isDueSoon) {
      statusColor = colorScheme.tertiary;
      statusText = daysUntil == 0
          ? 'Due today'
          : daysUntil == 1
              ? 'Due tomorrow'
              : 'Due in $daysUntil days';
      statusIcon = LucideIcons.clock;
    } else {
      statusColor = colorScheme.primary;
      statusText = 'Due ${DateFormat('MMM d').format(bill.nextDueDate)}';
      statusIcon = LucideIcons.calendar;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: isOverdue
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.addRecurring, extra: {'recurring': bill}),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      IconHelper.iconFromName(
                        bill.category.value?.iconName ?? 'category',
                      ),
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.category.value?.name ?? 'Unknown',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: spacing.elementGap * 0.25),
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            SizedBox(width: spacing.elementGap * 0.5),
                            Text(
                              statusText,
                              style: textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' • ${_getFrequencyText(bill.frequency)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.amount.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      if (isOverdue || isDueSoon)
                        Container(
                          margin:
                              EdgeInsets.only(top: spacing.elementGap * 0.5),
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.elementGap * 0.75,
                            vertical: spacing.elementGap * 0.25,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : 'URGENT',
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 1.5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .push(AppRoutes.addRecurring, extra: {'recurring': bill}),
                      icon: const Icon(LucideIcons.settings, size: 16),
                      label: const Text('Manage'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: spacing.elementGap),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _markAsPaid(bill);
                      },
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Mark Paid'),
                      style: FilledButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: spacing.elementGap),
                        backgroundColor: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsPaid(RecurringTransaction bill) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );

    // Check if bill is in the future
    if (dueDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.circleAlert, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cannot mark future bills as paid. Due on ${DateFormat('MMM d').format(bill.nextDueDate)}',
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isar = await ref.read(isarServiceProvider).getInstance();

    try {
      // Create a transaction for this bill payment
      final transaction = Transaction.create(
        date: DateTime.now(),
        amount: bill.amount,
        isExpense: bill.isExpense,
        description: bill.description?.isNotEmpty == true
            ? '${bill.description} (Paid)'
            : '${bill.category.value?.name ?? "Bill"} (Paid)',
      )
        ..account.value = bill.account.value
        ..category.value = bill.category.value
        ..recurringTransactionSource.value = bill;

      // Save the transaction
      await isar.writeTxn(() async {
        await isar.transactions.put(transaction);
        await transaction.account.save();
        await transaction.category.save();
        await transaction.recurringTransactionSource.save();
      });

      // Update next due date
      final nextDate = calculateNextDueDate(
        bill.nextDueDate,
        bill.frequency,
        bill.startDate,
      );

      if (bill.endDate != null && nextDate.isAfter(bill.endDate!)) {
        bill.isActive = false;
      } else {
        bill.nextDueDate = nextDate;
      }

      await isar.writeTxn(() async {
        await isar.recurringTransactions.put(bill);
      });
      ref.invalidate(transactionProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        SnackbarService.success('${bill.category.value?.name} marked as paid');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.error(BuddyMessages.errorWith('$e'));
      }
    }
  }

  String _getFrequencyText(Frequency freq) => switch (freq) {
        Frequency.daily => 'Daily',
        Frequency.weekly => 'Weekly',
        Frequency.monthly => 'Monthly',
        Frequency.yearly => 'Yearly',
      };
}
