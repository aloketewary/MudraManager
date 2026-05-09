import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class AppCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final effectiveColor = color ?? colorScheme.surfaceContainer;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(spacing.radiusMedium);

    return Card(
      elevation: 0,
      color: effectiveColor,
      child: onTap != null
          ? InkWell(
              borderRadius: effectiveBorderRadius,
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}
