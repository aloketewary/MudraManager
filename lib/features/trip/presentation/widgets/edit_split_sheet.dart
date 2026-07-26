import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/trip/data/group_detail_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';

/// Shows a bottom sheet to edit how an expense is split among participants.
///
/// [splitAmounts] must be keyed by participant id and hold **currency**
/// values, matching `TripTransaction.splitAmounts` storage convention (used
/// consistently even for `SplitType.percentage` — see
/// `AddTripTransactionScreen._computeSplitAmounts`). The sheet converts to
/// percentage points only for display/input when that split type is active.
///
/// On "Done", persists the edit via `TripService.updateTripTransactionSplit`
/// and invalidates the relevant providers — previously this sheet only
/// mutated local widget state and popped, silently discarding edits.
void showEditSplitSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Trip trip,
  required TripTransaction tripTxn,
  required List<TripParticipant> selectedParticipants,
  required SplitType splitType,
  required Map<int, double> splitAmounts,
  required VoidCallback onChanged,
  required AppSpacing spacing,
}) {
  final amount = tripTxn.resolvedAmount ?? 0.0;
  final ctxt = AppLocalizations.of(context)!;

  // Working copies — currency units always, regardless of display mode.
  final workingParticipants = List<TripParticipant>.from(selectedParticipants);
  final workingAmounts = Map<int, double>.from(splitAmounts);
  var currentSplitType = splitType;
  var saving = false;

  /// Value shown in the text field for [id] given the active split type.
  double displayValue(int id) {
    final currencyValue = workingAmounts[id] ?? 0;
    if (currentSplitType == SplitType.percentage && amount > 0) {
      return currencyValue / amount * 100;
    }
    return currencyValue;
  }

  /// Converts a raw text-field input (already in display units) back to
  /// currency and stores it.
  void setFromDisplayValue(int id, double displayInput) {
    if (currentSplitType == SplitType.percentage) {
      workingAmounts[id] = amount * displayInput / 100;
    } else {
      workingAmounts[id] = displayInput;
    }
  }

  final controllers = <int, TextEditingController>{};
  for (final p in workingParticipants) {
    controllers[p.id] = TextEditingController(
      text: displayValue(p.id).toStringAsFixed(
        currentSplitType == SplitType.percentage ? 1 : 2,
      ),
    );
  }

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

        final isPercentage = currentSplitType == SplitType.percentage;
        final displaySum = workingParticipants.fold<double>(
          0,
          (sum, p) => sum + displayValue(p.id),
        );
        final target = isPercentage ? 100.0 : amount;
        final remaining = target - displaySum;

        Future<void> save() async {
          if (workingParticipants.isEmpty || saving) return;
          setModalState(() => saving = true);
          HapticFeedback.mediumImpact();
          try {
            // For an equal split, always derive fresh equal shares rather
            // than persisting whatever custom/percentage amounts happen to
            // still be sitting in workingAmounts from a previous mode.
            final finalAmounts = currentSplitType == SplitType.equal
                ? List<double>.filled(
                    workingParticipants.length,
                    amount / workingParticipants.length,
                  )
                : workingParticipants.map((p) => workingAmounts[p.id] ?? 0).toList();

            await ref.read(tripServiceProvider).updateTripTransactionSplit(
                  tripTransactionId: tripTxn.id,
                  splitType: currentSplitType,
                  participantIds: workingParticipants.map((p) => p.id).toList(),
                  splitAmounts: finalAmounts,
                );
            ref.invalidate(tripByIdProvider(trip.id));
            ref.invalidate(groupDetailProvider(trip.id));
            for (final c in controllers.values) {
              c.dispose();
            }
            if (ctx.mounted) ctx.pop();
            onChanged();
            if (context.mounted) {
              SnackbarService.success(ctxt.expense_splitUpdated, spacing);
            }
          } catch (e) {
            if (context.mounted) {
              SnackbarService.error('${ctxt.common_error}: $e', spacing);
            }
          } finally {
            setModalState(() => saving = false);
          }
        }

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
                ctxt.expense_editSplit,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ctxt.trip_splitType, style: textTheme.titleSmall),
                  if ((currentSplitType == SplitType.custom || isPercentage) &&
                      amount > 0)
                    Text(
                      isPercentage
                          ? '${ctxt.expense_remaining}: ${remaining.toStringAsFixed(1)}%'
                          : '${ctxt.expense_remaining}: ${formatCurrency(remaining, code: trip.currencyCode, decimals: 2)}',
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
                segments: [
                  ButtonSegment(
                    value: SplitType.equal,
                    label: Text(ctxt.trip_equally),
                    icon: const Icon(LucideIcons.chartPie, size: 16),
                  ),
                  const ButtonSegment(
                    value: SplitType.percentage,
                    label: Text('%'),
                    icon: Icon(LucideIcons.percent, size: 16),
                  ),
                  ButtonSegment(
                    value: SplitType.custom,
                    label: Text(ctxt.trip_custom),
                    icon: const Icon(LucideIcons.calculator, size: 16),
                  ),
                ],
                selected: {currentSplitType},
                onSelectionChanged: (Set<SplitType> selected) {
                  HapticFeedback.selectionClick();
                  currentSplitType = selected.first;
                  // Refresh every controller's text to the new display unit.
                  for (final p in workingParticipants) {
                    controllers[p.id]?.text = displayValue(p.id).toStringAsFixed(
                      currentSplitType == SplitType.percentage ? 1 : 2,
                    );
                  }
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              Text(ctxt.trip_splitWith, style: textTheme.titleSmall),
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
                        workingParticipants.any((sp) => sp.id == p.id);

                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isSelected) {
                          workingParticipants.removeWhere((sp) => sp.id == p.id);
                          workingAmounts.remove(p.id);
                          controllers.remove(p.id)?.dispose();
                        } else {
                          workingParticipants.add(p);
                          workingAmounts[p.id] = 0.0;
                          controllers[p.id] = TextEditingController(text: '0');
                        }
                        setModalState(() {});
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
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
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
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
                                          isPercentage) &&
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
                                        if (isPercentage && amount > 0)
                                          Text(
                                            '${formatCurrency(workingAmounts[p.id] ?? 0, code: trip.currencyCode, decimals: 0)}  ',
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
                                              prefix: !isPercentage
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        right: 4,
                                                      ),
                                                      child: CurrencyBadge(
                                                        code: trip.currencyCode ??
                                                            BaseCurrency.code,
                                                        size: 12,
                                                      ),
                                                    )
                                                  : null,
                                              suffixText: isPercentage ? '%' : null,
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
                                                tooltip:
                                                    ctxt.trip_autoFillRemaining,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  double othersSum = 0;
                                                  for (final sp
                                                      in workingParticipants) {
                                                    if (sp.id == p.id) continue;
                                                    othersSum += displayValue(sp.id);
                                                  }
                                                  final rem = target - othersSum;
                                                  setFromDisplayValue(p.id, rem);
                                                  controllers[p.id]!.text =
                                                      rem.toStringAsFixed(
                                                    isPercentage ? 1 : 2,
                                                  );
                                                  setModalState(() {});
                                                },
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setFromDisplayValue(
                                                p.id,
                                                double.tryParse(value) ?? 0.0,
                                              );
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
                onPressed: saving ? null : save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ctxt.common_done),
              ),
            ],
          ),
        );
      },
    ),
  );
}
