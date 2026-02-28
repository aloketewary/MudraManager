import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final String? heroTag;

  const DashboardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.heroTag,
  });

  @override
  State<DashboardActionButton> createState() => _DashboardActionButtonState();
}

class _DashboardActionButtonState extends State<DashboardActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 0,
        color: widget.backgroundColor ?? color.primaryContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            HapticFeedback.mediumImpact();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (widget.iconColor ?? color.primary).withValues(alpha: 0.15),
                  child: Icon(widget.icon, size: 20, color: widget.iconColor ?? color.primary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: widget.textColor ?? color.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widget.heroTag != null ? Hero(tag: widget.heroTag!, child: button) : button;
  }
}
