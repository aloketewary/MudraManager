import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FrequencyType { daily, weekly, monthly, yearly }

class FrequencySelector extends StatelessWidget {
  final FrequencyType selectedFrequency;
  final Function(FrequencyType) onChanged;
  final int? customInterval;
  final Function(int)? onIntervalChanged;

  const FrequencySelector({
    super.key,
    required this.selectedFrequency,
    required this.onChanged,
    this.customInterval,
    this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<FrequencyType>(
          segments: const [
            ButtonSegment(
              value: FrequencyType.daily,
              label: Text('Daily'),
              icon: Icon(LucideIcons.calendarCheck, size: 16),
            ),
            ButtonSegment(
              value: FrequencyType.weekly,
              label: Text('Weekly'),
              icon: Icon(LucideIcons.calendarDays, size: 16),
            ),
            ButtonSegment(
              value: FrequencyType.monthly,
              label: Text('Monthly'),
              icon: Icon(LucideIcons.calendar, size: 16),
            ),
            ButtonSegment(
              value: FrequencyType.yearly,
              label: Text('Yearly'),
              icon: Icon(LucideIcons.calendar, size: 16),
            ),
          ],
          selected: {selectedFrequency},
          onSelectionChanged: (Set<FrequencyType> selected) {
            HapticFeedback.mediumImpact();
            onChanged(selected.first);
          },
        ),
        if (customInterval != null && onIntervalChanged != null) ...[
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Repeat every',
              suffixText: _getIntervalSuffix(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final interval = int.tryParse(value);
              if (interval != null) onIntervalChanged!(interval);
            },
          ),
        ],
      ],
    );
  }

  String _getIntervalSuffix() {
    switch (selectedFrequency) {
      case FrequencyType.daily:
        return 'days';
      case FrequencyType.weekly:
        return 'weeks';
      case FrequencyType.monthly:
        return 'months';
      case FrequencyType.yearly:
        return 'years';
    }
  }
}
