import 'dart:ui';

import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_access_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/presentation/screens/balance_history_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/reconciliation_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/investment_portfolio_screen.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';

class ManageAccountScreen extends ConsumerStatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  ConsumerState<ManageAccountScreen> createState() =>
      _ManageAccountScreenState();
}

class _ManageAccountScreenState extends ConsumerState<ManageAccountScreen> {
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final allAccountsAsync = ref.watch(allAccountsProvider);
    final balanceMapAsync = ref.watch(accountBalanceMapProvider);
    final baseBalanceMapAsync = ref.watch(accountBaseBalanceMapProvider);
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final balanceMap = balanceMapAsync.value ?? {};
    final baseBalanceMap = baseBalanceMapAsync.value ?? {};

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.accounts_manageAccountsTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_account',
            label: ctxt.accounts_addAccountLabel,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/manage-accounts/add');
            },
          ),
          ScreenAction(
            id: 'info_accounts',
            label: 'Info',
            icon: LucideIcons.info,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showInfoBottomSheet(context, color, textTheme, spacing);
            },
          ),
        ],
      ),
      body: allAccountsAsync.when(
        data: (allAccounts) {
          if (allAccounts.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noAccounts,
              iconData: LucideIcons.wallet,
              action: ElevatedButton.icon(
                onPressed: () => context.push('/manage-accounts/add'),
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.accounts_addAccountLabel),
              ),
            );
          }

          final activeAccounts = allAccounts.where((a) => a.isActive).toList();
          final archivedAccounts =
              allAccounts.where((a) => !a.isActive).toList();

          // Group active accounts by type
          final grouped = <AccountType, List<Account>>{};
          for (final account in activeAccounts) {
            grouped.putIfAbsent(account.accountType, () => []).add(account);
          }

          final totalBalance = activeAccounts.fold<double>(0.0, (sum, acc) {
            final balance = baseBalanceMap[acc.id] ?? 0.0;
            return acc.accountType == AccountType.creditCard
                ? sum - balance
                : sum + balance;
          });

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(allAccountsProvider);
              ref.invalidate(accountsProvider);
              ref.invalidate(accountBalanceMapProvider);
              ref.invalidate(accountBaseBalanceMapProvider);
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                _buildSummaryCard(
                  totalBalance,
                  activeAccounts.length,
                  color,
                  textTheme,
                  spacing,
                ),
                SizedBox(height: spacing.elementGap * 2),

                // Active grouped sections
                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeHeader(
                        entry.key,
                        entry.value.length,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildAccountGroup(
                        entry.value,
                        false,
                        activeAccounts.length,
                        balanceMap,
                        color,
                        textTheme,
                        ctxt,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap * 2),
                    ],
                  );
                }),

                // Archived section
                if (archivedAccounts.isNotEmpty) ...[
                  SizedBox(height: spacing.elementGap),
                  _buildArchivedHeader(color, textTheme, spacing, ctxt),
                  SizedBox(height: spacing.elementGap),
                  _buildAccountGroup(
                    archivedAccounts,
                    true,
                    activeAccounts.length,
                    balanceMap,
                    color,
                    textTheme,
                    ctxt,
                    spacing,
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
          itemCount: 5,
          itemBuilder: (context, index) => const TransactionCardSkeleton(),
        ),
        error: (err, stack) =>
            Center(child: Text(BuddyMessages.errorWith('$err'))),
      ),
    );
  }

  // ── SUMMARY CARD ── (enhanced)
  Widget _buildSummaryCard(
    double totalBalance,
    int accountCount,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final isDark = color.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.wallet, size: 14, color: color.primary),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  '${ctxt.accounts_totalBalance} (${BaseCurrency.code})',
                  style:
                      textTheme.labelLarge?.copyWith(color: color.primary),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            CurrencyText(
              amount: totalBalance,
              compact: false,
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.onSurface,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Container(
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
                  Icon(
                    LucideIcons.creditCard,
                    size: 12,
                    color: color.primary,
                  ),
                  SizedBox(width: spacing.elementGapMin),
                  Text(
                    '$accountCount ${ctxt.accounts_accountsCount}',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TYPE HEADER ── (enhanced with count badge)
  Widget _buildTypeHeader(
    AccountType type,
    int count,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: spacing.cardHorizontal),
      child: Row(
        children: [
          Container(
            width: spacing.elementGapMin,
            height: 20,
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: BorderRadius.circular(spacing.elementGapMin / 2),
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.primary.withValues(alpha: 0.12),
                  color.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(type.icon, size: 16, color: color.primary),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              type.label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap,
              vertical: spacing.elementGapUltraMin,
            ),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              border: Border.all(color: color.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$count',
              style: textTheme.labelSmall?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ARCHIVED HEADER ──
  Widget _buildArchivedHeader(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: spacing.cardHorizontal),
      child: Row(
        children: [
          Container(
            width: spacing.elementGapMin,
            height: 18,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant,
              borderRadius: BorderRadius.circular(spacing.elementGapMin / 2),
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(
              LucideIcons.archive,
              size: 16,
              color: color.onSurfaceVariant,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Text(
            ctxt.accounts_archived,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── GROUPED ACCOUNT CARD ── (enhanced with scale + archived improvements)
  Widget _buildAccountGroup(
    List<Account> accounts,
    bool isArchived,
    int activeCount,
    Map<int, double> balanceMap,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMin),
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
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: accounts.asMap().entries.map((entry) {
              final account = entry.value;
              final isLast = entry.key == accounts.length - 1;
              final accountColor =
                  Color(account.colorValue ?? Colors.blue.toARGB32());
              final balance = balanceMap[account.id] ?? 0.0;

              return Column(
                children: [
                  _AnimatedAccountTile(
                    account: account,
                    balance: balance,
                    isArchived: isArchived,
                    accountColor: accountColor,
                    isLast: isLast,
                    balanceMap: balanceMap,
                    color: color,
                    textTheme: textTheme,
                    ctxt: ctxt,
                    spacing: spacing,
                    activeCount: activeCount,
                    onTap: isArchived
                        ? () => _showArchivedContextOptions(
                              context,
                              account,
                              balance,
                              ctxt,
                            )
                        : () => _showContextOptions(
                              context,
                              account,
                              balance,
                              activeCount,
                              ctxt,
                            ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── ACTIVE ACCOUNT CONTEXT SHEET ──
  void _showContextOptions(
    BuildContext context,
    Account account,
    double balance,
    int activeCount,
    AppLocalizations ctxt,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: color.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusMedium + 4),
          ),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
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
                    // Accent drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),
                    _buildSheetHeader(
                      account,
                      accountColor,
                      spacing,
                      textTheme,
                      balance,
                    ),
                    SizedBox(height: spacing.elementGap),
                    Divider(
                      height: 1,
                      indent: spacing.cardInner,
                      endIndent: spacing.cardInner,
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _sheetOption(ctx, LucideIcons.pen, ctxt.accounts_edit, null,
                        color.primary, () {
                      Navigator.pop(ctx);
                      if (mounted) {
                        context.push(
                          '/manage-accounts/add',
                          extra: {'account': account},
                        );
                      }
                    }),
                    SizedBox(height: spacing.elementGapMin),
                    _sheetOption(ctx, LucideIcons.history,
                        ctxt.accounts_balanceHistory, null, color.primary, () {
                      Navigator.pop(ctx);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BalanceHistoryScreen(account: account),
                          ),
                        );
                      }
                    }),
                    SizedBox(height: spacing.elementGapMin),
                    _sheetOption(ctx, LucideIcons.scale, ctxt.reconcile_title,
                        ctxt.accounts_matchBank, color.primary, () {
                      Navigator.pop(ctx);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReconciliationScreen(account: account),
                          ),
                        );
                      }
                    }),
                    if (account.accountType == AccountType.investment) ...[
                      SizedBox(height: spacing.elementGapMin),
                      _sheetOption(ctx, LucideIcons.chartLine,
                          ctxt.accounts_viewPortfolio, null, color.primary, () {
                        Navigator.pop(ctx);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvestmentPortfolioScreen(account: account),
                            ),
                          );
                        }
                      }),
                    ],
                    if (!account.isPrimary) ...[
                      SizedBox(height: spacing.elementGapMin),
                      _sheetOption(
                          ctx,
                          LucideIcons.star,
                          ctxt.accounts_setAsPrimary,
                          ctxt.accounts_primaryDesc,
                          color.primary, () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(accountServiceProvider)
                            .setPrimaryAccount(account.id);
                        ref.invalidate(accountsProvider);
                        ref.invalidate(primaryAccountProvider);
                        if (mounted) {
                          SnackbarService.success(
                            '${account.name} is now your primary account',
                            spacing,
                          );
                        }
                      }),
                      SizedBox(height: spacing.elementGapMin),
                    ],
                    Divider(
                      height: 1,
                      indent: spacing.cardInner,
                      endIndent: spacing.cardInner,
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    _sheetOption(
                        ctx,
                        LucideIcons.archive,
                        ctxt.accounts_archive,
                        ctxt.accounts_archiveDesc,
                        color.onSurfaceVariant, () {
                      Navigator.pop(ctx);
                      if (activeCount <= 1) {
                        SnackbarService.warning(
                          ctxt.accounts_atLeastOneAccountRequired,
                          spacing,
                        );
                      } else {
                        _showArchiveConfirmation(account, ctxt, spacing);
                      }
                    }),
                    SizedBox(height: spacing.elementGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ARCHIVED ACCOUNT CONTEXT SHEET ──
  void _showArchivedContextOptions(
    BuildContext context,
    Account account,
    double balance,
    AppLocalizations ctxt,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: color.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusMedium + 4),
          ),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
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
                    // Accent drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),
                    _buildSheetHeader(
                      account,
                      accountColor,
                      spacing,
                      textTheme,
                      balance,
                    ),
                    SizedBox(height: spacing.elementGap),
                    Divider(
                      height: 1,
                      indent: spacing.cardInner,
                      endIndent: spacing.cardInner,
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _sheetOption(
                        ctx,
                        LucideIcons.archiveRestore,
                        ctxt.accounts_unarchive,
                        ctxt.accounts_unarchiveDesc,
                        color.primary, () {
                      Navigator.pop(ctx);
                      _unarchiveAccount(account, ctxt, spacing);
                    }),
                    SizedBox(height: spacing.elementGapMin),
                    _sheetOption(ctx, LucideIcons.trash2, ctxt.common_delete,
                        ctxt.accounts_deleteDesc, color.error, () {
                      Navigator.pop(ctx);
                      _showDeleteConfirmation(account, ctxt, spacing);
                    }),
                    SizedBox(height: spacing.elementGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SHARED SHEET HEADER ──
  Widget _buildSheetHeader(
    Account account,
    Color accountColor,
    AppSpacing spacing,
    TextTheme textTheme,
    double balance,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.radiusMedium),
            decoration: BoxDecoration(
              color: accountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child:
                Icon(account.accountType.icon, color: accountColor, size: 24),
          ),
          SizedBox(width: spacing.elementGap + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!account.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ctxt.accounts_archived,
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                CurrencyText(
                  currencyCode: account.currencyCode,
                  amount: balance,
                  style: textTheme.bodyMedium?.copyWith(
                    color: accountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetOption(
    BuildContext ctx,
    IconData icon,
    String title,
    String? subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final color = Theme.of(ctx).colorScheme;
    final spacing = ref.read(spacingProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardInner,
            vertical: spacing.elementGap,
          ),
          child: Row(
            children: [
              // Tonal icon container
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: iconColor == color.error
                      ? color.error.withValues(alpha: 0.1)
                      : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor == color.error ? iconColor : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ACTIONS ──

  Future<void> _unarchiveAccount(
    Account account,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) async {
    final isarService = ref.read(isarServiceProvider);
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      account.isActive = true;
      await isar.accounts.put(account);
    });
    ref.invalidate(allAccountsProvider);
    ref.invalidate(accountsProvider);

    if (context.mounted) {
      SnackbarService.success('${account.name} restored', spacing);
    }
  }

  Future<void> _showDeleteConfirmation(
    Account account,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: BuddyMessages.deleteTitle,
      message: BuddyMessages.deleteMessage(account.name),
    );

    if (confirmed == true) {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();
      await isar.writeTxn(() async {
        await isar.accounts.delete(account.id);
      });
      ref.invalidate(allAccountsProvider);
      ref.invalidate(accountsProvider);
    }
  }

  Future<void> _showArchiveConfirmation(
    Account account,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) async {
    final confirmed = await DialogUtils.showConfirmation(
      context,
      spacing,
      title: BuddyMessages.deleteTitle,
      message: ctxt.accounts_archiveAccountMessage(account.name),
      icon: LucideIcons.archive,
    );

    if (confirmed == true) {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();
      await isar.writeTxn(() async {
        account.isActive = false;
        await isar.accounts.put(account);
      });
      ref.invalidate(allAccountsProvider);
      ref.invalidate(accountsProvider);

      if (context.mounted) {
        SnackbarService.success(
          ctxt.accounts_accountArchivedMessage(account.name),
          spacing,
        );
      }
    }
  }

  void _showInfoBottomSheet(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
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
                Icon(LucideIcons.wallet, size: 64, color: color.primary),
                SizedBox(height: spacing.sectionGap),
                Text(
                  ctxt.accounts_howItWorks,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing.sectionGap),
                Text(
                  ctxt.accounts_howItWorksDesc,
                  style: textTheme.bodyMedium,
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

// ── ANIMATED ACCOUNT TILE ── (scale tap + archived visual improvements)
class _AnimatedAccountTile extends ConsumerStatefulWidget {
  final Account account;
  final double balance;
  final bool isArchived;
  final Color accountColor;
  final bool isLast;
  final Map<int, double> balanceMap;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;
  final AppSpacing spacing;
  final int activeCount;
  final VoidCallback onTap;

  const _AnimatedAccountTile({
    required this.account,
    required this.balance,
    required this.isArchived,
    required this.accountColor,
    required this.isLast,
    required this.balanceMap,
    required this.color,
    required this.textTheme,
    required this.ctxt,
    required this.spacing,
    required this.activeCount,
    required this.onTap,
  });

  @override
  ConsumerState<_AnimatedAccountTile> createState() =>
      __AnimatedAccountTileState();
}

class __AnimatedAccountTileState extends ConsumerState<_AnimatedAccountTile>
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

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.spacing;
    final color = widget.color;
    final textTheme = widget.textTheme;
    final accountColor = widget.accountColor;
    final account = widget.account;
    final isArchived = widget.isArchived;
    final balance = widget.balance;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
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
                highlightColor: accountColor.withValues(alpha: 0.05),
                splashColor: accountColor.withValues(alpha: 0.08),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardInner,
                    vertical: spacing.elementGap * 1.5,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'account_${account.id}',
                        child: Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: isArchived
                                ? color.onSurfaceVariant.withValues(alpha: 0.06)
                                : accountColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(
                              spacing.radiusMedium,
                            ),
                            border: isArchived
                                ? Border.all(
                                    color: color.onSurfaceVariant.withValues(
                                      alpha: 0.2,
                                    ),
                                  )
                                : null,
                          ),
                          child: isArchived
                              ? Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Icon(
                                      account.accountType.icon,
                                      color: color.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: color.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.archive,
                                          size: 8,
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Icon(
                                  account.accountType.icon,
                                  color: accountColor,
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
                                    account.name,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isArchived
                                          ? color.onSurfaceVariant
                                          : color.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (account.isPrimary) ...[
                                  SizedBox(
                                    width: spacing.elementGapMin,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.elementGapMin,
                                      vertical: spacing.elementGapUltraMin,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          color.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        spacing.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      widget.ctxt.accounts_primary,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (account.accountNumber != null ||
                                account.currencyCode != null)
                              Row(
                                children: [
                                  if (account.accountNumber != null)
                                    Text(
                                      '•••• ${account.accountNumber}'.safe(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  if (account.accountNumber != null &&
                                      account.currencyCode != null)
                                    Text(
                                      '  •  ',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.outlineVariant,
                                      ),
                                    ),
                                  if (account.currencyCode != null)
                                    CurrencyBadge(
                                      code: account.currencyCode!,
                                      size: 11,
                                      color: accountColor.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      CurrencyText(
                        currencyCode: account.currencyCode,
                        amount: balance,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isArchived
                              ? color.onSurfaceVariant
                              : (balance >= 0 ? accountColor : color.error),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final unlockedIds =
                              ref.watch(unlockedAccountIdsProvider);
                          final isUnlocked =
                              unlockedIds.value?.contains(account.id) ?? true;
                          if (isUnlocked || isArchived) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              left: spacing.elementGapMin,
                            ),
                            child: Icon(
                              LucideIcons.lock,
                              size: 12,
                              color: color.primary,
                            ),
                          );
                        },
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
