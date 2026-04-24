import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows a bottom sheet with year navigation and a 3×4 month grid.
/// Returns `DateTime(year, month, 1)` or null if dismissed.
Future<DateTime?> showMonthPicker({
  required BuildContext context,
  required DateTime initialMonth,
  DateTime? firstMonth,
  DateTime? lastMonth,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MonthPickerSheet(
      initial: initialMonth,
      first: firstMonth ?? DateTime(2020, 1),
      last: lastMonth ?? DateTime.now(),
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime first;
  final DateTime last;

  const _MonthPickerSheet({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          const SizedBox(height: 16),

          // Year nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Previous',
                icon: const Icon(LucideIcons.chevronLeft, size: 20),
                onPressed: _year > widget.first.year
                    ? () => setState(() => _year--)
                    : null,
              ),
              Text(
                '$_year',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Next',
                icon: const Icon(LucideIcons.chevronRight, size: 20),
                onPressed: _year < widget.last.year
                    ? () => setState(() => _year++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final month = i + 1;
              final date = DateTime(_year, month, 1);
              final isSelected =
                  _year == widget.initial.year && month == widget.initial.month;
              final isCurrent = _year == now.year && month == now.month;
              final isFuture = date.isAfter(DateTime(widget.last.year, widget.last.month + 1, 0));
              final isBefore = date.isBefore(DateTime(widget.first.year, widget.first.month, 1));
              final disabled = isFuture || isBefore;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: disabled
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(date);
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.primary
                          : isCurrent
                              ? color.primary.withValues(alpha: 0.1)
                              : color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat.MMM().format(DateTime(2000, month)),
                      style: text.titleSmall?.copyWith(
                        color: disabled
                            ? color.onSurface.withValues(alpha: 0.25)
                            : isSelected
                                ? color.onPrimary
                                : isCurrent
                                    ? color.primary
                                    : color.onSurface,
                        fontWeight:
                            isSelected || isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
