import 'package:auto_skeleton/auto_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/transactions/data/bill_control_center_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_surface.dart';

class RecurringExpensesCard extends ConsumerWidget {
  const RecurringExpensesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final expenses = ref.watch(dashboardRecurringExpensesProvider);
    final summaryAsync = ref.watch(billControlCenterProvider);
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    if (expenses.isEmpty) return const SizedBox.shrink();

    return summaryAsync.when(
      loading: () => _buildCardSurface(
        context,
        spacing: spacing,
        color: color,
        ctxt: ctxt,
        accent: color.primary,
        child: AutoSkeleton(
          enabled: !MediaQuery.of(context).disableAnimations,
          debugShowBones: false,
          child: _buildLoadingContent(
            spacing,
            color,
            Theme.of(context).textTheme,
            ctxt,
          ),
        ),
      ),
      error: (_, __) => _buildCardSurface(
        context,
        spacing: spacing,
        color: color,
        ctxt: ctxt,
        accent: color.primary,
        child: _buildFallbackContent(
          spacing,
          color,
          Theme.of(context).textTheme,
          ctxt,
          expenses.length,
        ),
      ),
      data: (data) {
        final isGuestMode = ref.watch(guestModeProvider);
        final overdueCount = data.expenseOverdue
            .where((bill) => !data.paidBillIds.contains(bill.id))
            .length;
        final dueSoonCount = data.expenseDueSoon
            .where((bill) => !data.paidBillIds.contains(bill.id))
            .length;
        final accent = overdueCount > 0
            ? color.error
            : dueSoonCount > 0
                ? color.tertiary
                : color.primary;

        return _buildCardSurface(
          context,
          spacing: spacing,
          color: color,
          ctxt: ctxt,
          accent: accent,
          child: _buildSummaryContent(
            spacing: spacing,
            color: color,
            textTheme: Theme.of(context).textTheme,
            ctxt: ctxt,
            monthlyTotal: GuestModeUtil.applyGuestMode(
              data.expenseMonthlyTotal,
              isGuestMode,
            ),
            activeCount: data.activeExpenseCount,
            overdueCount: overdueCount,
            dueSoonCount: dueSoonCount,
            accent: accent,
            reduceMotion: MediaQuery.of(context).disableAnimations,
          ),
        );
      },
    );
  }

  Widget _buildCardSurface(
    BuildContext context, {
    required AppSpacing spacing,
    required ColorScheme color,
    required AppLocalizations ctxt,
    required Color accent,
    required Widget child,
  }) {
    return FinanceSurface(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      borderRadius: BorderRadius.circular(spacing.radiusLarge),
      accent: accent,
      semanticLabel: ctxt.title_billControlCenter,
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.recurringTransactions);
      },
      child: child,
    );
  }

  Widget _buildHeader(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    return Row(
      children: [
        Container(
          width: spacing.touchTargetSmall,
          height: spacing.touchTargetSmall,
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          child: Icon(
            LucideIcons.repeat,
            color: color.primary,
            size: spacing.iconMD,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Text(
            ctxt.title_billControlCenter,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          LucideIcons.chevronRight,
          color: color.onSurfaceVariant,
          size: spacing.iconSM,
        ),
      ],
    );
  }

  Widget _buildSummaryContent({
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppLocalizations ctxt,
    required double monthlyTotal,
    required int activeCount,
    required int overdueCount,
    required int dueSoonCount,
    required Color accent,
    required bool reduceMotion,
  }) {
    final statusLabel = overdueCount > 0
        ? ctxt.billCenter_overdue
        : dueSoonCount > 0
            ? ctxt.billCenter_thisWeek
            : ctxt.billCenter_thisMonth;
    final statusCount = overdueCount > 0 ? overdueCount : dueSoonCount;
    final statusIcon =
        overdueCount > 0 ? LucideIcons.calendarX : LucideIcons.calendarClock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(spacing, color, textTheme, ctxt),
        SizedBox(height: spacing.elementGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.label_monthly,
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapUltraMin),
                  AnimatedBalance(
                    value: monthlyTotal,
                    duration: reduceMotion ? Duration.zero : spacing.animHero,
                    fixedStringLength: 0,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      color: color.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    ctxt.billCenter_activeBills(activeCount),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (overdueCount > 0 || dueSoonCount > 0)
              _buildStatusBadge(
                spacing: spacing,
                textTheme: textTheme,
                label: statusLabel,
                count: statusCount,
                icon: statusIcon,
                accent: accent,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required AppSpacing spacing,
    required TextTheme textTheme,
    required String label,
    required int count,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: spacing.touchTarget * 2.7),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: accent,
            size: spacing.iconXS,
          ),
          SizedBox(width: spacing.elementGapMin),
          Flexible(
            child: Text(
              '$label ($count)',
              style: textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(spacing, color, textTheme, ctxt),
        SizedBox(height: spacing.elementGap),
        Container(
          height: spacing.touchTargetSmall + spacing.elementGap,
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackContent(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    int activeCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(spacing, color, textTheme, ctxt),
        SizedBox(height: spacing.elementGap),
        Text(
          ctxt.billCenter_activeBills(activeCount),
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }
}
