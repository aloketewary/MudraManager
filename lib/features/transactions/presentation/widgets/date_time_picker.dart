import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends ConsumerWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const DateTimePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return ListTile(
      leading: const Icon(LucideIcons.calendar),
      title: const Text('Date'),
      subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
      trailing: const Icon(LucideIcons.chevronRight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      onTap: () async {
        HapticFeedback.mediumImpact();
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateChanged(date);
        }
      },
    );
  }
}
