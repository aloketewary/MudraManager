import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/debt.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/debt_snowball/data/debt_provider.dart';
import 'package:mudra_manager/features/debt_snowball/domain/debt_models.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

class DebtSnowballScreen extends ConsumerWidget {
  const DebtSnowballScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final debtsAsync = ref.watch(debtsProvider);
    final color = Theme.of(context).colorScheme;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.debt_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_debt',
            label: ctxt.debt_addDebt,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addDebt);
            },
          ),
          ScreenAction(
            id: 'info_debt',
            label: 'Info',
            icon: LucideIcons.info,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showInfoSheet(context, color, spacing, ctxt);
            },
          ),
        ],
      ),
      body: debtsAsync.when(
        data: (allDebts) {
          if (allDebts.isEmpty) {
            return NoDataFound(
              message: ctxt.debt_noDebts,
              description: ctxt.debt_noDebtsDesc,
              iconData: LucideIcons.scale,
              action: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addDebt),
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.debt_addDebt),
              ),
            );
          }

          final activeDebts = allDebts.where((d) => d.isActive).toList();
          final archivedDebts = allDebts.where((d) => !d.isActive).toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(debtsProvider);
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                _StrategySelector(spacing: spacing, ctxt: ctxt),
                SizedBox(height: spacing.elementGap * 2),
                _DebtSummaryCard(spacing: spacing, ctxt: ctxt),
                SizedBox(height: spacing.elementGap * 2),

                if (activeDebts.isNotEmpty) ...[
                  TypeSectionHeader(
                    label: ctxt.debt_activeCount(activeDebts.length),
                    icon: LucideIcons.scale,
                    accentColor: color.primary,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _DebtGroup(
                    debts: activeDebts,
                    isArchived: false,
                    spacing: spacing,
                    ctxt: ctxt,
                  ),
                  SizedBox(height: spacing.elementGap * 2),
                ],

                if (archivedDebts.isNotEmpty) ...[
                  TypeSectionHeader(
                    label: ctxt.debt_archived,
                    icon: LucideIcons.archive,
                    accentColor: color.onSurfaceVariant,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _DebtGroup(
                    debts: archivedDebts,
                    isArchived: true,
                    spacing: spacing,
                    ctxt: ctxt,
                  ),
                  SizedBox(height: spacing.elementGap * 2),
                ],

                SizedBox(
                  height: MediaQuery.of(context).padding.bottom +
                      kBottomNavigationBarHeight +
                      16,
                ),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: EdgeInsets.fromLTRB(
            spacing.cardHorizontal,
            spacing.cardVertical,
            spacing.cardHorizontal,
            100,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const TransactionCardSkeleton(),
        ),
        error: (err, stack) =>
            Center(child: Text(BuddyMessages.errorWith('$err'))),
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context,
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(spacing.sectionGap),
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
                SizedBox(height: spacing.sectionGap),
                Icon(LucideIcons.scale, size: 64, color: color.primary),
                SizedBox(height: spacing.sectionGap),
                Text(
                  ctxt.debt_infoTitle,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing.sectionGap),
                Text(
                  ctxt.debt_infoDesc,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.sectionGap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── STRATEGY SELECTOR ──

class _StrategySelector extends ConsumerWidget {
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _StrategySelector({required this.spacing, required this.ctxt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(debtSortOrderProvider);

    return Row(
      children: [
        Expanded(
          child: FilterChip(
            selected: sortOrder == DebtSortOrder.balanceAscending,
            label: Text(ctxt.debt_snowball),
            avatar: const Icon(LucideIcons.snowflake, size: 16),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              ref.read(debtSortOrderProvider.notifier).set(
                    DebtSortOrder.balanceAscending,
                  );
            },
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: FilterChip(
            selected: sortOrder == DebtSortOrder.balanceDescending,
            label: Text(ctxt.debt_avalanche),
            avatar: const Icon(LucideIcons.mountain, size: 16),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              ref.read(debtSortOrderProvider.notifier).set(
                    DebtSortOrder.balanceDescending,
                  );
            },
          ),
        ),
      ],
    );
  }
}

// ── HERO SUMMARY CARD (one glow per screen) ──

class _DebtSummaryCard extends ConsumerWidget {
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _DebtSummaryCard({required this.spacing, required this.ctxt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = color.brightness == Brightness.dark;
    final result = ref.watch(debtSnowballResultProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: isDark ? 0.20 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, size: 14, color: color.primary),
              SizedBox(width: spacing.elementGapMin),
              Text(
                ctxt.debt_totalDebt,
                style: textTheme.labelLarge?.copyWith(color: color.primary),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          CurrencyText(
            amount: result.totalDebt,
            fixedLength: 0,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color.onSurface,
            ),
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          Row(
            children: [
              Expanded(
                child: _statPill(
                  icon: LucideIcons.calendarClock,
                  label: ctxt.debt_monthsToFreedom,
                  value: '${result.monthsToDebtFree}',
                  color: color,
                  textTheme: textTheme,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _statPillCurrency(
                  icon: LucideIcons.trendingDown,
                  label: ctxt.debt_interestPaid,
                  amount: result.totalInterest,
                  color: color,
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.primary),
          SizedBox(width: spacing.elementGapMin),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: color.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: textTheme.labelLarge?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPillCurrency({
    required IconData icon,
    required String label,
    required double amount,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.primary),
          SizedBox(width: spacing.elementGapMin),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: color.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CurrencyText(
                  amount: amount,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.labelLarge?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── GLASS DEBT GROUP ──

class _DebtGroup extends ConsumerWidget {
  final List<Debt> debts;
  final bool isArchived;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _DebtGroup({
    required this.debts,
    required this.isArchived,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final result = ref.watch(debtSnowballResultProvider);

    return Container(
      decoration: BoxDecoration(
        color: isArchived
            ? color.surface.withValues(alpha: 0.50)
            : color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(
          color: isArchived
              ? color.onSurfaceVariant.withValues(alpha: 0.2)
              : color.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: isArchived ? 0.01 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: debts.asMap().entries.map((entry) {
              final debt = entry.value;
              final isLast = entry.key == debts.length - 1;
              final scheduleIdx = result.paymentSchedule
                  .indexWhere((s) => s.debtId == debt.id);
              final order = scheduleIdx >= 0 ? scheduleIdx + 1 : null;

              return _AnimatedDebtTile(
                debt: debt,
                isArchived: isArchived,
                payoffOrder: order,
                isLast: isLast,
                spacing: spacing,
                ctxt: ctxt,
                onTap: isArchived
                    ? () => _showArchivedOptions(context, ref, debt)
                    : () => _showActiveOptions(context, ref, debt),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showActiveOptions(BuildContext context, WidgetRef ref, Debt debt) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => _OptionsSheet(
        debt: debt,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
        options: [
          _SheetOptionData(
            icon: LucideIcons.pen,
            title: ctxt.common_edit,
            iconColor: color.primary,
            onTap: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.addDebt, extra: {'debt': debt});
            },
          ),
          _SheetOptionData(
            icon: LucideIcons.archive,
            title: ctxt.debt_archive,
            subtitle: ctxt.debt_archiveDesc,
            iconColor: color.onSurfaceVariant,
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(debtServiceProvider).setActive(debt.id, false);
              ref.invalidate(debtsProvider);
              if (context.mounted) {
                SnackbarService.success('${debt.name} archived', spacing);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showArchivedOptions(BuildContext context, WidgetRef ref, Debt debt) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => _OptionsSheet(
        debt: debt,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
        options: [
          _SheetOptionData(
            icon: LucideIcons.archiveRestore,
            title: ctxt.debt_unarchive,
            subtitle: ctxt.debt_unarchiveDesc,
            iconColor: color.primary,
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(debtServiceProvider).setActive(debt.id, true);
              ref.invalidate(debtsProvider);
              if (context.mounted) {
                SnackbarService.success('${debt.name} restored', spacing);
              }
            },
          ),
          _SheetOptionData(
            icon: LucideIcons.trash2,
            title: ctxt.common_delete,
            subtitle: ctxt.debt_deleteDesc,
            iconColor: color.error,
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await DialogUtils.showDeleteConfirmation(
                context,
                spacing,
                title: BuddyMessages.deleteTitle,
                message: BuddyMessages.deleteMessage(debt.name),
              );
              if (confirmed == true) {
                await ref.read(debtServiceProvider).deleteDebt(debt.id);
                ref.invalidate(debtsProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── ANIMATED DEBT TILE ──

class _AnimatedDebtTile extends StatefulWidget {
  final Debt debt;
  final bool isArchived;
  final int? payoffOrder;
  final bool isLast;
  final AppSpacing spacing;
  final AppLocalizations ctxt;
  final VoidCallback onTap;

  const _AnimatedDebtTile({
    required this.debt,
    required this.isArchived,
    required this.payoffOrder,
    required this.isLast,
    required this.spacing,
    required this.ctxt,
    required this.onTap,
  });

  @override
  State<_AnimatedDebtTile> createState() => _AnimatedDebtTileState();
}

class _AnimatedDebtTileState extends State<_AnimatedDebtTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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

  void _handleTapDown(TapDownDetails details) => _controller.forward();

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = widget.spacing;
    final debt = widget.debt;
    final isArchived = widget.isArchived;
    final debtColor =
        debt.colorValue != null ? Color(debt.colorValue!) : color.primary;
    final isPaid = debt.isPaid;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Column(
        children: [
          if (isArchived)
            Container(
              width: double.infinity,
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: spacing.cardInner),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.onSurfaceVariant.withValues(alpha: 0.0),
                    color.onSurfaceVariant.withValues(alpha: 0.15),
                    color.onSurfaceVariant.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          Opacity(
            opacity: isArchived ? 0.60 : 1.0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                highlightColor: debtColor.withValues(alpha: 0.05),
                splashColor: debtColor.withValues(alpha: 0.08),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardInner,
                    vertical: spacing.elementGap * 1.5,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'debt_${debt.id}',
                        child: Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: isArchived
                                ? color.onSurfaceVariant.withValues(alpha: 0.06)
                                : debtColor.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                            border: isArchived
                                ? Border.all(
                                    color: color.onSurfaceVariant
                                        .withValues(alpha: 0.2),
                                  )
                                : null,
                          ),
                          child: Icon(
                            LucideIcons.scale,
                            color: isArchived ? color.onSurfaceVariant : debtColor,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap * 1.5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    debt.name,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isArchived
                                          ? color.onSurfaceVariant
                                          : color.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPaid) ...[
                                  SizedBox(width: spacing.elementGapMin),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.elementGapMin,
                                      vertical: spacing.elementGapUltraMin,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.primary.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(spacing.radiusSmall),
                                    ),
                                    child: Text(
                                      widget.ctxt.debt_paidOff,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (!isArchived &&
                                    widget.payoffOrder != null) ...[
                                  SizedBox(width: spacing.elementGapMin),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.elementGapMin,
                                      vertical: spacing.elementGapUltraMin,
                                    ),
                                    decoration: BoxDecoration(
                                      color: debtColor.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(spacing.radiusSmall),
                                    ),
                                    child: Text(
                                      '#${widget.payoffOrder}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: debtColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${debt.interestRate.toStringAsFixed(1)}% APR',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CurrencyText(
                        amount: debt.balance,
                        fixedLength: 0,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isArchived
                              ? color.onSurfaceVariant
                              : (isPaid ? color.primary : debtColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!widget.isLast) SizedBox(height: spacing.elementGapMin),
        ],
      ),
    );
  }
}

// ── SHARED OPTIONS SHEET ──

class _SheetOptionData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  _SheetOptionData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.onTap,
  });
}

class _OptionsSheet extends StatelessWidget {
  final Debt debt;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final List<_SheetOptionData> options;

  const _OptionsSheet({
    required this.debt,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final debtColor =
        debt.colorValue != null ? Color(debt.colorValue!) : color.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusMedium + 4),
        ),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusMedium + 4),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: spacing.elementGap),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.radiusMedium),
                          decoration: BoxDecoration(
                            color: debtColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(LucideIcons.scale, color: debtColor, size: 24),
                        ),
                        SizedBox(width: spacing.elementGap + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.name,
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              CurrencyText(
                                amount: debt.balance,
                                fixedLength: 0,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: debtColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Divider(
                    height: 1,
                    indent: spacing.cardInner,
                    endIndent: spacing.cardInner,
                    color: color.outlineVariant.withValues(alpha: 0.3),
                  ),
                  ...options.map((opt) => _sheetOption(opt)),
                  SizedBox(height: spacing.elementGap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(_SheetOptionData opt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          opt.onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardInner,
            vertical: spacing.elementGap,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: opt.iconColor == color.error
                      ? color.error.withValues(alpha: 0.1)
                      : opt.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(opt.icon, color: opt.iconColor, size: 20),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.title,
                      style: TextStyle(
                        color: opt.iconColor == color.error ? opt.iconColor : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (opt.subtitle != null)
                      Text(
                        opt.subtitle!,
                        style: TextStyle(
                          color: color.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: color.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
