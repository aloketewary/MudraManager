import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:table_calendar/table_calendar.dart';

enum PeriodType { day, week, month, year, custom }

/// Human-readable label for the currently selected period (e.g. "June 2026",
/// "This Week", "12 Jun - 18 Jun"). Shared by the full selector and any
/// compact text-button trigger.
String periodLabel(
  AppLocalizations l10n,
  PeriodType period,
  DateTime? customStart,
  DateTime? customEnd,
) {
  final now = DateTime.now();
  switch (period) {
    case PeriodType.day:
      return DateFormat.MMMd().format(now);
    case PeriodType.week:
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}';
    case PeriodType.month:
      return DateFormat.yMMMM().format(now);
    case PeriodType.year:
      return DateFormat.y().format(now);
    case PeriodType.custom:
      if (customStart != null && customEnd != null) {
        return '${DateFormat.MMMd().format(customStart)} - ${DateFormat.MMMd().format(customEnd)}';
      }
      return l10n.stats_selectRange;
  }
}

/// Opens the shared period-picker bottom sheet (quick chips + custom range
/// calendar). Used by [PeriodCalendarSelector] and by any compact
/// text-button trigger that wants the same picker without the large
/// dropdown-style header widget.
void showPeriodPickerSheet({
  required BuildContext context,
  required AppSpacing spacing,
  required PeriodType selectedPeriod,
  DateTime? customStart,
  DateTime? customEnd,
  required void Function(PeriodType period, DateTime? start, DateTime? end)
      onChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PeriodPickerSheetContent(
      spacing: spacing,
      selectedPeriod: selectedPeriod,
      initialStart: customStart,
      initialEnd: customEnd,
      onChanged: onChanged,
    ),
  );
}

class _PeriodPickerSheetContent extends StatefulWidget {
  final AppSpacing spacing;
  final PeriodType selectedPeriod;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(PeriodType period, DateTime? start, DateTime? end)
      onChanged;

  const _PeriodPickerSheetContent({
    required this.spacing,
    required this.selectedPeriod,
    this.initialStart,
    this.initialEnd,
    required this.onChanged,
  });

  @override
  State<_PeriodPickerSheetContent> createState() =>
      _PeriodPickerSheetContentState();
}

class _PeriodPickerSheetContentState
    extends State<_PeriodPickerSheetContent> {
  late DateTime? _rangeStart = widget.initialStart;
  late DateTime? _rangeEnd = widget.initialEnd;
  late PeriodType _selected = widget.selectedPeriod;
  late DateTime _focusedDay = DateTime.now();

  AppSpacing get spacing => widget.spacing;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
      ),
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.cardVertical,
        spacing.cardHorizontal,
        spacing.cardVerticalMax + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          Text(
            l10n.stats_selectPeriod,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing.sectionGap),

          // Period grid — 2 columns, full width
          Row(
            children: [
              Expanded(
                child: _buildGridChip(
                  PeriodType.day,
                  l10n.stats_today,
                  LucideIcons.calendarCheck,
                  color,
                  textTheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridChip(
                  PeriodType.week,
                  l10n.stats_thisWeek,
                  LucideIcons.columns3,
                  color,
                  textTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGridChip(
                  PeriodType.month,
                  l10n.stats_thisMonth,
                  LucideIcons.calendarDays,
                  color,
                  textTheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridChip(
                  PeriodType.year,
                  l10n.stats_thisYear,
                  LucideIcons.calendarDays,
                  color,
                  textTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Custom range — full width, same height
          _buildGridChip(
            PeriodType.custom,
            l10n.stats_customRange,
            LucideIcons.calendarRange,
            color,
            textTheme,
          ),

          // Calendar (shown when custom is selected)
          if (_selected == PeriodType.custom) ...[
            SizedBox(height: spacing.elementGap),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              selectedDayPredicate: (day) => false,
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focused;
                });
                if (start != null && end != null) {
                  HapticFeedback.lightImpact();
                  widget.onChanged(PeriodType.custom, start, end);
                  Navigator.pop(context);
                }
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor:
                    color.primaryContainer.withValues(alpha: 0.3),
                todayTextStyle: TextStyle(color: color.onSurface),
                rangeStartTextStyle: TextStyle(color: color.onPrimary),
                rangeEndTextStyle: TextStyle(color: color.onPrimary),
                disabledTextStyle: TextStyle(
                  color: color.onSurface.withValues(alpha: 0.3),
                ),
                weekendTextStyle: TextStyle(color: color.onSurface),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridChip(
    PeriodType period,
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final isSelected = _selected == period;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (period == PeriodType.custom) {
            setState(() => _selected = period);
          } else {
            setState(() => _selected = period);
            widget.onChanged(period, null, null);
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.primaryContainer
                : color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? color.primary.withValues(alpha: 0.5)
                  : color.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color.primary : color.onSurfaceVariant,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? color.primary : color.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full dropdown-style period selector (icon + label + chevron container).
/// Kept for screens that want the larger, more prominent header treatment.
/// For a compact single text-button trigger, use [showPeriodPickerSheet]
/// directly instead.
class PeriodCalendarSelector extends StatelessWidget {
  final PeriodType selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;
  final Function(PeriodType period, DateTime? start, DateTime? end) onChanged;
  final AppSpacing spacing;

  const PeriodCalendarSelector({
    super.key,
    required this.selectedPeriod,
    this.customStart,
    this.customEnd,
    required this.onChanged,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          showPeriodPickerSheet(
            context: context,
            spacing: spacing,
            selectedPeriod: selectedPeriod,
            customStart: customStart,
            customEnd: customEnd,
            onChanged: onChanged,
          );
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  color: color.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  periodLabel(l10n, selectedPeriod, customStart, customEnd),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronDown,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
