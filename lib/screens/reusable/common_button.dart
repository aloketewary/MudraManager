import 'package:flutter/material.dart';
import 'package:mudra_manager/theme/design_tokens.dart';

class CommonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backGroundColor;
  final Color? textColor;
  final IconData? iconData;
  final TextStyle? textStyle;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backGroundColor,
    this.iconData,
    this.textColor,
    this.textStyle,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationFast,
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

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ElevatedButton(
          onPressed: null, // Handled by GestureDetector
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backGroundColor ?? color.primary,
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMedium,
            ),
            elevation: DesignTokens.elevation2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconData != null) Icon(
                widget.iconData, 
                color: widget.textColor ?? color.onPrimary, 
                size: DesignTokens.iconSizeMedium,
              ),
              if (widget.iconData != null) SizedBox(width: DesignTokens.spacing12),
              Text(
                widget.text.toUpperCase(), 
                style: widget.textStyle ?? textTheme.labelLarge?.copyWith(
                  color: widget.textColor ?? color.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
