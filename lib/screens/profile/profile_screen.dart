import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/onboarding/onboarding_screen.dart'
    show OnboardingScreen;
import 'package:mudra_manager/screens/profile/app_settings_page.dart'
    show AppSettingsPage;
import 'package:mudra_manager/screens/profile/edit_user_profile_screen.dart'
    show EditUserProfileScreen;
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/screens/profile/setting_screen.dart';
import 'package:mudra_manager/screens/profile/sms_import_setting_screen.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart'
    show CommonButton;
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart'
    show MudraManagerAvatarIcons;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var iconDataList = MudraManagerAvatarIcons.iconDataList;
    final profileAsync = ref.watch(userProfileProvider);
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 20),

        // Avatar + Name + Email
        Center(
          child: profileAsync.when(
            data: (profile) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: Icon(
                      iconDataList[profile?.avatarIndex ?? 0],
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    profile?.email ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          ),
        ),

        const SizedBox(height: 24),

        // Section Tiles
        Expanded(
          child: ListView(
            children: [
              ProfileTile(
                title: ctxt.profile_userProfileTitleText,
                subtitle: ctxt.profile_userProfileSubtitleText,
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditUserProfileScreen(),
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
              ProfileTile(
                title: "App Settings",
                subtitle: "Update app related settings",
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppSettingsPage()),
                  );
                },
              ),

              ProfileTile(
                title: "Security",
                subtitle: "Protect your app with PIN or Fingerprint",
                icon: Icons.lock,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SecuritySettingsScreen()),
                  );
                },
              ),
              ProfileTile(
                title: "SMS Import",
                subtitle: "Auto-import transactions from your SMS messages",
                icon: Icons.sms, // You can change icon if you want
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              SmsImportSettingsScreen(), // You’ll create this screen
                    ),
                  );
                },
              ),
              ProfileTile(
                title: "Logout",
                subtitle: "Clear Everything and Logout",
                icon: Icons.logout,
                isLogout: true,
                onTap: () {
                  showAdaptiveDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          'Logout',
                          style: textTheme.titleLarge?.copyWith(
                            color: color.primary,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: textTheme.bodyLarge?.copyWith(
                            color: color.secondary,
                          ),
                        ),
                        actions: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CommonButton(
                                text: 'Cancel',
                                onPressed: () => Navigator.pop(context),
                                backGroundColor: color.secondary,
                                textColor: color.onSecondary,
                              ),
                              SizedBox(width: 16),
                              CommonButton(
                                text: 'Logout',
                                onPressed: () async {
                                  //Clear all data from Isar
                                  final isar =
                                      await ref
                                          .read(isarServiceProvider)
                                          .getInstance();

                                  // 1. Clear database
                                  await isar.writeTxn(() async {
                                    await isar.clear();
                                  });

                                  // 2. Clear shared preferences
                                  SharedPrefsUtil.instance.clear();

                                  // 3. Navigate to onboarding (and clear backstack)
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => OnboardingScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                backGroundColor: Colors.redAccent,
                                textColor: color.onSecondary,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
