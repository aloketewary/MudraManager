import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class TransactionSearchBar extends ConsumerWidget {
  final String searchQuery;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const TransactionSearchBar({
    super.key,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        child: TextField(
          autofocus: true,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: TextStyle(color: color.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(LucideIcons.search, color: color.primary, size: 22),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                  tooltip: 'Close',
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onClear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: color.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
