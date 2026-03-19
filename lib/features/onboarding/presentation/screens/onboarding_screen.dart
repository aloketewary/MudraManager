import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/models/onboarding_page_model.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _pageColors = [
    Color(0xFF2196F3), // rupee — blue
    Color(0xFFFF9800), // sms — orange
    Color(0xFF4CAF50), // budget — green
    Color(0xFF9C27B0), // insights — purple
    Color(0xFF009688), // secure — teal
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.accountSetup);
    }
  }

  void _goBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == onboardingData.length - 1;

    return Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVerticalMin,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.languages,
                      color: color.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        LanguageService.showLanguagePicker(context, ref),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.accountSetup),
                      child: Text(
                        'Skip',
                        style: textTheme.labelLarge?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // ── PAGE CONTENT ──
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  final accent = _pageColors[index % _pageColors.length];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontalMax + 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon with glow ring
                        TweenAnimationBuilder<double>(
                          key: ValueKey(index),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) => Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: value,
                              child: child,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.25),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                    alpha: isDark ? 0.15 : 0.12,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accent.withValues(
                                      alpha: isDark ? 0.2 : 0.14,
                                    ),
                                    accent.withValues(
                                      alpha: isDark ? 0.08 : 0.05,
                                    ),
                                  ],
                                ),
                              ),
                              child: index == 0
                                  ? Image.asset(
                                      'assets/logo/rupee.png',
                                      width: 64,
                                      height: 64,
                                    )
                                  : Icon(data.icon, size: 64, color: accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Title
                        TweenAnimationBuilder<double>(
                          key: ValueKey('title_$index'),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Text(
                            ctxt.translate(data.title),
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color.onSurface,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Description
                        TweenAnimationBuilder<double>(
                          key: ValueKey('desc_$index'),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Text(
                            ctxt.translate(data.description),
                            style: textTheme.bodyLarge?.copyWith(
                              color: color.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── BOTTOM SECTION ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontalMax + 8,
                0,
                spacing.cardHorizontalMax + 8,
                spacing.cardVerticalMax + 8,
              ),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? _pageColors[_currentPage]
                                : color.onSurfaceVariant.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  spacing.radiusMedium,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              size: 20,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _goNext();
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  spacing.radiusMedium,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'Get Started' : 'Continue',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isLast) ...[
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.arrowRight, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
