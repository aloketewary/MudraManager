import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionSearchBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          autofocus: true,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: TextStyle(color: color.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(LucideIcons.search, color: color.primary, size: 22),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onClear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
