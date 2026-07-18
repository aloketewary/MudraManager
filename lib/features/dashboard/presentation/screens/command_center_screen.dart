import 'package:mudra_manager/core/constants/dashboard_constants.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return ScreenShell(
      config: const ScreenShellConfig(
        appBarMode: AppBarMode.none,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: accountsAsync.when(
        data: (accounts) {
          final totalBalance = accounts.fold<double>(
            0,
            (sum, acc) => sum + (acc.initialBalance),
          );
          final primaryAccount = accounts.isNotEmpty ? accounts.first : null;
          final transactionService = ref.watch(transactionProvider);

          return FutureBuilder<List<Transaction>>(
            future: transactionService.getAll(),
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? [];
              final now = DateTime.now();
              final threeDaysAgo = now.subtract(const Duration(days: 3));
              final pendingAmount = transactions
                  .where((t) => t.date.isAfter(threeDaysAgo) && t.isExpense)
                  .fold<double>(0, (sum, t) => sum + t.baseAmount);
              final availableBalance = totalBalance - pendingAmount;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth =
                      constraints.maxWidth > DashboardConstants.maxWidth
                          ? DashboardConstants.maxWidth
                          : double.infinity;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _CommandCenterBody(
                        totalBalance: totalBalance,
                        pendingAmount: pendingAmount,
                        availableBalance: availableBalance,
                        primaryAccount: primaryAccount,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: AccountCardSkeleton(),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }
}

/// Full-screen "glance zone" body: search/notifications bar, hero balance,
/// and a card-style representation of the primary account.
class _CommandCenterBody extends ConsumerWidget {
  final double totalBalance;
  final double pendingAmount;
  final double availableBalance;
  final Account? primaryAccount;

  const _CommandCenterBody({
    required this.totalBalance,
    required this.pendingAmount,
    required this.availableBalance,
    required this.primaryAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer.withValues(alpha: 0.3),
            color.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _TopActionBar(),
            const Spacer(),
            _GlanceBalance(
              totalBalance: totalBalance,
              pendingAmount: pendingAmount,
              availableBalance: availableBalance,
            ),
            const Spacer(),
            if (primaryAccount != null)
              _AccountRepresentationCard(account: primaryAccount!),
          ],
        ),
      ),
    );
  }
}

class _TopActionBar extends ConsumerWidget {
  const _TopActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Search',
            icon: Icon(LucideIcons.search, color: color.onSurface),
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Navigate to search
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(LucideIcons.bell, color: color.onSurface),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.notifications);
            },
          ),
        ],
      ),
    );
  }
}

/// Hero total balance — wrapped in [AmountGlow] + [AnimatedBalance] per the
/// dashboard-visual-polish steering rules: one glow per card, on the number
/// the user came here to check.
class _GlanceBalance extends ConsumerWidget {
  final double totalBalance;
  final double pendingAmount;
  final double availableBalance;

  const _GlanceBalance({
    required this.totalBalance,
    required this.pendingAmount,
    required this.availableBalance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'Total Balance',
          style: textTheme.bodyLarge?.copyWith(
            color: color.onSurface.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        AmountGlow(
          color: color.primary,
          child: AnimatedBalance(
            value: totalBalance,
            duration: const Duration(milliseconds: 1500),
            compact: false,
            fixedStringLength: 2,
            style: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 56,
              color: color.onSurface,
            ),
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        if (pendingAmount > 0) ...[
          _MoneyHoldPill(pendingAmount: pendingAmount),
          SizedBox(height: spacing.elementGap),
        ],
        Text(
          'Available: ${formatCurrency(availableBalance, code: BaseCurrency.code, decimals: 2)}',
          style: textTheme.bodyLarge?.copyWith(
            color: color.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MoneyHoldPill extends ConsumerWidget {
  final double pendingAmount;

  const _MoneyHoldPill({required this.pendingAmount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Semantics(
      label:
          'Money on hold: ${formatCurrency(pendingAmount, code: BaseCurrency.code, decimals: 2)}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardInner,
          vertical: spacing.elementGap,
        ),
        decoration: BoxDecoration(
          color: color.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(
            color: color.error.withValues(alpha: 0.3),
            width: spacing.strokeThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.lock, size: spacing.iconSM, color: color.error),
            SizedBox(width: spacing.elementGapMin),
            Text(
              'Money hold: ${formatCurrency(pendingAmount, code: BaseCurrency.code, decimals: 2)}',
              style: textTheme.bodyMedium?.copyWith(
                color: color.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card-style visual representation of the primary account (debit/credit
/// card mockup). Secondary/metric numbers here use plain [CurrencyText] —
/// only the screen's single hero balance above gets [AmountGlow].
class _AccountRepresentationCard extends ConsumerWidget {
  final Account account;

  const _AccountRepresentationCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isCreditCard = account.accountType == AccountType.creditCard;
    final lastFour = account.accountNumber != null &&
            account.accountNumber!.length >= 4
        ? account.accountNumber!.substring(account.accountNumber!.length - 4)
        : '****';

    return Padding(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primary.withValues(alpha: 0.9),
              color.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: color.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  account.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  isCreditCard ? LucideIcons.creditCard : LucideIcons.wallet,
                  color: color.onPrimary.withValues(alpha: 0.7),
                  size: spacing.iconLG,
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            Text(
              '•••• •••• •••• $lastFour',
              style: textTheme.headlineSmall?.copyWith(
                color: color.onPrimary,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    CurrencyText(
                      amount: account.initialBalance,
                      compact: false,
                      fixedLength: 2,
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isCreditCard)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Valid Thru',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        '12/24',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
