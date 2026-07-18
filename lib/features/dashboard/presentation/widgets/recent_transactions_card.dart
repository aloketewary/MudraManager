import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart' as db;
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class RecentTransactionsCard extends ConsumerWidget {
  final int maxTransactions;

  const RecentTransactionsCard({
    super.key,
    this.maxTransactions = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final transactions = ref.watch(dashboardTransactionsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    if (transactions.isEmpty) return const SizedBox.shrink();

    // Get recent transactions (sorted by date, most recent first)
    // Using toList() to create stable reference for rebuild optimization
    final recentTransactions = List<db.Transaction>.from(
      transactions.where((t) => !t.isTransfer).take(maxTransactions),
    );

    return _RecentTransactionsCardContent(
      recentTransactions: recentTransactions,
      isGuestMode: isGuestMode,
      spacing: spacing,
      color: color,
      textTheme: textTheme,
      ctxt: ctxt,
    );
  }
}

class _RecentTransactionsCardContent extends StatelessWidget {
  final List<db.Transaction> recentTransactions;
  final bool isGuestMode;
  final AppSpacing spacing;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _RecentTransactionsCardContent({
    required this.recentTransactions,
    required this.isGuestMode,
    required this.spacing,
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Divider(height: 1, color: color.primary.withValues(alpha: 0.12)),
            ...List.generate(
              recentTransactions.length,
              (index) => _TransactionItem(
                transaction: recentTransactions[index],
                index: index,
                isGuestMode: isGuestMode,
                spacing: spacing,
                color: color,
                textTheme: textTheme,
                ctxt: ctxt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.transactions);
      },
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGapMin + 4),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(
                LucideIcons.receiptText,
                color: color.primary,
                size: spacing.iconMD,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            AdaptiveText(
              ctxt.statistics_recentTransactionsTitleText,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
            const Spacer(),
            Semantics(
              label: 'See all transactions',
              button: true,
              child: Padding(
                padding: EdgeInsets.all(spacing.elementGapMin),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: color.onSurface,
                  size: spacing.iconMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends ConsumerWidget {
  final db.Transaction transaction;
  final int index;
  final bool isGuestMode;
  final AppSpacing spacing;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _TransactionItem({
    required this.transaction,
    required this.index,
    required this.isGuestMode,
    required this.spacing,
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = transaction.category.value;
    final account = transaction.account.value;
    final displayAmount = GuestModeUtil.applyGuestMode(
      transaction.amount,
      isGuestMode,
    );
    final isExpense = transaction.isExpense;

    return Semantics(
      label: '${category?.name ?? 'Uncategorized'}, ${account?.name ?? 'Unknown account'}, '
          '$displayAmount ${isExpense ? 'expense' : 'income'}',
      button: true,
      child: RepaintBoundary(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              AppRoutes.addTransaction,
              extra: {'transaction': transaction},
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap + 4,
            ),
            child: Row(
              children: [
                _buildCategoryIcon(category),
                SizedBox(width: spacing.radiusMedium),
                _buildCategoryInfo(category, account),
                const Spacer(),
                _buildAmountAndDate(),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50), duration: 300.ms).slideX(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildCategoryIcon(Category? category) {
    final iconColor = Color(category?.colorValue ?? 0xFF6200EE);
    return Container(
      width: spacing.iconXL + spacing.iconSM,
      height: spacing.iconXL + spacing.iconSM,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Icon(
        IconHelper.getIconData(category?.iconName),
        color: iconColor,
        size: spacing.iconMD,
      ),
    );
  }

  Widget _buildCategoryInfo(Category? category, Account? account) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptiveText(
            category?.name ?? 'Uncategorized',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
          ),
          SizedBox(height: spacing.elementGapUltraMin),
          AdaptiveText(
            account?.name ?? 'Unknown',
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountAndDate() {
    final isExpense = transaction.isExpense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CurrencyText(
          amount: GuestModeUtil.applyGuestMode(transaction.amount, isGuestMode),
          currencyCode: transaction.currencyCode,
          showSign: true,
          isExpense: isExpense,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isExpense ? color.error : color.primary,
          ),
          maxLines: 1,
        ),
        if (transaction.currencyCode != null && transaction.convertedAmount != null)
          CurrencyText(
            amount: transaction.convertedAmount!,
            compact: true,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            prefixText: '≈',
          ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          _formatDate(transaction.date),
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        Text(
          _formatTime(),
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, {bool withTime = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    final timeFormatValue = DateFormat('hh:mm a', ctxt.localeName).format(date);

    if (transactionDate == today) {
      return "${ctxt.label_today}${withTime ? ' - $timeFormatValue' : ''}";
    } else if (transactionDate == yesterday) {
      return "${ctxt.label_yesterday}${withTime ? ' - $timeFormatValue' : ''}";
    } else if (now.difference(date).inDays < 7) {
      return "${DateFormat('EEEE', ctxt.localeName).format(date)}${withTime ? ' - $timeFormatValue' : ''}";
    } else {
      return "${DateFormat('MMM dd', ctxt.localeName).format(date)}${withTime ? ' - $timeFormatValue' : ''}";
    }
  }

  String _formatTime() {
    return DateFormat('hh:mm a', ctxt.localeName).format(transaction.date);
  }
}
