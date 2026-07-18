import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Glass-styled dropdown for day selection (statement day / due day).
///
/// Usage:
/// ```dart
/// GlassDayPicker(
///   label: 'Statement Day',
///   value: _statementDay,
///   icon: LucideIcons.calendarRange,
///   onChanged: (v) => setState(() => _statementDay = v),
///   accentColor: _selectedColor,
/// )
/// ```
class GlassDayPicker extends ConsumerWidget {
  final String label;
  final int? value;
  final IconData icon;
  final ValueChanged<int?> onChanged;
  final Color accentColor;

  const GlassDayPicker({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch<AppSpacing>(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: color.surface.withValues(alpha: isDark ? 0.6 : 0.7),
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: accentColor),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: value,
            isExpanded: true,
            isDense: true,
            hint: Text('—', style: textTheme.bodyLarge),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text('—', style: textTheme.bodyLarge),
              ),
              ...List.generate(31, (i) => i + 1).map(
                (day) => DropdownMenuItem(
                  value: day,
                  child: Text('$day', style: textTheme.bodyLarge),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}