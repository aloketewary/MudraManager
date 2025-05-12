import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/onboarding/onboarding_screen.dart'
    show OnboardingScreen;
import 'package:mudra_manager/screens/profile/app_settings_page.dart' show AppSettingsPage;
import 'package:mudra_manager/screens/profile/edit_user_profile_screen.dart'
    show EditUserProfileScreen;
import 'package:mudra_manager/screens/profile/manage_account_screen.dart'
    show ManageAccountScreen;
import 'package:mudra_manager/screens/profile/manage_categories_screen.dart'
    show ManageCategoriesScreen;
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/screens/profile/setting_screen.dart';
import 'package:mudra_manager/screens/profile/sms_import_setting_screen.dart';
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart'
    show MudraManagerAvatarIcons;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var iconDataList = MudraManagerAvatarIcons.iconDataList;
    final profileAsync = ref.watch(userProfileProvider);

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
                    profile?.email ?? 'unkown@email.com',
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
                title: "User Profile",
                subtitle: "Change profile image, name, and email",
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
                title: "Accounts",
                subtitle: "Manage your accounts",
                icon: Icons.account_balance_wallet,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageAccountScreen(),
                    ),
                  );
                },
              ),
              ProfileTile(
                title: "Category",
                subtitle: "Manage your categories",
                icon: Icons.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageCategoriesScreen(),
                    ),
                  );
                },
              ),
              ProfileTile(
                title: "App Settings",
                subtitle: "Update app related settings",
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppSettingsPage(),
                    ),
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
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TextButton.icon(
            onPressed: () async {
              //Clear all data from Isar
              final isar = await ref.read(isarServiceProvider).getInstance();

              // 1. Clear database
              await isar.writeTxn(() async {
                await isar.clear();
              });

              // 2. Clear shared preferences
              SharedPrefsUtil.instance.clear();

              // 3. Navigate to onboarding (and clear backstack)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => OnboardingScreen()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

}
