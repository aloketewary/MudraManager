import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/transaction.dart' as db;
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_surface.dart';

class RecentTransactionsCard extends ConsumerWidget {
  final int maxTransactions;

  const RecentTransactionsCard({
    super.key,
    this.maxTransactions = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return dashboardAsync.when(
      loading: () => const RecentTransactionsCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        // Dashboard data is already sorted by date. Keep transfers out of this
        // compact activity summary, matching the existing transaction screen.
        final recentTransactions = List<db.Transaction>.from(
          data.transactions.where((t) => !t.isTransfer).take(maxTransactions),
        );

        if (recentTransactions.isEmpty) return const SizedBox.shrink();

        return _RecentTransactionsCardContent(
          recentTransactions: recentTransactions,
          isGuestMode: isGuestMode,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          ctxt: ctxt,
        );
      },
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
    return FinanceSurface(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontalMin,
        vertical: spacing.cardVerticalMin,
      ),
      padding: EdgeInsets.all(spacing.cardHorizontal),
      borderRadius: spacing.borderRadiusLarge,
      border: BorderSide(color: color.primary.withValues(alpha: 0.0)),
      accent: color.primary,
      semanticLabel: ctxt.statistics_recentTransactionsTitleText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReferenceHeader(context),
          SizedBox(height: spacing.sectionGap),
          ..._buildTransactionGroups(),
        ],
      ),
    );
  }

  Widget _buildReferenceHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            ctxt.statistics_recentTransactionsTitleText,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          label: 'Pinned transactions',
          child: Icon(
            LucideIcons.pin,
            size: spacing.iconSM,
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        IconButton(
          tooltip: ctxt.dashboard_viewAllLabel,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.transactions);
          },
          icon: Icon(
            LucideIcons.history,
            size: spacing.iconSM,
            color: color.onSurfaceVariant,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(
            minWidth: spacing.touchTargetSmall,
            minHeight: spacing.touchTargetSmall,
          ),
        ),
        SizedBox(width: spacing.elementGapMin),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.elementGap,
            vertical: spacing.elementGapMin,
          ),
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            'For the Period',
            style: textTheme.labelSmall?.copyWith(
              color: color.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransactionGroups() {
    final groups = <DateTime, List<db.Transaction>>{};
    for (final transaction in recentTransactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      groups.putIfAbsent(day, () => <db.Transaction>[]).add(transaction);
    }

    final widgets = <Widget>[];
    var groupIndex = 0;
    for (final entry in groups.entries) {
      if (groupIndex > 0) {
        widgets.add(SizedBox(height: spacing.sectionGap));
      }
      widgets.add(_buildDateHeader(entry.key, entry.value));
      widgets.add(SizedBox(height: spacing.elementGap));

      for (var index = 0; index < entry.value.length; index++) {
        if (index > 0) {
          widgets.add(SizedBox(height: spacing.elementGapMin));
        }
        widgets.add(_buildTransactionTile(entry.value[index]));
      }
      groupIndex++;
    }
    return widgets;
  }

  Widget _buildDateHeader(DateTime date, List<db.Transaction> transactions) {
    final total = GuestModeUtil.applyGuestMode(
      transactions.fold<double>(0, (sum, transaction) {
        return sum + transaction.baseAmount;
      }),
      isGuestMode,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('EEEE, d MMMM, y', ctxt.localeName).format(date),
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'Total',
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(width: spacing.elementGapMin),
        CurrencyText(
          amount: total,
          fixedLength: 0,
          compact: true,
          showSign: false,
          style: textTheme.titleSmall?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(db.Transaction transaction) {
    return ClipRRect(
      borderRadius: spacing.borderRadiusMedium,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.surfaceContainerHigh,
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.30),
          ),
          borderRadius: spacing.borderRadiusMedium,
        ),
        child: _TransactionItem(
          transaction: transaction,
          isGuestMode: isGuestMode,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          ctxt: ctxt,
        ),
      ),
    );
  }
}

