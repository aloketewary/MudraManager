import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionFilterChips extends StatelessWidget {
  final int? selectedCategoryId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final int? selectedTagId;
  final String? selectedTagName;
  final VoidCallback onClearCategory;
  final VoidCallback onClearDateRange;
  final VoidCallback? onClearTag;

  const TransactionFilterChips({
    super.key,
    this.selectedCategoryId,
    this.filterStartDate,
    this.filterEndDate,
    this.selectedTagId,
    this.selectedTagName,
    required this.onClearCategory,
    required this.onClearDateRange,
    this.onClearTag,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectedCategoryId == null &&
        filterStartDate == null &&
        selectedTagId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (selectedCategoryId != null)
            Chip(
              avatar: Icon(Icons.category_rounded, size: 18, color: color.primary),
              label: Text('Category', style: textTheme.labelMedium),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: color.primaryContainer,
              side: BorderSide.none,
              onDeleted: () {
                HapticFeedback.mediumImpact();
                onClearCategory();
              },
            ),
          if (selectedTagId != null)
            Chip(
              avatar: Icon(Icons.label_rounded, size: 18, color: color.tertiary),
              label: Text(selectedTagName ?? 'Tag', style: textTheme.labelMedium),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: color.tertiaryContainer,
              side: BorderSide.none,
              onDeleted: () {
                HapticFeedback.mediumImpact();
                onClearTag?.call();
              },
            ),
          if (filterStartDate != null)
            Chip(
              avatar: Icon(Icons.date_range_rounded, size: 18, color: color.primary),
              label: Text('Date Range', style: textTheme.labelMedium),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: color.primaryContainer,
              side: BorderSide.none,
              onDeleted: () {
                HapticFeedback.mediumImpact();
                onClearDateRange();
              },
            ),
        ],
      ),
    );
  }
}
