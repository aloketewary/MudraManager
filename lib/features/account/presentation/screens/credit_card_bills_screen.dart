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
import 'package:mudra_manager/features/account/data/credit_card_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class CreditCardBillsScreen extends ConsumerWidget {
  const CreditCardBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final summariesAsync = ref.watch(creditCardSummariesProvider);
    final isGuest = ref.watch(guestModeProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(ctxt.cc_title),
        elevation: 0,
      ),
      body: summariesAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return _buildEmpty(color, textTheme, spacing, ctxt);
          }

          final totalOutstanding =
              summaries.fold<double>(0, (s, c) => s + c.outstanding);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              _buildTotalHero(
                totalOutstanding, summaries.length, isGuest,
                color, textTheme, spacing, ctxt,
              ),
              SizedBox(height: spacing.sectionGap),
              ...summaries.map(
                (s) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.sectionGap),
                  child: _buildCardTile(
                    s, isGuest, color, textTheme, spacing, ctxt, context,
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
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.creditCard, size: 64,
              color: color.onSurfaceVariant.withValues(alpha: 0.3)),
          SizedBox(height: spacing.sectionGap),
          Text(ctxt.cc_noCards, style: textTheme.titleMedium?.copyWith(
            color: color.onSurfaceVariant,
          )),
          SizedBox(height: spacing.elementGap),
          Text(ctxt.cc_noCardsHint, style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant.withValues(alpha: 0.6),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalHero(
    double total, int cardCount, bool isGuest,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isZero = total == 0;
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
            amount: GuestModeUtil.applyGuestMode(total, isGuest),
            compact: false,
            fixedLength: 0,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: heroColor,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.cc_acrossCards(cardCount),
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(
    CreditCardSummary summary, bool isGuest,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt, BuildContext context,
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
                  child: Icon(LucideIcons.creditCard, size: 20,
                      color: cardColor),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                      if (card.accountNumber != null)
                        Text('•••• ${card.accountNumber}',
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
                    child: Text(dueStatus, style: textTheme.labelSmall?.copyWith(
                      color: dueColor,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: color.outlineVariant.withValues(alpha: 0.3)),

          // Outstanding + Minimum Due
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Expanded(
                  child: _metricColumn(
                    ctxt.account_outstanding,
                    GuestModeUtil.applyGuestMode(summary.outstanding, isGuest),
                    summary.outstanding > 0 ? color.error : color.primary,
                    textTheme, spacing,
                    currencyCode: card.currencyCode,
                  ),
                ),
                Expanded(
                  child: _metricColumn(
                    ctxt.cc_minimumDue,
                    GuestModeUtil.applyGuestMode(summary.minimumDue, isGuest),
                    color.tertiary,
                    textTheme, spacing,
                    currencyCode: card.currencyCode,
                  ),
                ),
                if (summary.billingCycleSpend > 0)
                  Expanded(
                    child: _metricColumn(
                      ctxt.cc_cycleSpend,
                      GuestModeUtil.applyGuestMode(
                          summary.billingCycleSpend, isGuest),
                      color.secondary,
                      textTheme, spacing,
                      currencyCode: card.currencyCode,
                    ),
                  ),
              ],
            ),
          ),

          // Utilization bar
          if (hasLimit) ...[
            Divider(height: 1,
                color: color.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: _buildUtilization(
                utilPct, card.creditLimit!, summary.outstanding, isGuest,
                cardColor, color, textTheme, spacing, ctxt,
              ),
            ),
          ],

          // Dates row
          if (card.statementDay != null || card.dueDay != null) ...[
            Divider(height: 1,
                color: color.outlineVariant.withValues(alpha: 0.3)),
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
                        cardColor, textTheme, spacing,
                      ),
                    ),
                  if (summary.nextDueDate != null)
                    Expanded(
                      child: _dateChip(
                        LucideIcons.calendarClock,
                        ctxt.cc_nextDue,
                        DateFormat('d MMM', safeDateLocale)
                            .format(summary.nextDueDate!),
                        dueColor, textTheme, spacing,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Pay action
          if (summary.outstanding > 0) ...[
            Divider(height: 1,
                color: color.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Expanded(
                    child: _payButton(
                      ctxt.cc_payMinimum,
                      summary.minimumDue,
                      color.tertiary,
                      card,
                      color, textTheme, spacing, context,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: _payButton(
                      ctxt.cc_payFull,
                      summary.outstanding,
                      color.primary,
                      card,
                      color, textTheme, spacing, context,
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
    String label, double amount, Color accentColor,
    TextTheme textTheme, AppSpacing spacing, {String? currencyCode,}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(
          color: accentColor.withValues(alpha: 0.7),
        )),
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
    double utilPct, double limit, double outstanding, bool isGuest,
    Color cardColor, ColorScheme color, TextTheme textTheme,
    AppSpacing spacing, AppLocalizations ctxt,
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
            Text(ctxt.cc_utilization, style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            )),
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
    IconData icon, String label, String value,
    Color accentColor, TextTheme textTheme, AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: accentColor),
        SizedBox(width: spacing.elementGapMin),
        Text('$label ', style: textTheme.labelSmall?.copyWith(
          color: accentColor.withValues(alpha: 0.7),
        )),
        Text(value, style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _payButton(
    String label, double amount, Color accent, Account card,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    BuildContext context,
  ) {
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.addTransaction, extra: {
          'isIncome': false,
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
      ),
      child: Text(label, style: textTheme.labelSmall?.copyWith(
        color: accent,
        fontWeight: FontWeight.w600,
      )),
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
