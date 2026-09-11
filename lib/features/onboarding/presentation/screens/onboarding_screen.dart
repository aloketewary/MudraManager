import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/models/onboarding_page_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _animationsDisabled =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration _animationDuration(Duration duration) =>
      _animationsDisabled ? Duration.zero : duration;

  void _goNext() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: _animationDuration(const Duration(milliseconds: 300)),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.accountSetup);
    }
  }

  void _goBack() {
    _controller.previousPage(
      duration: _animationDuration(const Duration(milliseconds: 300)),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToAccountSetup() {
    HapticFeedback.lightImpact();
    context.go(AppRoutes.accountSetup);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isLast = _currentPage == onboardingData.length - 1;

    return Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(color, textTheme, spacing, ctxt, isLast),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => LayoutBuilder(
                  builder: (context, constraints) {
                    final data = onboardingData[index];

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal + 8,
                        vertical: spacing.cardVertical,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: _AnimatedPagePart(
                                  duration: _animationDuration(
                                    const Duration(milliseconds: 360),
                                  ),
                                  child: _buildFinancePreview(
                                    color: color,
                                    data: data,
                                    index: index,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _AnimatedPagePart(
                              duration: _animationDuration(
                                const Duration(milliseconds: 280),
                              ),
                              delay: const Duration(milliseconds: 40),
                              child: Text(
                                ctxt.translate(data.title),
                                style: textTheme.headlineLarge?.copyWith(
                                  color: color.onSurface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _AnimatedPagePart(
                              duration: _animationDuration(
                                const Duration(milliseconds: 280),
                              ),
                              delay: const Duration(milliseconds: 80),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: Text(
                                  ctxt.translate(data.description),
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: color.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildBottomBar(color, textTheme, spacing, ctxt, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isLast,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal + 8,
        spacing.cardVertical + 4,
        spacing.cardHorizontal + 8,
        spacing.cardVertical,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Mudra logo',
            image: true,
            child: Image.asset(
              'assets/logo/logo.png',
              width: 32,
              height: 32,
              excludeFromSemantics: true,
            ),
          ),
          const Spacer(),
          if (!isLast)
            TextButton(
              onPressed: _skipToAccountSetup,
              style: TextButton.styleFrom(
                foregroundColor: color.onSurfaceVariant,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: Text(
                ctxt.onboard_skip,
                style: textTheme.labelLarge?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.75),
              ),
            ),
            child: IconButton(
              tooltip: ctxt.onboard_languages,
              onPressed: () => LanguageService.showLanguagePicker(context, ref),
              icon: Icon(
                LucideIcons.languages,
                size: 19,
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancePreview({
    required ColorScheme color,
    required OnboardingPage data,
    required int index,
  }) {
    final accent = color.primary;
    const barHeights = [28.0, 46.0, 36.0, 68.0, 54.0, 78.0, 62.0];

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _PreviewMark(
                  color: color,
                  accent: accent,
                  data: data,
                  showLogo: index == 0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PreviewRule(
                        color: color,
                        width: 88,
                        height: 8,
                        emphasis: true,
                      ),
                      const SizedBox(height: 8),
                      _PreviewRule(color: color, width: 132, height: 5),
                    ],
                  ),
                ),
                _PreviewRule(color: color, width: 42, height: 8),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 126,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.48),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  barHeights.length,
                  (barIndex) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: barIndex == barHeights.length - 1 ? 0 : 8,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: _animationDuration(
                            Duration(milliseconds: 160 + barIndex * 20),
                          ),
                          height: barHeights[barIndex],
                          decoration: BoxDecoration(
                            color: barIndex == barHeights.length - 1
                                ? accent
                                : accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _PreviewMetric(color: color, accent: accent)),
                const SizedBox(width: 12),
                Expanded(child: _PreviewMetric(color: color, accent: accent)),
                const SizedBox(width: 12),
                Expanded(child: _PreviewMetric(color: color, accent: accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isLast,
  ) {
    final progress = (_currentPage + 1) / onboardingData.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal + 8,
        spacing.cardVertical,
        spacing.cardHorizontal + 8,
        spacing.cardVerticalMax + 8,
      ),
      child: Column(
        children: [
          Semantics(
            label: 'Onboarding progress',
            value: 'Step ${_currentPage + 1} of ${onboardingData.length}',
            child: Row(
              children: [
                Text(
                  '${(_currentPage + 1).toString().padLeft(2, '0')} / '
                  '${onboardingData.length.toString().padLeft(2, '0')}',
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == onboardingData.length - 1 ? 0 : 6,
                          ),
                          child: AnimatedContainer(
                            duration: _animationDuration(
                              const Duration(milliseconds: 240),
                            ),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index < _currentPage + 1
                                  ? color.primary
                                  : color.outlineVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.labelMedium?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentPage > 0) ...[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _goBack,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: color.onSurface,
                      side: BorderSide(
                        color: color.outlineVariant.withValues(alpha: 0.8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _goNext();
                    },
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast
                              ? ctxt.translate('onboard_GetStarted')
                              : ctxt.onboard_continue,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (isLast) ...[
                          const SizedBox(width: 10),
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
    );
  }
}

class _AnimatedPagePart extends StatelessWidget {
  const _AnimatedPagePart({
    required this.duration,
    required this.child,
    this.delay = Duration.zero,
  });

  final Duration duration;
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(child),
      duration: duration == Duration.zero ? Duration.zero : duration + delay,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _PreviewMark extends StatelessWidget {
  const _PreviewMark({
    required this.color,
    required this.accent,
    required this.data,
    required this.showLogo,
  });

  final ColorScheme color;
  final Color accent;
  final OnboardingPage data;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: showLogo
          ? Image.asset(
              'assets/logo/logo.png',
              excludeFromSemantics: true,
              fit: BoxFit.contain,
            )
          : Icon(data.icon, size: 22, color: accent),
    );
  }
}

class _PreviewRule extends StatelessWidget {
  const _PreviewRule({
    required this.color,
    required this.width,
    required this.height,
    this.emphasis = false,
  });

  final ColorScheme color;
  final double width;
  final double height;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.onSurface.withValues(alpha: emphasis ? 0.72 : 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.color, required this.accent});

  final ColorScheme color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 4,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.7,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: color.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
