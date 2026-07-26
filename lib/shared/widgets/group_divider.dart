import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Divider for grouped cards with configurable color and indent.
class GroupDivider extends ConsumerWidget {
  const GroupDivider({
    super.key,
    this.indent = 58,
    this.color,
  });

  final double indent;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.outlineVariant;

    return Divider(
      height: 1,
      indent: indent,
      color: effectiveColor.withValues(alpha: 0.4),
    );
  }
}
