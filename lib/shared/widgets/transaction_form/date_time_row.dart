import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DateTimeRow extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool allowFuture;

  const DateTimeRow({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.allowFuture = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildChip(
            context: context,
            icon: LucideIcons.calendar,
            label: DateFormat('MMM dd, yyyy').format(selectedDate),
            color: color,
            textTheme: textTheme,
            onTap: () => _pickDate(context),
            spacing: spacing,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildChip(
            context: context,
            icon: LucideIcons.clock,
            label: DateFormat('hh:mm a').format(selectedDate),
            color: color,
            textTheme: textTheme,
            onTap: () => _pickTime(context),
            spacing: spacing,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ColorScheme color,
    required TextTheme textTheme,
    required VoidCallback onTap,
    required AppSpacing spacing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final safeInitial =
        selectedDate.isAfter(now) && !allowFuture ? now : selectedDate;
    final pick = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(2000),
      lastDate: allowFuture ? DateTime(2030) : now,
    );
    if (pick != null) {
      HapticFeedback.lightImpact();
      onDateChanged(
        DateTime(
          pick.year,
          pick.month,
          pick.day,
          selectedDate.hour,
          selectedDate.minute,
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (picked != null) {
      HapticFeedback.lightImpact();
      onDateChanged(
        DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }
}
