import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Animated search bar with smooth reveal/hide animations.
///
/// Features:
/// - Slide + fade reveal animation
/// - Debounced search callback
/// - Haptic feedback
/// - Clear button with animation
/// - Uses spacingProvider for responsive sizing
class AnimatedSearchBar extends ConsumerStatefulWidget {
  /// Called when search query changes
  final ValueChanged<String> onSearch;

  /// Called when search is cleared
  final VoidCallback onClear;

  /// Current search query
  final String currentQuery;

  const AnimatedSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
    this.currentQuery = '',
  });

  @override
  ConsumerState<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends ConsumerState<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _textController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start animation when mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Material(
          elevation: 0,
          color: color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          child: TextField(
            controller: _textController,
            autofocus: true,
            onChanged: _handleSearchChange,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.txnList_searchHint,
              hintStyle: TextStyle(
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                color: color.primary,
                size: spacing.iconMD,
              ),
              suffixIcon: widget.currentQuery.isNotEmpty
                  ? AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return AnimatedOpacity(
                          opacity: _textController.text.isNotEmpty ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: child,
                        );
                      },
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: spacing.iconSM,
                          color: color.onSurfaceVariant,
                        ),
                        onPressed: _handleClear,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: color.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSearchChange(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onSearch(value.toLowerCase());
      }
    });
  }

  void _handleClear() {
    HapticFeedback.mediumImpact();
    _textController.clear();
    widget.onClear();
  }
}