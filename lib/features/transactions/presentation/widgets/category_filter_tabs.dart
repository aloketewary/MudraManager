import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Horizontal category filter tabs.
///
/// Features:
/// - Smooth animated selection transitions
/// - Scroll-aware tab centering
/// - Accessibility with proper semantics
/// - Theming via AppSpacing
class CategoryFilterTabs extends ConsumerStatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CategoryFilterTabs({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    required this.onTabSelected,
  });

  @override
  ConsumerState<CategoryFilterTabs> createState() => _CategoryFilterTabsState();
}

class _CategoryFilterTabsState extends ConsumerState<CategoryFilterTabs> {
  late final ScrollController _scrollController;
  late List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryFilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelectedTab();
    }
  }

  void _scrollToSelectedTab() {
    if (widget.tabs.isEmpty || !mounted) return;

    final index = widget.selectedIndex.clamp(0, widget.tabs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _tabKeys[index].currentContext;
      if (tabContext == null) return;

      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : ref.read(spacingProvider).animNormal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return Container(
      height: spacing.touchTargetSmall + spacing.elementGapMin,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGapMin,
          vertical: spacing.elementGapMin,
        ),
        itemCount: widget.tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing.elementGapMin),
        itemBuilder: (context, index) {
          final isSelected = widget.selectedIndex == index;
          return _FilterTab(
            key: _tabKeys[index],
            index: index,
            label: widget.tabs[index],
            isSelected: isSelected,
            spacing: spacing,
            colorScheme: colorScheme,
            isReducedMotion: isReducedMotion,
            onTap: () {
              widget.onTabSelected(index);
              _scrollToSelectedTab();
            },
          );
        },
      ),
    );
  }
}

/// Individual filter tab with animated selection state.
class _FilterTab extends StatelessWidget {
  final int index;
  final String label;
  final bool isSelected;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;
  final VoidCallback onTap;

  const _FilterTab({
    super.key,
    required this.index,
    required this.label,
    required this.isSelected,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
    required this.onTap,
  });

  IconData get _icon {
    return switch (index) {
      1 => LucideIcons.arrowUpRight,
      2 => LucideIcons.arrowDownLeft,
      3 => LucideIcons.arrowLeftRight,
      _ => LucideIcons.listFilter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
          splashFactory: isReducedMotion ? NoSplash.splashFactory : null,
          child: AnimatedContainer(
            duration: isReducedMotion ? Duration.zero : spacing.animFast,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: spacing.touchTargetSmall),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal + spacing.elementGapMin,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.65)
                    : colorScheme.outlineVariant.withValues(alpha: 0.7),
                width: isSelected ? spacing.strokeNormal : spacing.strokeThin,
              ),
              borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, size: spacing.iconXS, color: foregroundColor),
                SizedBox(width: spacing.elementGapUltraMin),
                AnimatedDefaultTextStyle(
                  duration: isReducedMotion ? Duration.zero : spacing.animFast,
                  curve: Curves.easeOutCubic,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 0.1,
                        height: 1.1,
                      ),
                  child: Text(label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
