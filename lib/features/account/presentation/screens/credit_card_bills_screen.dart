import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/account/data/credit_card_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class CreditCardBillsScreen extends ConsumerWidget {
  const CreditCardBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final billsAsync = ref.watch(creditCardBillsProvider);
    final isGuest = ref.watch(guestModeProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.cc_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: billsAsync.when(
        data: (data) {
          if (data.cards.isEmpty) {
            return _buildEmpty(color, textTheme, spacing, ctxt);
          }

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              _buildTotalHero(
                data.summary,
                isGuest,
                color,
                textTheme,
                spacing,
                ctxt,
              ),
              SizedBox(height: spacing.elementGap),
              _buildWarningsStrip(
                data.summary,
                color,
                textTheme,
                spacing,
                ctxt,
              ),
              SizedBox(height: spacing.sectionGap),
              ...data.cards.map(
                (s) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.sectionGap),
                  child: _buildCardTile(
                    s,
                    isGuest,
                    color,
                    textTheme,
                    spacing,
                    ctxt,
                    context,
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap * 2),
            ],
          );
        },
        loading: () => ListView(
          children: List.generate(3, (_) => const DashboardCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(ctxt.common_errorLoading)),
      ),
    );
  }

  Widget _buildEmpty(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.creditCard,
            size: 64,
            color: color.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          SizedBox(height: spacing.sectionGap),
          Text(
            ctxt.cc_noCards,
            style: textTheme.titleMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            ctxt.cc_noCardsHint,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalHero(
    CreditCardBillsSummary summary,
    bool isGuest,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isZero = summary.totalOutstanding == 0;
    final heroColor = isZero ? color.primary : color.error;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            heroColor.withValues(alpha: 0.12),
            color.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, size: 18, color: heroColor),
              SizedBox(width: spacing.elementGap),
              Text(
                ctxt.cc_totalOutstanding,
                style: textTheme.labelLarge?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(
              summary.totalOutstanding,
              isGuest,
            ),
            compact: false,
            fixedLength: 0,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: heroColor,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          // Aggregate minimum due
          Row(
            children: [
              Text(
                ctxt.cc_totalMinimumDue,
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(width: spacing.elementGapMin),
              CurrencyText(
                amount: GuestModeUtil.applyGuestMode(
                  summary.totalMinimumDue,
                  isGuest,
                ),
                compact: true,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.cc_acrossCards(summary.cardCount),
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsStrip(
    CreditCardBillsSummary summary,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final warnings = <_WarningItem>[];

    if (summary.overdueCount > 0) {
      warnings.add(
        _WarningItem(
          text: ctxt.cc_overdueCount(summary.overdueCount),
          color: color.error,
        ),
      );
    }
    if (summary.dueSoonCount > 0) {
      warnings.add(
        _WarningItem(
          text: ctxt.cc_dueSoonCount(summary.dueSoonCount),
          color: color.tertiary,
        ),
      );
    }
    if (summary.highUtilizationCount > 0) {
      warnings.add(
        _WarningItem(
          text: ctxt.cc_highUtilCount(summary.highUtilizationCount),
          color: color.tertiary,
        ),
      );
    }

    if (warnings.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardInner,
          vertical: spacing.elementGap,
        ),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.checkCircle2, size: 16, color: color.primary),
            SizedBox(width: spacing.elementGap),
            Text(
              ctxt.cc_allPaymentsCurrent,
              style: textTheme.labelMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, size: 16, color: color.error),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              warnings.map((w) => w.text).join(' · '),
              style: textTheme.labelMedium?.copyWith(
                color: color.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(
    CreditCardSummary summary,
    bool isGuest,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    BuildContext context,
  ) {
    final card = summary.account;
    final cardColor = Color(card.colorValue ?? Colors.blue.toARGB32());
    final hasLimit = card.creditLimit != null && card.creditLimit! > 0;
    final utilPct = summary.utilization ?? 0;
    final dueStatus = _dueStatus(summary.daysUntilDue, ctxt);
    final dueColor = _dueColor(summary.daysUntilDue, color);
    final safeDateLocale = ctxt.localeName == 'bn' ? 'en' : ctxt.localeName;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    LucideIcons.creditCard,
                    size: 20,
                    color: cardColor,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (card.accountNumber != null)
                        Text(
                          '•••• ${card.accountNumber}',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                if (dueStatus != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.elementGap,
                      vertical: spacing.elementGapMin,
                    ),
                    decoration: BoxDecoration(
                      color: dueColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Text(
                      dueStatus,
                      style: textTheme.labelSmall?.copyWith(
                        color: dueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(
              height: 1, color: color.outlineVariant.withValues(alpha: 0.3)),

          // Metrics: Outstanding + Est. Minimum Due + Available Credit
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metricColumn(
                        ctxt.account_outstanding,
                        GuestModeUtil.applyGuestMode(
                            summary.outstanding, isGuest),
                        summary.outstanding > 0 ? color.error : color.primary,
                        textTheme,
                        spacing,
                        currencyCode: card.currencyCode,
                      ),
                    ),
                    Expanded(
                      child: _metricColumn(
                        ctxt.cc_minimumDue,
                        GuestModeUtil.applyGuestMode(
                            summary.minimumDue, isGuest),
                        color.tertiary,
                        textTheme,
                        spacing,
                        currencyCode: card.currencyCode,
                      ),
                    ),
                    if (hasLimit)
                      Expanded(
                        child: _metricColumn(
                          ctxt.cc_availableCredit,
                          GuestModeUtil.applyGuestMode(
                            summary.availableCredit,
                            isGuest,
                          ),
                          color.primary,
                          textTheme,
                          spacing,
                          currencyCode: card.currencyCode,
                        ),
                      ),
                  ],
                ),
                // Provenance line for minimum due
                if (summary.minimumDue > 0)
                  Padding(
                    padding: EdgeInsets.only(top: spacing.elementGapMin),
                    child: Text(
                      ctxt.cc_minimumDueProvenance,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                // Secondary: billing cycle spend
                if (summary.billingCycleSpend > 0)
                  Padding(
                    padding: EdgeInsets.only(top: spacing.elementGapMin),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.arrowUpRight,
                          size: 12,
                          color: color.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          ctxt.cc_cycleSpend,
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        CurrencyText(
                          amount: GuestModeUtil.applyGuestMode(
                            summary.billingCycleSpend,
                            isGuest,
                          ),
                          currencyCode: card.currencyCode,
                          compact: true,
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Utilization bar
          if (hasLimit) ...[
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: _buildUtilization(
                utilPct,
                card.creditLimit!,
                summary.outstanding,
                isGuest,
                cardColor,
                color,
                textTheme,
                spacing,
                ctxt,
              ),
            ),
          ],

          // Dates row
          if (card.statementDay != null || card.dueDay != null) ...[
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardInner,
                vertical: spacing.elementGap,
              ),
              child: Row(
                children: [
                  if (summary.nextStatementDate != null)
                    Expanded(
                      child: _dateChip(
                        LucideIcons.calendarRange,
                        ctxt.cc_nextStatement,
                        DateFormat('d MMM', safeDateLocale)
                            .format(summary.nextStatementDate!),
                        cardColor,
                        textTheme,
                        spacing,
                      ),
                    ),
                  if (summary.nextDueDate != null)
                    Expanded(
                      child: _dateChip(
                        LucideIcons.calendarClock,
                        ctxt.cc_nextDue,
                        DateFormat('d MMM', safeDateLocale)
                            .format(summary.nextDueDate!),
                        dueColor,
                        textTheme,
                        spacing,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Pay action — Pay Full promoted, Pay Minimum demoted
          if (summary.outstanding > 0) ...[
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary: Pay Full (filled button)
                  FilledButton(
                    onPressed: () => _navigateToPayment(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: color.primary,
                      foregroundColor: color.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: spacing.elementGap),
                    ),
                    child: Text(
                      ctxt.cc_payFull,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  // Secondary: Pay Minimum (text link, demoted)
                  Center(
                    child: TextButton(
                      onPressed: () => _navigateToPayment(context),
                      style: TextButton.styleFrom(
                        foregroundColor: color.onSurfaceVariant,
                        padding: EdgeInsets.symmetric(
                          vertical: spacing.elementGapMin,
                        ),
                      ),
                      child: CurrencyText(
                        amount: GuestModeUtil.applyGuestMode(
                          summary.minimumDue,
                          isGuest,
                        ),
                        compact: true,
                        prefixText: '${ctxt.cc_payMinimum}: ',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricColumn(
    String label,
    double amount,
    Color accentColor,
    TextTheme textTheme,
    AppSpacing spacing, {
    String? currencyCode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: accentColor.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: spacing.elementGapUltraMin),
        CurrencyText(
          amount: amount,
          currencyCode: currencyCode,
          compact: true,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUtilization(
    double utilPct,
    double limit,
    double outstanding,
    bool isGuest,
    Color cardColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final barColor = utilPct > 75
        ? color.error
        : utilPct > 50
            ? color.tertiary
            : cardColor;
    final clampedPct = utilPct.clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ctxt.cc_utilization,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            Text(
              '${utilPct.toStringAsFixed(0)}%',
              style: textTheme.labelSmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGapMin),
        ClipRRect(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: LinearProgressIndicator(
            value: clampedPct,
            minHeight: spacing.progressNormal,
            backgroundColor: color.outlineVariant.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(barColor),
            semanticsLabel: ctxt.cc_utilization,
            semanticsValue: '${utilPct.toStringAsFixed(0)}%',
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CurrencyText(
              amount: GuestModeUtil.applyGuestMode(outstanding, isGuest),
              compact: true,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            CurrencyText(
              amount: GuestModeUtil.applyGuestMode(limit, isGuest),
              compact: true,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateChip(
    IconData icon,
    String label,
    String value,
    Color accentColor,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: accentColor),
        SizedBox(width: spacing.elementGapMin),
        Text(
          '$label ',
          style: textTheme.labelSmall?.copyWith(
            color: accentColor.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _navigateToPayment(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push(
      AppRoutes.addTransaction,
      extra: {
        'isIncome': false,
      },
    );
  }

  String? _dueStatus(int? daysUntilDue, AppLocalizations ctxt) {
    if (daysUntilDue == null) return null;
    if (daysUntilDue < 0) return ctxt.account_overdue(daysUntilDue.abs());
    if (daysUntilDue == 0) return ctxt.account_dueToday;
    return ctxt.account_daysUntilDue(daysUntilDue);
  }

  Color _dueColor(int? daysUntilDue, ColorScheme color) {
    if (daysUntilDue == null) return color.onSurfaceVariant;
    if (daysUntilDue <= 0) return color.error;
    if (daysUntilDue <= 3) return color.tertiary;
    return color.primary;
  }
}

class _WarningItem {
  final String text;
  final Color color;

  const _WarningItem({required this.text, required this.color});
}
