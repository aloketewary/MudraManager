import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: child,
    );
  }
}

class HapticElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const HapticElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: child,
    );
  }
}

class HapticIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;

  const HapticIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      icon: icon,
    );
  }
}

class HapticInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  const HapticInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      borderRadius: borderRadius,
      child: child,
    );
  }
}

class HapticGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const HapticGestureDetector({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: child,
    );
  }
}

// Extension method for easy haptic feedback
extension HapticCallback on VoidCallback {
  VoidCallback withHaptic() {
    return () {
      HapticFeedback.lightImpact();
      this();
    };
  }
}
