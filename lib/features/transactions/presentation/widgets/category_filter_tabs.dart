import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryFilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to selected tab when index changes externally
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelectedTab();
    }
  }

  void _scrollToSelectedTab() {
    final targetOffset = _calculateTabOffset(widget.selectedIndex);
    _scrollController.animateTo(
      targetOffset,
      duration: ref.read(spacingProvider).animNormal,
      curve: Curves.easeOutCubic,
    );
  }

  double _calculateTabOffset(int index) {
    const tabWidth = 80.0; // Base tab width
    final spacing = ref.read(spacingProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final tabCount = widget.tabs.length;

    // Center the selected tab
    final totalWidth = tabCount * tabWidth + (tabCount - 1) * spacing.elementGap;
    final targetOffset = (index * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

    return targetOffset.clamp(0.0, (totalWidth - screenWidth).clamp(0.0, double.infinity));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax),
        itemCount: widget.tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing.elementGap),
        itemBuilder: (context, index) {
          final isSelected = widget.selectedIndex == index;
          return _FilterTab(
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
  final String label;
  final bool isSelected;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
        splashFactory: isReducedMotion ? NoSplash.splashFactory : null,
        child: AnimatedContainer(
          duration: isReducedMotion ? Duration.zero : spacing.animFast,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMin + 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.onSurface : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant.withValues(alpha: spacing.opacityMedium),
              width: spacing.strokeThin,
            ),
            borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
          ),
          child: AnimatedDefaultTextStyle(
            duration: isReducedMotion ? Duration.zero : spacing.animFast,
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.surface
                  : colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 1.0,
              height: 1.0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}