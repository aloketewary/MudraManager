import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class LazyLoadWidget extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final double visibilityThreshold;
  final Duration? delay;

  const LazyLoadWidget({
    super.key,
    required this.child,
    this.placeholder,
    this.visibilityThreshold = 0.1,
    this.delay,
  });

  @override
  ConsumerState<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends ConsumerState<LazyLoadWidget> {
  bool _isLoaded = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_isLoaded && info.visibleFraction >= widget.visibilityThreshold) {
      if (widget.delay != null) {
        Future.delayed(widget.delay!, () {
          if (mounted) setState(() => _isLoaded = true);
        });
      } else {
        setState(() => _isLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);

    return VisibilityDetector(
      key: Key('lazy-${widget.child.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _isLoaded
          ? widget.child
          : widget.placeholder ?? _buildDefaultPlaceholder(spacing),
    );
  }

  Widget _buildDefaultPlaceholder(AppSpacing spacing) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SkeletonLoader(
        width: double.infinity,
        height: 200,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
    );
  }
}