class _TransactionItem extends StatefulWidget {
  final db.Transaction transaction;
  final bool isGuestMode;
  final AppSpacing spacing;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _TransactionItem({
    required this.transaction,
    required this.isGuestMode,
    required this.spacing,
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final category = transaction.category.value;
    final account = transaction.account.value;
    final categoryColor = Color(
      category?.colorValue ?? widget.color.primary.toARGB32(),
    );
    final amountColor = transaction.isExpense
        ? FinanceColors.expenseColor(widget.color.brightness)
        : FinanceColors.incomeColor(widget.color.brightness);
    final displayAmount = GuestModeUtil.applyGuestMode(
      transaction.amount,
      widget.isGuestMode,
    );
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : category?.name ?? 'Uncategorized';
    final accountName = account?.name ?? 'Unknown account';
    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final semanticLabel = [
      title,
      accountName,
      transaction.isExpense
          ? widget.ctxt.transaction_type_expense
          : widget.ctxt.transaction_type_income,
    ].join(', ');

    final row = Semantics(
      label: semanticLabel,
      button: true,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(
                AppRoutes.addTransaction,
                extra: {'transaction': transaction},
              );
            },
            onTapDown: isReducedMotion ? null : (_) => _controller.forward(),
            onTapUp: isReducedMotion ? null : (_) => _controller.reverse(),
            onTapCancel: isReducedMotion ? null : _controller.reverse,
            child: Padding(
              padding: EdgeInsets.all(widget.spacing.cardInner * 0.75),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCategoryIcon(categoryColor),
                  SizedBox(width: widget.spacing.elementGap),
                  Expanded(
                    child: _buildTransactionInfo(
                      title: title,
                      accountName: accountName,
                      categoryColor: categoryColor,
                    ),
                  ),
                  SizedBox(width: widget.spacing.elementGap),
                  _buildAmount(
                    displayAmount: displayAmount,
                    amountColor: amountColor,
                    convertedAmount: transaction.convertedAmount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isReducedMotion) return row;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        alignment: Alignment.center,
        child: child,
      ),
      child: row,
    );
  }

  Widget _buildCategoryIcon(Color categoryColor) {
    return Container(
      width: widget.spacing.touchTargetSmall + widget.spacing.elementGap,
      height: widget.spacing.touchTargetSmall + widget.spacing.elementGap,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.12),
        borderRadius: widget.spacing.borderRadiusMedium,
      ),
      alignment: Alignment.center,
      child: Icon(
        IconHelper.getIconData(widget.transaction.category.value?.iconName),
        color: categoryColor,
        size: widget.spacing.iconMD,
      ),
    );
  }

  Widget _buildTransactionInfo({
    required String title,
    required String accountName,
    required Color categoryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: widget.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: widget.spacing.elementGapMin),
        Row(
          children: [
            Icon(
              widget.transaction.isExpense
                  ? LucideIcons.arrowUpRight
                  : LucideIcons.arrowDownLeft,
              size: widget.spacing.iconXS,
              color: categoryColor,
            ),
            SizedBox(width: widget.spacing.elementGapUltraMin),
            Icon(
              LucideIcons.creditCard,
              size: widget.spacing.iconXS,
              color: widget.color.onSurfaceVariant,
            ),
            SizedBox(width: widget.spacing.elementGapUltraMin),
            Expanded(
              child: Text(
                accountName,
                style: widget.textTheme.bodySmall?.copyWith(
                  color: widget.color.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmount({
    required double displayAmount,
    required Color amountColor,
    required double? convertedAmount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyText(
          amount: displayAmount,
          currencyCode: widget.transaction.currencyCode,
          showSign: true,
          isExpense: widget.transaction.isExpense,
          style: widget.textTheme.titleSmall?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        ),
        if (widget.transaction.currencyCode != null && convertedAmount != null)
          Padding(
            padding: EdgeInsets.only(top: widget.spacing.elementGapUltraMin),
            child: CurrencyText(
              amount: GuestModeUtil.applyGuestMode(
                convertedAmount,
                widget.isGuestMode,
              ),
              compact: true,
              style: widget.textTheme.bodySmall?.copyWith(
                color: widget.color.onSurfaceVariant,
              ),
              prefixText: '≈',
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}
