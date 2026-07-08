import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';

/// Shows a bottom sheet to edit how an expense is split among participants.
void showEditSplitSheet({
  required BuildContext context,
  required Trip trip,
  required TripTransaction tripTxn,
  required List<TripParticipant> selectedParticipants,
  required SplitType splitType,
  required Map<int, double> splitAmounts,
  required VoidCallback onChanged,
  required AppSpacing spacing,
}) {
  final amount = tripTxn.resolvedAmount ?? 0.0;
  final controllers = <int, TextEditingController>{};
  for (var p in selectedParticipants) {
    controllers[p.id] = TextEditingController(
      text: (splitAmounts[p.id] ?? 0).toString(),
    );
  }

  var currentSplitType = splitType;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(spacing.radiusSmall * 2),
      ),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final color = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        double currentSum = 0;
        for (var id in selectedParticipants.map((p) => p.id)) {
          currentSum += splitAmounts[id] ?? 0;
        }
        final isPercentage = currentSplitType == SplitType.percentage;
        final target = isPercentage ? 100.0 : amount;
        final remaining = target - currentSum;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.expense_editSplit,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Split Type', style: textTheme.titleSmall),
                  if ((currentSplitType == SplitType.custom ||
                          currentSplitType == SplitType.percentage) &&
                      amount > 0)
                    Text(
                      isPercentage
                          ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
                          : 'Remaining: ${formatCurrency(remaining, decimals: 2)}',
                      style: textTheme.labelLarge?.copyWith(
                        color: remaining.abs() < 0.1
                            ? color.primary
                            : (remaining < 0 ? color.error : color.tertiary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<SplitType>(
                segments: const [
                  ButtonSegment(
                    value: SplitType.equal,
                    label: Text('Equal'),
                    icon: Icon(LucideIcons.chartPie, size: 16),
                  ),
                  ButtonSegment(
                    value: SplitType.percentage,
                    label: Text('%'),
                    icon: Icon(LucideIcons.percent, size: 16),
                  ),
                  ButtonSegment(
                    value: SplitType.custom,
                    label: Text('Custom'),
                    icon: Icon(LucideIcons.calculator, size: 16),
                  ),
                ],
                selected: {currentSplitType},
                onSelectionChanged: (Set<SplitType> selected) {
                  currentSplitType = selected.first;
                  onChanged();
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              Text('Participants', style: textTheme.titleSmall),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: trip.participants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = trip.participants.toList()[index];
                    final isSelected =
                        selectedParticipants.any((sp) => sp.id == p.id);

                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isSelected) {
                          selectedParticipants
                              .removeWhere((sp) => sp.id == p.id);
                          splitAmounts.remove(p.id);
                        } else {
                          selectedParticipants.add(p);
                          if (currentSplitType != SplitType.equal) {
                            splitAmounts[p.id] = 0.0;
                            controllers[p.id] =
                                TextEditingController(text: '0');
                          }
                        }
                        onChanged();
                        setModalState(() {});
                      },
                      borderRadius:
                          BorderRadius.circular(spacing.radiusSmall),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.primaryContainer.withValues(alpha: 0.2)
                              : color.surface,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                          border: Border.all(
                            color: isSelected
                                ? color.primary.withValues(alpha: 0.5)
                                : color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected
                                  ? color.primary
                                  : color.surfaceContainerHighest,
                              child: Text(
                                p.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: isSelected
                                      ? color.onPrimary
                                      : color.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: (currentSplitType == SplitType.custom ||
                                          currentSplitType ==
                                              SplitType.percentage) &&
                                      isSelected
                                  ? Row(
                                      children: [
                                        Text(
                                          p.name,
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (currentSplitType ==
                                                SplitType.percentage &&
                                            amount > 0)
                                          Text(
                                            '${formatCurrency((amount * (splitAmounts[p.id] ?? 0) / 100), decimals: 0)}  ',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: color.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: controllers[p.id],
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            decoration: InputDecoration(
                                              prefixText: currentSplitType ==
                                                      SplitType.percentage
                                                  ? ''
                                                  : null,
                                              prefix: currentSplitType !=
                                                      SplitType.percentage
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        right: 4,
                                                      ),
                                                      child: CurrencyBadge(
                                                        code: BaseCurrency.code,
                                                        size: 12,
                                                      ),
                                                    )
                                                  : null,
                                              suffixText: currentSplitType ==
                                                      SplitType.percentage
                                                  ? '%'
                                                  : null,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  LucideIcons.wand,
                                                  size: 18,
                                                  color: color.primary,
                                                ),
                                                tooltip: 'Auto-fill remaining',
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  double othersSum = 0;
                                                  for (var sp
                                                      in selectedParticipants) {
                                                    if (sp.id == p.id) continue;
                                                    othersSum +=
                                                        splitAmounts[sp.id] ??
                                                            0;
                                                  }
                                                  final rem =
                                                      target - othersSum;
                                                  splitAmounts[p.id] = rem;
                                                  controllers[p.id]!.text =
                                                      rem.toStringAsFixed(
                                                    isPercentage ? 1 : 2,
                                                  );
                                                  onChanged();
                                                  setModalState(() {});
                                                },
                                              ),
                                            ),
                                            onChanged: (value) {
                                              splitAmounts[p.id] =
                                                  double.tryParse(value) ?? 0.0;
                                              onChanged();
                                              setModalState(() {});
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      p.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                            ),
                            if (isSelected &&
                                currentSplitType == SplitType.equal)
                              Icon(
                                LucideIcons.circleCheck,
                                color: color.primary,
                              )
                            else if (!isSelected)
                              Icon(
                                LucideIcons.circle,
                                color: color.outline,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  for (var c in controllers.values) {
                    c.dispose();
                  }
                  ctx.pop();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(AppLocalizations.of(context)!.common_done),
              ),
            ],
          ),
        );
      },
    ),
  );
}
