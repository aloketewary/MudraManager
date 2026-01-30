import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/isar_provider.dart' show reminderTimeProvider;
import 'package:mudra_manager/service/notification_service.dart' show NotificationService;
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
          _buildSettingCard(context, color, textTheme, Icons.color_lens_outlined, ctxt.app_settings_theme_mode_title, _getSubtitle(currentTheme, ctxt), () {
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
          SizedBox(height: 8),
          _buildSettingCard(context, color, textTheme, Icons.format_paint_outlined, 'Choose Theme', 'Select your preferred theme', () {
            HapticFeedback.mediumImpact();
            context.push('/theme');
          }),
          SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final reminderTime = ref.watch(reminderTimeProvider);
            return _buildSettingCard(context, color, textTheme, Icons.notifications_active_outlined, ctxt.app_settings_daily_reminder_title, reminderTime != null ? "Set at ${reminderTime.format(context)}" : "Set a daily notification time", () async {
              HapticFeedback.mediumImpact();
              final selectedTime = await showTimePicker(context: context, initialTime: reminderTime ?? TimeOfDay.now());
              if (selectedTime != null) {
                await NotificationService.scheduleDailyReminder(selectedTime);
                ref.read(reminderTimeProvider.notifier).state = selectedTime;
                SnackbarService.success('Reminder set for ${selectedTime.format(context)}');
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color.primary, size: 24)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.onSurfaceVariant),
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
