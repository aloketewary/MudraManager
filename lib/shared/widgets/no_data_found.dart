import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mudra_manager/core/theme/design_tokens.dart';

class NoDataFound extends StatelessWidget {
  final String message;
  final String? imagePath;
  final IconData? iconData;
  final Widget? action;

  const NoDataFound({
    super.key,
    required this.message,
    this.imagePath,
    this.iconData,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    assert(imagePath != null || iconData != null);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing24),
            child: imagePath != null
                ? Image.asset(imagePath!, width: 128)
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.1, 1.1),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      )
                : Container(
                        padding: const EdgeInsets.all(DesignTokens.spacing24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.primaryContainer.withValues(alpha: 0.3),
                        ),
                        child: Icon(iconData, size: 80, color: color.primary),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.05, 1.05),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing32,
              vertical: DesignTokens.spacing16,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null)
            Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spacing16),
                  child: action,
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
