import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/account/data/balance_history_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/account/presentation/widgets/balance_history_chart.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class BalanceHistoryScreen extends ConsumerWidget {
  final Account account;

  const BalanceHistoryScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceHistory = ref.watch(balanceHistoryProvider(account.id));
    final isGuestMode = ref.watch(guestModeProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    return ScreenShell(
      config: ScreenShellConfig(
        title: account.name,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: balanceHistory.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noData,
              iconData: LucideIcons.history,
            );
          }

          final currentBalance = snapshots.last.balance;
          final firstBalance = snapshots.first.balance;
          final change = currentBalance - firstBalance;
          final changePercent =
              firstBalance != 0 ? (change / firstBalance.abs() * 100) : 0.0;

          // Emotional context
          final emotionLine = change > 0
              ? ctxt.balanceHistory_growing
              : change < 0
                  ? ctxt.balanceHistory_declining
                  : ctxt.balanceHistory_steady;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // Hero
              _buildHeroCard(
                currentBalance,
                change,
                changePercent,
                emotionLine,
                accountColor,
                isGuestMode,
                color,
                textTheme,
                spacing,
                ctxt,
              ),
              SizedBox(height: spacing.sectionGap),

              // Chart — the star
              BalanceHistoryChart(
                snapshots: snapshots,
                accountColor: accountColor,
                isGuestMode: isGuestMode,
              ),
              SizedBox(height: spacing.sectionGap),

              // Stats
              _buildStatsRow(
                snapshots,
                isGuestMode,
                color,
                textTheme,
                spacing,
                ctxt,
              ),
              SizedBox(height: spacing.sectionGap * 2),
            ],
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.all(spacing.cardHorizontal),
          child: const DashboardCardSkeleton(),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, size: 64, color: color.error),
              SizedBox(height: spacing.sectionGap),
              Text(
                ctxt.common_errorLoading,
                style: textTheme.titleMedium?.copyWith(color: color.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    double currentBalance,
    double change,
    double changePercent,
    String emotionLine,
    Color accountColor,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isPositive = change >= 0;
    final changeColor = isPositive ? color.primary : color.error;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accountColor.withValues(alpha: 0.12),
            color.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emotional headline
          Text(
            emotionLine,
            style: textTheme.bodySmall?.copyWith(
              color: changeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: accountColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  account.accountType.icon,
                  color: accountColor,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.balanceHistory_currentBalance,
                style: textTheme.labelLarge
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(currentBalance, isGuestMode),
            currencyCode: account.currencyCode,
            compact: false,
            style:
                textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap,
              vertical: spacing.elementGapMin,
            ),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
                  size: 14,
                  color: changeColor,
                ),
                SizedBox(width: spacing.elementGapMin),
                CurrencyText(
                  amount:
                      GuestModeUtil.applyGuestMode(change.abs(), isGuestMode),
                  currencyCode: account.currencyCode,
                  style: textTheme.labelMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' (${changePercent.abs().toStringAsFixed(1)}%)',
                  style: textTheme.labelMedium?.copyWith(
                    color: changeColor,
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

  Widget _buildStatsRow(
    List snapshots,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final balances = snapshots.map((s) => s.balance as double).toList();
    final highest = balances.reduce((a, b) => a > b ? a : b);
    final lowest = balances.reduce((a, b) => a < b ? a : b);
    final avg = balances.reduce((a, b) => a + b) / balances.length;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            ctxt.balanceHistory_highest,
            GuestModeUtil.applyGuestMode(highest, isGuestMode),
            LucideIcons.arrowUp,
            color.primary,
            color,
            textTheme,
            spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _statPill(
            ctxt.balanceHistory_lowest,
            GuestModeUtil.applyGuestMode(lowest, isGuestMode),
            LucideIcons.arrowDown,
            color.error,
            color,
            textTheme,
            spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _statPill(
            ctxt.balanceHistory_average,
            GuestModeUtil.applyGuestMode(avg, isGuestMode),
            LucideIcons.minus,
            color.secondary,
            color,
            textTheme,
            spacing,
          ),
        ),
      ],
    );
  }

  Widget _statPill(
    String label,
    double value,
    IconData icon,
    Color pillColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: pillColor),
          SizedBox(height: spacing.elementGapMin),
          CurrencyText(
            amount: value,
            currencyCode: account.currencyCode,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing.elementGapUltraMin),
          Text(
            label,
            style:
                textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
