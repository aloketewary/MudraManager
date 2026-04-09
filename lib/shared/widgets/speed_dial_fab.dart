import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class ExpandableFab extends StatefulWidget {
  final AnimationController? visibilityController;
  final EdgeInsets padding;

  const ExpandableFab({
    super.key,
    this.visibilityController,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  State<ExpandableFab> createState() => ExpandableFabState();
}

class ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  bool _isOpen = false;
  bool _navigating = false;

  // Collapsed pill width / expanded bar width — measured via layout
  static const _collapsedWidth = 100.0;
  static const _expandedWidth = 340.0;
  static const _height = 52.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void close() {
    if (_isOpen) _toggle();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _controller.forward() : _controller.reverse();
  }

  void _onItemTap(String route, {Map<String, dynamic>? extra}) {
    if (_navigating) return;
    _navigating = true;
    HapticFeedback.lightImpact();
    _toggle();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) context.push(route, extra: extra);
      _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrim — always in tree, animated opacity
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _curve,
            builder: (_, __) {
              final v = _curve.value;
              return IgnorePointer(
                ignoring: v < 0.01,
                child: GestureDetector(
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: v * 0.3),
                  ),
                ),
              );
            },
          ),
        ),

        // Morphing bar
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.padding.bottom + MediaQuery.of(context).padding.bottom,
          child: _buildVisibilityWrapper(
            child: Center(
              child: AnimatedBuilder(
                animation: _curve,
                builder: (context, __) => _buildBar(context, _curve.value),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityWrapper({required Widget child}) {
    if (widget.visibilityController == null) return child;
    return AnimatedBuilder(
      animation: widget.visibilityController!,
      builder: (_, c) {
        final v = widget.visibilityController!.value;
        return IgnorePointer(
          ignoring: v < 0.5,
          child: Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 60),
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildBar(BuildContext context, double t) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = lerpDouble(_collapsedWidth, _expandedWidth, t)!;

    return GestureDetector(
      // Tap bar background to collapse when expanded
      onTap: _isOpen ? _toggle : null,
      child: Container(
        width: width,
        height: _height,
        decoration: BoxDecoration(
          color: Color.lerp(
            color.primaryContainer,
            color.surfaceContainerHigh,
            t,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: color.shadow.withValues(alpha: 0.1 + (t * 0.1)),
              blurRadius: 8 + (t * 16),
              offset: Offset(0, 3 + (t * 3)),
              spreadRadius: t * 2,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Collapsed content — fades out
              Opacity(
                opacity: (1 - t * 3).clamp(0.0, 1.0), // gone by t=0.33
                child: IgnorePointer(
                  ignoring: t > 0.1,
                  child: InkWell(
                    onTap: _toggle,
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(
                      width: _collapsedWidth,
                      height: _height,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 20,
                            color: color.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add',
                            style: textTheme.labelLarge?.copyWith(
                              color: color.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded content — fades in
              Opacity(
                opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0), // starts at t=0.3
                child: IgnorePointer(
                  ignoring: t < 0.5,
                  child: SizedBox(
                    width: _expandedWidth,
                    height: _height,
                    child: Row(
                      children: [
                        _buildActionItem(
                          icon: LucideIcons.trendingDown,
                          label: 'Expense',
                          accentColor: color.error,
                          color: color,
                          textTheme: textTheme,
                          onTap: () => _onItemTap(AppRoutes.addTransaction),
                        ),
                        _buildDivider(color, t),
                        _buildActionItem(
                          icon: LucideIcons.trendingUp,
                          label: 'Income',
                          accentColor: color.primary,
                          color: color,
                          textTheme: textTheme,
                          onTap: () => _onItemTap(
                            AppRoutes.addTransaction,
                            extra: {'isIncome': true},
                          ),
                        ),
                        _buildDivider(color, t),
                        _buildActionItem(
                          icon: LucideIcons.arrowLeftRight,
                          label: 'Transfer',
                          accentColor: color.tertiary,
                          color: color,
                          textTheme: textTheme,
                          onTap: () => _onItemTap(AppRoutes.transfer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color accentColor,
    required ColorScheme color,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme color, double t) {
    return Opacity(
      opacity: ((t - 0.5) / 0.5).clamp(0.0, 1.0), // fades in late
      child: Container(
        width: 1,
        height: 24,
        decoration: BoxDecoration(
          color: color.outlineVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
