import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';

class CommonDropdownField<T> extends ConsumerWidget {
  const CommonDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.labelText,
    this.hintText,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final Widget Function(T) itemBuilder;
  final String? labelText;
  final String? hintText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items:
            items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: itemBuilder(item), // Use the provided builder
                  ),
                )
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(spacing.radiusSmall)),
          fillColor: Colors.transparent,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            borderSide: BorderSide(color: color.secondary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
