import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_query_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class SmsActivityCard extends ConsumerStatefulWidget {
  final SmsActivity activity;

  const SmsActivityCard({super.key, required this.activity});

  @override
  ConsumerState<SmsActivityCard> createState() => _SmsActivityCardState();
}

class _SmsActivityCardState extends ConsumerState<SmsActivityCard> {
  bool _isExpanded = false;

  Color _getStatusColor(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    switch (widget.activity.status) {
      case ActivityStatus.pending:
        return color.primary;
      case ActivityStatus.needsReview:
        return FinanceColors.statusWarning;
      case ActivityStatus.duplicate:
        return FinanceColors.statusDanger;
      default:
        return color.onSurfaceVariant;
    }
  }

  String _getStatusLabel() {
    switch (widget.activity.status) {
      case ActivityStatus.pending:
        return 'PENDING';
      case ActivityStatus.needsReview:
        return 'NEEDS REVIEW';
      case ActivityStatus.duplicate:
        return 'DUPLICATE';
      default:
        return '';
    }
  }

  Future<void> _addAccount() async {
    final result = await context.push<bool>(
      '/manage-accounts/add',
      extra: {
        'accountNumber': widget.activity.account,
        'bankName': widget.activity.fromBank,
      },
    );

    if (result == true && mounted) {
      // Ask if user wants to auto-approve pending transactions
      final autoApprove = await DialogUtils.showConfirmation(
        context,
        title: 'Auto-approve pending?',
        message:
            'Do you want to automatically approve pending transactions for "${widget.activity.account}"?',
        icon: LucideIcons.circleCheck,
        confirmText: 'Yes',
        cancelText: 'No',
      );

      if (autoApprove == true) {
        await _autoApprovePending();
      }

      // Force refresh accounts provider
      ref.invalidate(accountsProvider);
      ref.invalidate(accountServiceProvider);
      ref.invalidate(transactionProvider);
      ref.invalidate(transactionQueryProvider);

      // Wait a bit for providers to refresh
      await Future.delayed(const Duration(milliseconds: 100));

      // Force rebuild
      if (mounted) setState(() {});
    }
  }

  Future<void> _autoApprovePending() async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    final accounts = await isar.accounts.where().findAll();
    final categories = await isar.categorys.where().findAll();

    Account? matchingAccount;
    try {
      matchingAccount = accounts.firstWhere(
        (a) =>
            a.accountNumber != null &&
            widget.activity.account!.contains(a.accountNumber!),
      );
    } catch (e) {
      return; // No matching account found
    }

    final pendingActivities = await isar.smsActivitys
        .filter()
        .accountEqualTo(widget.activity.account)
        .and()
        .statusEqualTo(ActivityStatus.pending)
        .findAll();

    for (final activity in pendingActivities) {
      final category = CategoryMatcherService.matchCategory(
            activity.body,
            categories,
            activity.isIncome == true,
          ) ??
          categories.firstWhere(
            (c) =>
                c.categoryType ==
                (activity.isIncome == true
                    ? CategoryType.income
                    : CategoryType.expense),
            orElse: () => categories.first,
          );

      await SmsActivityService.instance.approveActivity(
        activity,
        matchingAccount,
        category,
      );
    }
  }

  Future<void> _approve() async {
    if (!mounted) return;

    // Navigate to add transaction screen with pre-filled data
    final transaction = Transaction.create(
      date: widget.activity.date,
      amount: widget.activity.amount ?? 0,
      isExpense: widget.activity.isIncome != true,
      description: widget.activity.body,
    );

    final result = await context.push<bool>(
      AppRoutes.addTransaction,
      extra: {
        'transaction': transaction,
        'smsActivity': widget.activity,
      },
    );

    if (result == true) {
      ref.invalidate(transactionProvider);
      ref.invalidate(transactionQueryProvider);
    }
  }

  Future<void> _reject() async {
    await SmsActivityService.instance.rejectActivity(widget.activity, null);
    ref.invalidate(transactionProvider);
    ref.invalidate(transactionQueryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _getStatusColor(context);

    // Check if account exists in database (only if account was detected in SMS)
    final accountsAsync = ref.watch(accountsProvider);
    final hasUnknownAccount = widget.activity.account != null &&
        accountsAsync.when(
          data: (accounts) {
            // Check if any account number matches (last 4 digits)
            return !accounts.any(
              (a) =>
                  a.accountNumber != null &&
                  widget.activity.account!.contains(a.accountNumber!),
            );
          },
          loading: () => false,
          error: (_, __) => false,
        );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(Tone.current.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(Tone.current.borderRadius),
                        ),
                        child: Icon(
                          widget.activity.isIncome == true
                              ? LucideIcons.arrowDown
                              : LucideIcons.arrowUp,
                          color: statusColor,
                          size: 24.0,
                        ),
                      ),
                      if (hasUnknownAccount)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: FinanceColors.statusWarning,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: color.surface, width: 2),
                            ),
                            child: const Icon(
                              LucideIcons.wallet,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusLabel(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.activity.confidence != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${widget.activity.confidence}%',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.activity.fromBank ?? widget.activity.sender,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.activity.account != null)
                          Text(
                            widget.activity.account!,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.activity.amount != null)
                        CurrencyText(
                          amount: widget.activity.amount!,
                          showSign: true,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.activity.isIncome == true
                                ? color.primary
                                : color.error,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd').format(widget.activity.date),
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (hasUnknownAccount) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            FinanceColors.statusWarning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: FinanceColors.statusWarning
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            color: FinanceColors.statusWarning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Account "${widget.activity.account}" not found. Add it first.',
                              style: textTheme.bodySmall?.copyWith(
                                  color: FinanceColors.statusWarning,),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reject,
                          icon: const Icon(LucideIcons.x, size: 18),
                          label: const Text('REJECT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color.error,
                            side: BorderSide(color: color.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: hasUnknownAccount ? _addAccount : _approve,
                          icon: Icon(
                            hasUnknownAccount
                                ? LucideIcons.plus
                                : LucideIcons.check,
                            size: 18,
                          ),
                          label: Text(
                            hasUnknownAccount ? 'ADD ACCOUNT' : 'APPROVE',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
