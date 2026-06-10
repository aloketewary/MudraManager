import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A wrapper that renders a list of widgets with a staggered reveal animation.
class StaggeredWidgetList extends StatefulWidget {
  final List<Widget> children;
  final bool animate;
  final VoidCallback? onComplete;

  const StaggeredWidgetList({
    super.key,
    required this.children,
    this.animate = true,
    this.onComplete,
  });

  @override
  State<StaggeredWidgetList> createState() => _StaggeredWidgetListState();
}

class _StaggeredWidgetListState extends State<StaggeredWidgetList> {
  int _revealedCount = 0;
  bool _allRevealed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _allRevealed = true;
      _revealedCount = widget.children.length;
    } else if (widget.children.isNotEmpty) {
      _revealNext();
    }
  }

  void _revealNext() {
    if (_allRevealed || !mounted) return;
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        _revealedCount++;
        if (_revealedCount >= widget.children.length) {
          _allRevealed = true;
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return SliverList(
        delegate: SliverChildListDelegate(widget.children),
      );
    }

    final visibleCount = _allRevealed ? widget.children.length : _revealedCount;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < visibleCount) {
            if (index == visibleCount - 1 && !_allRevealed) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _revealNext());
            }
            final child = widget.children[index];
            return child
                .animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                );
          }
          return const SizedBox.shrink();
        },
        childCount: widget.children.length,
      ),
    );
  }
}
