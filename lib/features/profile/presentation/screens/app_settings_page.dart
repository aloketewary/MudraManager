import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/guest_mode_toggle.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  late final MarketplaceService _marketplaceService;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveText(
          ctxt.app_settings_appbar_title,
          style: textTheme.titleLarge,
          maxLines: 1,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            context,
            color,
            textTheme,
            LucideIcons.puzzle,
            'Plugins',
            'Manage plugins by category',
            () {
              HapticFeedback.mediumImpact();
              context.push('/plugins');
            },
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            context,
            color,
            textTheme,
            LucideIcons.layoutDashboard,
            'Customize Dashboard',
            'Show/hide and reorder cards',
            () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.dashboardCustomize);
            },
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            context,
            color,
            textTheme,
            LucideIcons.globe,
            ctxt.app_settings_language_title,
            ctxt.app_settings_language_subtitle,
            () {
              HapticFeedback.mediumImpact();
              context.push('/language');
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: _marketplaceService.isPluginEnabled('com.mudra.guest_mode'),
            builder: (context, snapshot) {
              final isPluginEnabled = snapshot.data ?? false;
              if (!isPluginEnabled) return const SizedBox.shrink();
              return const GuestModeToggle();
            },
          ),
          _buildSettingCard(
            context,
            color,
            textTheme,
            LucideIcons.sun,
            ctxt.app_settings_theme_mode_title,
            ctxt.app_settings_theme_mode_subtitle,
            () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ctxt.app_settings_themeModeModalTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...AppThemeMode.values.map(
                        (mode) => Card(
                          elevation: 0,
                          color: currentTheme == mode
                              ? color.primaryContainer
                              : color.surfaceContainerHighest,
                          child: ListTile(
                            title: Text(_getSubtitle(mode, ctxt)),
                            leading: Icon(
                              _getThemeIcon(mode),
                              color: currentTheme == mode
                                  ? color.onPrimaryContainer
                                  : color.onSurface,
                            ),
                            trailing: currentTheme == mode
                                ? Icon(
                                    LucideIcons.check,
                                    color: color.onPrimaryContainer,
                                  )
                                : null,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              themeNotifier.setTheme(mode);
                              context.pop();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: color.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return LucideIcons.sun;
      case AppThemeMode.dark:
        return LucideIcons.moon;
      case AppThemeMode.amoled:
        return LucideIcons.circle;
      case AppThemeMode.system:
        return LucideIcons.smartphone;
    }
  }

  String _getSubtitle(AppThemeMode mode, AppLocalizations ctxt) {
    switch (mode) {
      case AppThemeMode.light:
        return ctxt.app_settings_theme_mode_light;
      case AppThemeMode.dark:
        return ctxt.app_settings_theme_mode_dark;
      case AppThemeMode.amoled:
        return ctxt.app_settings_theme_mode_amoled;
      case AppThemeMode.system:
        return ctxt.app_settings_theme_mode_system_default;
    }
  }
}
