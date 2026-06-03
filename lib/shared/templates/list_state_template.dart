import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Template B — List + State
///
/// Used for: transactions, bills, notifications.
/// Structure:
///   - Optional filter header
///   - Scrollable list with builder
///   - Optional state badge per item
///   - Empty state when list is empty
///
/// This template ONLY renders. It does NOT compute state.
class ListStateTemplate<T> extends ConsumerWidget {
  /// Items to display.
  final List<T> items;

  /// Builder for each item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional filter/header widget above the list.
  final Widget? filterHeader;

  /// Widget shown when items is empty.
  final Widget? emptyState;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Optional FAB.
  final Widget? floatingActionButton;

  /// Optional separator between items.
  final Widget? separator;

  const ListStateTemplate({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.filterHeader,
    this.emptyState,
    this.isLoading = false,
    this.floatingActionButton,
    this.separator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          // Filter header
          if (filterHeader != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: filterHeader,
              ),
            ),

          // Empty state
          if (items.isEmpty && emptyState != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: emptyState,
            ),

          // Item list
          if (items.isNotEmpty)
            SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  separator ?? const SizedBox.shrink(),
              itemBuilder: (context, index) =>
                  itemBuilder(context, items[index], index),
            ),
        ],
      ),
    );
  }
}
