import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart'
    show MudraManagerAvatarIcons;
import 'package:mudra_manager/util/snackbar_service.dart';

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
                onTap: () => context.push('/edit-profile'),
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

                  final newThreshold = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom,
                          left: 24,
                          right: 24,
                          top: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: color.onSurfaceVariant.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: color.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Set Low Balance Threshold',
                              style: textTheme.titleLarge?.copyWith(
                                color: color.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get notified when account balance falls below this amount',
                              style: textTheme.bodyMedium?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: controller,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'Threshold Amount',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: color.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      final value = double.tryParse(
                                        controller.text.trim(),
                                      );
                                      if (value != null) {
                                        context.pop(value);
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  );

                  if (newThreshold != null) {
                    prefsService.setLowBalanceThreshold(newThreshold);
                    SnackbarService.success(
                      'Threshold updated to ₹${newThreshold.toStringAsFixed(2)}',
                    );
                  }
                },
              ),

              ProfileTile(
                title: "App Settings",
                subtitle: "Update app related settings",
                icon: Icons.settings,
                onTap: () => context.push('/app-settings'),
              ),

              ProfileTile(
                title: "Security",
                subtitle: "Protect your app with PIN or Fingerprint",
                icon: Icons.lock,
                onTap: () => context.push('/security'),
              ),
              ProfileTile(
                title: "SMS Import",
                subtitle: "Auto-import transactions from your SMS messages",
                icon: Icons.sms,
                onTap: () => context.push('/sms-import'),
              ),
              ProfileTile(
                title: "Logout",
                subtitle: "Clear Everything and Logout",
                icon: Icons.logout,
                isLogout: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: color.onSurfaceVariant.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Icon(
                              Icons.logout,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Logout',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Are you sure you want to logout? All data will be cleared.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () async {
                                      final isar =
                                          await ref
                                              .read(isarServiceProvider)
                                              .getInstance();
                                      await isar.writeTxn(() async {
                                        await isar.clear();
                                      });
                                      SharedPrefsUtil.instance.clear();
                                      context.go('/onboarding');
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Logout'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
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
