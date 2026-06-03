import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_preview_screen.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/responsive_helper.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class ThemePickerScreen extends ConsumerStatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  ConsumerState<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends ConsumerState<ThemePickerScreen> {
  late AppColorTheme _tempSelectedTheme;

  @override
  void initState() {
    super.initState();
    _tempSelectedTheme = ref.read(themeNotifierProvider);
  }

  void _applyTheme() {
    final ctxt = context.mounted ? AppLocalizations.of(context)! : null;
    ref.read(themeNotifierProvider.notifier).setTheme(_tempSelectedTheme);
    SnackbarService.success(
      ctxt?.theme_themeAppliedMessage ?? 'Theme applied!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final isPro = ref.watch(hasFullAccessProvider).value ?? false;

    // Separate free and pro themes
    final freeThemes = AppColorTheme.values.where((t) => !t.isPro).toList();
    final proThemes = AppColorTheme.values.where((t) => t.isPro).toList();

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.theme_chooseThemeTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        fab: ScreenAction(
          id: 'apply_theme',
          label: ctxt.theme_applyThemeLabel,
          icon: LucideIcons.circleCheck,
          onTap: _applyTheme,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Free Themes ──
          _buildSectionHeader('Themes', color, textTheme),
          const SizedBox(height: 12),
          _buildThemeGrid(
            freeThemes,
            isPro: true,
            color: color,
            textTheme: textTheme,
          ),
          const SizedBox(height: 28),

          // ── Pro Themes ──
          _buildSectionHeader(
            'Pro Themes',
            color,
            textTheme,
            showProBadge: !isPro,
          ),
          const SizedBox(height: 12),
          _buildThemeGrid(
            proThemes,
            isPro: isPro,
            color: color,
            textTheme: textTheme,
          ),
          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme, {
    bool showProBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
          if (showProBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.primary, color.tertiary],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRO',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeGrid(
    List<AppColorTheme> themes, {
    required bool isPro,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveHelper.getGridAspectRatio(
          context,
          defaultRatio: 0.70,
          singleColumnRatio: 1.2,
        ),
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = _tempSelectedTheme == theme;
        final isLocked = theme.isPro && !isPro;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Opacity(
                    opacity: isLocked ? 0.55 : 1.0,
                    child: ThemePreviewCard(
                      theme: theme,
                      isSelected: isSelected,
                      onTap: () {
                        if (isLocked) {
                          HapticFeedback.mediumImpact();
                          context.push(AppRoutes.upgrade);
                          return;
                        }
                        setState(() => _tempSelectedTheme = theme);
                      },
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              theme.label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? color.primary
                    : isLocked
                        ? color.onSurfaceVariant.withValues(alpha: 0.5)
                        : color.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              theme.subtitle,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(
                  alpha: isLocked ? 0.4 : 0.7,
                ),
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}
