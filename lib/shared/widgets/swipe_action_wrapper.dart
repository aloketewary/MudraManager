import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwipeActionWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool enablePeek;

  const SwipeActionWrapper({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.enablePeek = false,
  });

  @override
  ConsumerState<SwipeActionWrapper> createState() => _SwipeActionWrapperState();
}

class _SwipeActionWrapperState extends ConsumerState<SwipeActionWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _peekController;
  late final Animation<Offset> _peekAnimation;
  bool _showPeek = false;
  final bool _peekTriggered = false;

  @override
  void initState() {
    super.initState();
    _peekController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _peekAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.25, 0))
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(-0.25, 0)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-0.25, 0),
          end: const Offset(0.25, 0),
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.25, 0)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.25, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 10,
      ),
    ]).animate(_peekController);

    _peekController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showPeek = false);
      }
    });
  }

  @override
  void didUpdateWidget(SwipeActionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enablePeek && !oldWidget.enablePeek && !_peekTriggered) {
      _maybeShowPeek();
    }
  }

  Future<void> _maybeShowPeek() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_seen_swipe_peek') == true) return;

    await prefs.setBool('has_seen_swipe_peek', true);

    if (!mounted) return;
    setState(() => _showPeek = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      HapticFeedback.lightImpact();
      _peekController.forward();
    }
  }

  @override
  void dispose() {
    _peekController.dispose();
    super.dispose();
  }

  Widget _buildDismissible(ColorScheme color, AppSpacing spacing,) {
    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          widget.onEdit();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          widget.onDelete();
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.pencil, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(LucideIcons.trash2, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final dismissible = _buildDismissible(color, spacing,);

    if (!_showPeek) return dismissible;

    return _PeekOverlay(
      animation: _peekAnimation,
      color: color,
      spacing: spacing,
      child: dismissible,
    );
  }
}

class _PeekOverlay extends AnimatedWidget {
  final Animation<Offset> animation;
  final ColorScheme color;
  final Widget child;
  final AppSpacing spacing;

  const _PeekOverlay({
    required this.animation,
    required this.color,
    required this.child,
    required this.spacing,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final dx = animation.value.dx;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (dx < 0)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: color.error,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Opacity(
                opacity: (-dx / 0.25).clamp(0.0, 1.0),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        if (dx > 0)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Opacity(
                opacity: (dx / 0.25).clamp(0.0, 1.0),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.pencil, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        FractionalTranslation(
          translation: animation.value,
          child: child,
        ),
      ],
    );
  }
}
