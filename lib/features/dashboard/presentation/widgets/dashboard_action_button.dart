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
    
    final isPrimary = widget.backgroundColor == null;
    final bgColor = widget.backgroundColor ?? color.primaryContainer;
    final fgColor = widget.iconColor ?? color.primary;
    final txtColor = widget.textColor ?? color.onPrimaryContainer;

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary 
                ? color.primary.withValues(alpha: 0.3)
                : color.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: color.primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: fgColor.withValues(alpha: 0.15),
                    child: Icon(widget.icon, size: 20, color: fgColor),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: txtColor,
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
      ),
    );

    return widget.heroTag != null ? Hero(tag: widget.heroTag!, child: button) : button;
  }
}
