import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/credit_card/data/credit_card_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
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
    final appBarData = billsAsync.value;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.cc_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: true,
        customAppBar: appBarData == null
            ? null
            : _CreditCardBillsAppBar(
                title: ctxt.cc_title,
                summary: appBarData.summary,
                isGuest: isGuest,
                spacing: spacing,
                onBack: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
              ),
      ),
      actions: ScreenActions.empty,
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.invalidate(creditCardBillsProvider);
        await ref.read(creditCardBillsProvider.future);
      }),
      body: billsAsync.when(
        data: (data) {
          if (data.cards.isEmpty) {
            return _buildEmpty(context, color, textTheme, spacing, ctxt);
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontalMax,
              spacing.sectionGap,
              spacing.cardHorizontalMax,
              spacing.sectionGap + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildTotalHero(
                context,
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
              TypeSectionHeader(
                label: ctxt.cc_yourCards,
                icon: LucideIcons.creditCard,
                accentColor: color.primary,
              ),
              SizedBox(height: spacing.elementGap),
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
              SizedBox(height: spacing.sectionGap),
            ],
          );
        },
        loading: () => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: List.generate(
            3,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sectionGap),
              child: const DashboardCardSkeleton(),
            ),
          ),
        ),
        error: (err, _) => Center(child: Text(BuddyMessages.errorWith('$err'))),
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return NoDataFound(
      message: '${ctxt.cc_noCards}\n${ctxt.cc_noCardsHint}',
      iconData: LucideIcons.creditCard,
      action: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.addAccount);
        },
        icon: const Icon(LucideIcons.plus),
        label: Text(ctxt.accounts_addAccountLabel),
      ),
    );
  }

  Widget _buildTotalHero(
    BuildContext context,
    CreditCardBillsSummary summary,
    bool isGuest,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isDark = color.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hasLimit = summary.totalCreditLimit > 0;
    final totalLimit = summary.totalCreditLimit;
    final utilization = hasLimit
        ? (summary.totalOutstanding / totalLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final heroColor =
        summary.totalOutstanding > 0 ? color.error : color.primary;

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            heroColor.withValues(alpha: isDark ? 0.22 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: heroColor.withValues(alpha: isDark ? 0.32 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: heroColor.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardVisual(heroColor, color, spacing),
          SizedBox(height: spacing.elementGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(
                    summary.totalOutstanding,
                    isGuest,
                  ),
                  compact: false,
                  fixedLength: 0,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: heroColor,
                  ),
                ),
              ),
              if (hasLimit) ...[
                Text(
                  ' / ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(totalLimit, isGuest),
                  compact: true,
                  fixedLength: 0,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  '${(utilization * 100).round()}%',
                  style: textTheme.titleSmall?.copyWith(
                    color: heroColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.cc_totalOutstanding,
            style: textTheme.labelMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          if (hasLimit) ...[
            SizedBox(height: spacing.elementGap),
            FinanceProgressBar(
              value: utilization,
              fillColor: heroColor,
              trackColor: color.surfaceContainerHighest,
              stripeColor: heroColor.withValues(alpha: 0.20),
              height: spacing.progressNormal,
              semanticLabel: ctxt.cc_utilization,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildUtilizationMilestones(
              utilization,
              heroColor,
              color,
              textTheme,
              spacing,
              reduceMotion,
            ),
          ],
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap,
              vertical: spacing.elementGapMin,
            ),
            decoration: BoxDecoration(
              color: heroColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              border: Border.all(color: heroColor.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.walletCards,
                  size: 14,
                  color: heroColor,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  ctxt.cc_acrossCards(summary.cardCount),
                  style: textTheme.labelSmall?.copyWith(
                    color: heroColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  ctxt.cc_totalMinimumDue,
                  style: textTheme.labelSmall?.copyWith(
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
                  style: textTheme.labelSmall?.copyWith(
                    color: color.tertiary,
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

  Widget _buildCardVisual(
    Color heroColor,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Container(
      width: double.infinity,
      height: spacing.sectionGap * 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            heroColor.withValues(alpha: 0.18),
            color.surfaceContainerHighest,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.creditCard,
        color: heroColor,
        size: spacing.iconXL * 2.2,
      ),
    );
  }

  Widget _buildUtilizationMilestones(
    double progress,
    Color accentColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool reduceMotion,
  ) {
    const milestones = [0, 25, 50, 75, 100];
    const milestoneIcons = [
      LucideIcons.circle,
      LucideIcons.chartBar,
      LucideIcons.target,
      LucideIcons.triangleAlert,
      LucideIcons.circleAlert,
    ];
    final currentIndex = milestones.lastIndexWhere(
      (milestone) => milestone / 100 <= progress,
    );

    return Semantics(
      label: 'Credit utilization milestones',
      value: '${(progress * 100).round()}%',
      child: Column(
        children: [
          SizedBox(
            height: spacing.elementGap * 3.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: spacing.elementGap,
                  right: spacing.elementGap,
                  child: Container(
                    height: spacing.progressThin,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                  ),
                ),
                Positioned(
                  left: spacing.elementGap,
                  right: spacing.elementGap,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: spacing.progressThin,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.72),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < milestones.length; index++)
                      _utilizationMilestoneDot(
                        reached: index <= currentIndex,
                        isCurrent: index == currentIndex && progress < 1,
                        icon: milestoneIcons[index],
                        accentColor: accentColor,
                        color: color,
                        spacing: spacing,
                        reduceMotion: reduceMotion,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < milestones.length; index++)
                Text(
                  '${milestones[index]}%',
                  style: textTheme.labelSmall?.copyWith(
                    color: index <= currentIndex
                        ? accentColor
                        : color.onSurfaceVariant,
                    fontWeight: index == currentIndex
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _utilizationMilestoneDot({
    required bool reached,
    required bool isCurrent,
    required IconData icon,
    required Color accentColor,
    required ColorScheme color,
    required AppSpacing spacing,
    required bool reduceMotion,
  }) {
    final markerSize = spacing.elementGap * (isCurrent ? 2.75 : 2.25);
    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        color: isCurrent
            ? accentColor.withValues(alpha: 0.14)
            : reached
                ? accentColor
                : color.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent || reached
              ? accentColor
              : color.outlineVariant.withValues(alpha: 0.7),
          width: isCurrent ? spacing.strokeThin * 1.5 : spacing.strokeThin,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        reached ? LucideIcons.check : icon,
        size: isCurrent ? spacing.iconSM : spacing.iconXS,
        color: isCurrent
            ? accentColor
            : reached
                ? color.onPrimary
                : color.onSurfaceVariant,
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
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),

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
                          summary.outstanding,
                          isGuest,
                        ),
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
                          summary.minimumDue,
                          isGuest,
                        ),
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
                    onPressed: () =>
                        _navigateToPayment(context, card, summary.outstanding),
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
                      onPressed: () => _navigateToPayment(
                        context,
                        card,
                        summary.minimumDue,
                      ),
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
        FinanceProgressBar(
          value: clampedPct.toDouble(),
          fillColor: barColor,
          trackColor: color.outlineVariant.withValues(alpha: 0.2),
          stripeColor: barColor.withValues(alpha: 0.16),
          height: spacing.progressNormal,
          semanticLabel: ctxt.cc_utilization,
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

  /// Paying a credit card bill moves money from a bank/cash account *into*
  /// the card account — it's a transfer, not a standalone expense. Routing
  /// through `AddEditTransactionScreen` (a plain expense with no account
  /// context) never actually reduced the card's outstanding balance.
  void _navigateToPayment(BuildContext context, Account card, double amount) {
    HapticFeedback.lightImpact();
    context.push(
      AppRoutes.transfer,
      extra: {
        'toAccount': card,
        'amount': amount > 0 ? amount.toStringAsFixed(2) : null,
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

class _CreditCardBillsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _CreditCardBillsAppBar({
    required this.title,
    required this.summary,
    required this.isGuest,
    required this.spacing,
    required this.onBack,
  });

  final String title;
  final CreditCardBillsSummary summary;
  final bool isGuest;
  final AppSpacing spacing;
  final VoidCallback onBack;

  @override
  Size get preferredSize => Size.fromHeight(80 + spacing.cardInner * 2.5);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      leading: Padding(
        padding: EdgeInsets.only(left: spacing.cardHorizontal),
        child: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: spacing.cardHorizontal),
          child: Tooltip(
            message: summary.cardCount == 1
                ? '1 credit card'
                : '${summary.cardCount} credit cards',
            child: CircleAvatar(
              radius: spacing.elementGap + 2,
              backgroundColor: color.primary.withValues(alpha: 0.12),
              child: Icon(
                LucideIcons.creditCard,
                size: 16,
                color: color.primary,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(spacing.cardInner * 2.5),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            0,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Row(
            children: [
              Expanded(
                child: _headerAmount(
                  context,
                  AppLocalizations.of(context)!.cc_totalOutstanding,
                  GuestModeUtil.applyGuestMode(
                    summary.totalOutstanding,
                    isGuest,
                  ),
                ),
              ),
              SizedBox(width: spacing.elementGap * 2),
              Expanded(
                child: _headerAmount(
                  context,
                  AppLocalizations.of(context)!.cc_totalMinimumDue,
                  GuestModeUtil.applyGuestMode(
                    summary.totalMinimumDue,
                    isGuest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAmount(BuildContext context, String label, double amount) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: spacing.elementGapMin),
        CurrencyText(
          amount: amount,
          compact: false,
          fixedLength: 0,
          style: textTheme.titleLarge?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WarningItem {
  final String text;
  final Color color;

  const _WarningItem({required this.text, required this.color});
}
