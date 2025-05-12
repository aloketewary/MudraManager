import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/isar_provider.dart'
    show reminderTimeProvider;
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/screens/profile/about_app.dart' show AboutScreen;
import 'package:mudra_manager/screens/profile/backup_restore_screen.dart';
import 'package:mudra_manager/screens/profile/choose_language_screen.dart'
    show ChooseLanguageScreen;
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/service/notification_service.dart'
    show NotificationService;
import 'package:mudra_manager/theme/theme_provider.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.app_settings_appbar_title,
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
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
                    title: "Language",
                    subtitle: "Choose your language",
                    icon: Icons.language_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChooseLanguageScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileTile(
                    title: "Theme Mode",
                    subtitle: _getSubtitle(currentTheme),
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
                                      title: Text(_getSubtitle(mode)),
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
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).toList(),
                            ),
                      );
                    },
                  ),
                  ProfileTile(
                    title: "Low Balance Threshold",
                    subtitle:
                        "Set the low balance threshold\nCurrent threshold ${SharedPrefsUtil.instance.getLowBalanceThreshold().toStringAsFixed(0)}",
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () async {
                      final prefsService = SharedPrefsUtil.instance;
                      final currentThreshold =
                          prefsService.getLowBalanceThreshold();

                      final controller = TextEditingController(
                        text: currentThreshold.toStringAsFixed(2),
                      );

                      final newThreshold = await showDialog<double>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: Text(
                                'Set Low Balance Threshold',
                                style: textTheme.titleLarge?.copyWith(
                                  color: color.primary,
                                ),
                              ),
                              contentPadding: EdgeInsets.all(16),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Threshold (₹)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CommonButton(
                                      text: 'Cancel',
                                      onPressed: () => Navigator.pop(ctx),
                                      backGroundColor: color.secondary,
                                      textColor: color.onSecondary,
                                    ),
                                    SizedBox(width: 16),
                                    CommonButton(
                                      text: 'Save',
                                      onPressed: () {
                                        final value = double.tryParse(
                                          controller.text.trim(),
                                        );
                                        if (value != null) {
                                          Navigator.pop(ctx, value);
                                        }
                                      },
                                      backGroundColor: color.primary,
                                      textColor: color.onPrimary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                      );

                      if (newThreshold != null) {
                        prefsService.setLowBalanceThreshold(newThreshold);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Threshold updated to ₹${newThreshold.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final reminderTime = ref.watch(reminderTimeProvider);

                      return ProfileTile(
                        title: "Daily Expense Reminder",
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

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder set for ${selectedTime.format(context)}',
                                ),
                              ),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  BackupRestoreScreen(), // You’ll create this screen
                        ),
                      );
                    },
                  ),
                  ProfileTile(
                    title: "About Mudra Manager",
                    subtitle: "Version, team and legal information",
                    icon: Icons.info_outline, // You can change icon if you want
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AboutScreen(), // You’ll create this screen
                        ),
                      );
                    },
                  ),
                  // Text('Notification Settings', style: textTheme.titleLarge),
                  // const SizedBox(height: 16),
                  // SwitchListTile(
                  //   title: const Text("Daily Expense Reminder"),
                  //   subtitle: const Text("Receive reminders to log expenses daily"),
                  //   value: true, // Make this dynamic with a provider or state
                  //   onChanged: (val) {},
                  // ),
                  // SwitchListTile(
                  //   title: const Text("Backup Reminder"),
                  //   subtitle: const Text("Get reminded to backup your data"),
                  //   value: false,
                  //   onChanged: (val) {},
                  // ),
                  // const Divider(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      default:
        return "System Default";
    }
  }
}
