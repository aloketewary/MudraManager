import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class PageTransitions {
  static const Duration _duration = Duration(milliseconds: 300);

  static Widget fadeThrough({
    required Widget child,
    Key? key,
  }) {
    return PageTransitionSwitcher(
      duration: _duration,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: child,
    );
  }

  static Route<T> sharedAxisRoute<T>({
    required Widget page,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      transitionDuration: _duration,
    );
  }

  static Route<T> fadeRoute<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: _duration,
    );
  }
}

class OpenContainerWrapper extends ConsumerWidget {
  final Widget closedBuilder;
  final Widget Function(BuildContext) openBuilder;
  final Color? closedColor;
  final double? borderRadius;

  const OpenContainerWrapper({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.closedColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: closedColor ?? colorScheme.surfaceContainerHighest,
      openColor: colorScheme.surface,
      middleColor: colorScheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? spacing.radiusMedium),
      ),
      transitionDuration: const Duration(milliseconds: 450),
      closedBuilder: (context, action) => closedBuilder,
      openBuilder: (context, action) => openBuilder(context),
    );
  }
}
