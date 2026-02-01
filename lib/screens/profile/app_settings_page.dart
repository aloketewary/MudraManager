import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/isar_provider.dart' show reminderTimeProvider;
import 'package:mudra_manager/service/notification_service.dart' show NotificationService;
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    var ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.app_settings_appbar_title, style: textTheme.titleLarge)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSettingCard(context, color, textTheme, Icons.language_outlined, ctxt.app_settings_language_title, ctxt.app_settings_language_subtitle, () {
            HapticFeedback.mediumImpact();
            context.push('/language');
          }),
          SizedBox(height: 8),
          _buildSettingCard(context, color, textTheme, Icons.brightness_6_outlined, ctxt.app_settings_theme_mode_title, _getSubtitle(currentTheme, ctxt), () {
            HapticFeedback.mediumImpact();
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: color.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                    SizedBox(height: 16),
                    ...ThemeMode.values.map((mode) => ListTile(
                      title: Text(_getSubtitle(mode, ctxt)),
                      leading: Icon(mode == ThemeMode.light ? Icons.light_mode : mode == ThemeMode.dark ? Icons.dark_mode : Icons.phone_android),
                      selected: currentTheme == mode,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        themeNotifier.setTheme(mode);
                        context.pop();
                      },
                    )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = AppColors.glassGradient(color.primary, isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: AppColors.glassShadow(color.primary, isDark),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 2))]),
              child: Icon(icon, color: color.primary, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.primary),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(ThemeMode mode, AppLocalizations ctxt) {
    switch (mode) {
      case ThemeMode.light:
        return ctxt.app_settings_theme_mode_light;
      case ThemeMode.dark:
        return ctxt.app_settings_theme_mode_dark;
      default:
        return ctxt.app_settings_theme_mode_system_default;
    }
  }
}
