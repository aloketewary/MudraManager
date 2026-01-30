import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/isar_provider.dart'
    show reminderTimeProvider;
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/service/notification_service.dart'
    show NotificationService;
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    var textTheme = Theme.of(context).textTheme;
    var ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ctxt.app_settings_appbar_title,
          style: textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ProfileTile(
                    title: ctxt.app_settings_language_title,
                    subtitle: ctxt.app_settings_language_subtitle,
                    icon: Icons.language_outlined,
                    onTap: () => context.push('/language'),
                  ),
                  ProfileTile(
                    title: ctxt.app_settings_theme_mode_title,
                    subtitle: _getSubtitle(currentTheme, ctxt),
                    icon: Icons.color_lens_outlined,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  ThemeMode.values.map((mode) {
                                    return ListTile(
                                      title: Text(_getSubtitle(mode, ctxt)),
                                      leading: Icon(
                                        mode == ThemeMode.light
                                            ? Icons.light_mode
                                            : mode == ThemeMode.dark
                                            ? Icons.dark_mode
                                            : Icons.phone_android,
                                      ),
                                      selected: currentTheme == mode,
                                      onTap: () {
                                        themeNotifier.setTheme(mode);
                                        context.pop();
                                      },
                                    );
                                  }).toList(),
                            ),
                      );
                    },
                  ),
                  ProfileTile(
                    title: 'Choose Theme',
                    subtitle: 'Select your preferred theme',
                    icon: Icons.format_paint_outlined,
                    onTap: () => context.push('/theme'),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final reminderTime = ref.watch(reminderTimeProvider);

                      return ProfileTile(
                        title: ctxt.app_settings_daily_reminder_title,
                        subtitle:
                            reminderTime != null
                                ? "Set a daily notification at ${reminderTime.format(context)}"
                                : "Set a daily notification time",
                        icon: Icons.notifications_active_outlined,
                        onTap: () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: reminderTime ?? TimeOfDay.now(),
                          );

                          if (selectedTime != null) {
                            await NotificationService.scheduleDailyReminder(
                              selectedTime,
                            );
                            ref.read(reminderTimeProvider.notifier).state =
                                selectedTime;

                            SnackbarService.success(
                              'Reminder set for ${selectedTime.format(context)}',
                            );
                          }
                        },
                      );
                    },
                  ),
                  ProfileTile(
                    title: "Backup and Restore",
                    subtitle: "Backup and Restore App Data",
                    icon: Icons.settings_backup_restore,
                    onTap: () => context.push('/backup-restore'),
                  ),
                  ProfileTile(
                    title: "About Mudra Manager",
                    subtitle: "Version, team and legal information",
                    icon: Icons.info_outline,
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),
            ),
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
