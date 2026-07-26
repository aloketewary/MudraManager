import 'package:flutter/material.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Shows full contribution history as a draggable bottom sheet.
void showContributionHistorySheet({
  required BuildContext context,
  required List<GoalContribution> contributions,
  required Goal goal,
  required Color goalColor,
  required AppSpacing spacing,
}) {
  final color = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final ctxt = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: color.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusMedium)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: spacing.elementGap),
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(spacing.sectionGap),
            child: Text(
              ctxt.goal_recentActivity,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
              itemCount: contributions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 48,
                color: color.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (_, i) => _ContributionTile(
                contribution: contributions[i],
                goal: goal,
                goalColor: goalColor,
                spacing: spacing,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContributionTile extends StatelessWidget {
  final GoalContribution contribution;
  final Goal goal;
  final Color goalColor;
  final AppSpacing spacing;

  const _ContributionTile({
    required this.contribution,
    required this.goal,
    required this.goalColor,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final diff = DateTime.now().difference(contribution.date);
    final timeLabel = diff.inDays == 0
        ? ctxt.common_today
        : diff.inDays == 1
            ? ctxt.common_yesterday
            : diff.inDays < 7
                ? ctxt.goal_daysAgo(diff.inDays)
                : safeDateFormat('dd MMM', ctxt.localeName)
                    .format(contribution.date);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.plus, size: 14, color: goalColor),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: CurrencyText(
              currencyCode: goal.currencyCode,
              amount: contribution.amount,
              fixedLength: 0,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            timeLabel,
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
