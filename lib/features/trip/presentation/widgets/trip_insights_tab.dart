import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_state.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class TripInsightsTab extends StatelessWidget {
  final GroupDetailState state;
  final bool isGuestMode;
  final AppSpacing spacing;

  const TripInsightsTab({
    super.key,
    required this.state,
    required this.isGuestMode,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final insights = state.insights;
    final header = state.header;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (insights.totalCost == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chartBar,
                  size: 64,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                BuddyMessages.noData,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add expenses to see report',
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _buildSummary(insights, header, color, textTheme),
        SizedBox(height: spacing.sectionGap),
        _buildPerPerson(insights, header, color, textTheme),
        SizedBox(height: spacing.sectionGap),
        _buildCategories(insights, header, color, textTheme),
      ],
    );
  }

  Widget _buildSummary(
    InsightsView insights,
    GroupHeaderView header,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            Icon(LucideIcons.wallet, color: color.primary, size: 28),
            SizedBox(height: spacing.elementGap),
            Text(
              'Total Trip Cost',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: spacing.elementGap),
            CurrencyText(
              amount: GuestModeUtil.applyGuestMode(
                insights.totalCost,
                isGuestMode,
              ),
              currencyCode: header.currencyCode,
              compact: false,
              showPositiveSign: false,
              showSign: true,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.onPrimaryContainer,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              children: [
                _statPill(
                  LucideIcons.receiptText,
                  'Transactions',
                  '${insights.transactionCount}',
                  color,
                  textTheme,
                ),
                SizedBox(width: spacing.elementGap),
                _statPill(
                  LucideIcons.users,
                  'Per Person',
                  formatCurrency(
                    GuestModeUtil.applyGuestMode(
                      insights.perPersonAverage,
                      isGuestMode,
                    ),
                    code: header.currencyCode,
                    decimals: 0,
                  ),
                  color,
                  textTheme,
                ),
                SizedBox(width: spacing.elementGap),
                _statPill(
                  LucideIcons.trendingUp,
                  'Avg/Txn',
                  formatCurrency(
                    GuestModeUtil.applyGuestMode(
                      insights.averagePerTransaction,
                      isGuestMode,
                    ),
                    code: header.currencyCode,
                    decimals: 0,
                  ),
                  color,
                  textTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(
    IconData icon,
    String label,
    String value,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: spacing.cardVertical,
          horizontal: spacing.cardHorizontal,
        ),
        decoration: BoxDecoration(
          color: color.onPrimaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: color.onPrimaryContainer.withValues(alpha: 0.6),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onPrimaryContainer,
              ),
            ),
            SizedBox(height: spacing.cardVerticalMin),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerPerson(
    InsightsView insights,
    GroupHeaderView header,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final chartColors = [
      color.primary,
      color.tertiary,
      color.secondary,
      color.error,
      color.primaryContainer,
      color.tertiaryContainer,
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.users, color: color.secondary, size: 20),
                SizedBox(width: spacing.sectionGap),
                Text(
                  'Per Person Summary',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ...insights.participantSpending.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final isTop = insights.topSpender?.id == p.id;
              final barColor = chartColors[i % chartColors.length];

              return Container(
                margin: EdgeInsets.only(bottom: spacing.elementGap),
                padding: EdgeInsets.all(spacing.elementGap * 1.5),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipOval(
                        child: BoringAvatar(
                          name: p.name,
                          palette: BoringAvatarPalette([
                            color.primary,
                            color.tertiary,
                            color.primaryContainer,
                            color.tertiaryContainer,
                          ]),
                          type: BoringAvatarType.beam,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.cardHorizontal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isTop) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    '👑 Top',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.percentage / 100,
                              minHeight: 6,
                              backgroundColor: color.surface,
                              valueColor: AlwaysStoppedAnimation(barColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CurrencyText(
                          amount: GuestModeUtil.applyGuestMode(
                            p.amountPaid,
                            isGuestMode,
                          ),
                          currencyCode: header.currencyCode,
                          compact: false,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                          showPositiveSign: false,
                          showSign: true,
                        ),
                        Text(
                          '${p.percentage.toStringAsFixed(1)}%',
                          style: textTheme.bodySmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(
    InsightsView insights,
    GroupHeaderView header,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final chartColors = [
      color.primary,
      color.tertiary,
      color.secondary,
      color.error,
      color.primaryContainer,
      color.tertiaryContainer,
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.chartPie, color: color.primary, size: 20),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Category Breakdown',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ...insights.categories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final catColor = chartColors[i % chartColors.length];

              return Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: spacing.sectionGap),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    CurrencyText(
                      amount: GuestModeUtil.applyGuestMode(
                        cat.amount,
                        isGuestMode,
                      ),
                      currencyCode: header.currencyCode,
                      compact: false,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                      showPositiveSign: false,
                      showSign: true,
                    ),
                    SizedBox(width: spacing.sectionGap),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${cat.percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
