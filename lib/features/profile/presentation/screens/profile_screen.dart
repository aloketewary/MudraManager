import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/theme/mudra_manager_avatar_icons.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/gamification/widgets/badge_showcase.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

final lowBalancePluginProvider = FutureProvider.autoDispose((ref) async {
  return await MarketplaceService().isPluginEnabled('com.mudra.low_balance_alert');
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _achievementsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final iconDataList = MudraManagerAvatarIcons.iconDataList;
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref
        .watch(budgetServiceProvider)
        .getFilterBudget(DateTime.now());
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return profileAsync.when(
      data: (profile) => CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            leading: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: color.onSurfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Icon(Icons.person, size: 64, color: color.primary),
                          const SizedBox(height: 16),
                          Text(
                            'About Mudra Manager',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your personal finance companion. Track expenses, manage budgets, and gain insights into your spending habits.',
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed =
                    constraints.biggest.height <=
                    kToolbarHeight + MediaQuery.of(context).padding.top + 20;
                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: isCollapsed
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            profile?.name ?? 'Unknown',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : const SizedBox.shrink(),
                  background: Container(
                    decoration: BoxDecoration(color: color.primaryContainer),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: color.primary,
                                  child: Icon(
                                    iconDataList[profile?.avatarIndex ?? 0],
                                    size: 32,
                                    color: color.onPrimary,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      context.push('/edit-profile');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: color.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    profile?.name ?? 'Unknown',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: color.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (profile?.email != null && profile!.email!.isNotEmpty)
                                    Text(
                                      profile.email!,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onPrimaryContainer.withValues(alpha: 0.8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: _buildQuickStat(context, Icons.account_balance_wallet, accountsAsync.when(data: (a) => a.length.toString(), loading: () => '...', error: (_, __) => '0'), 'Accounts')),
                        Container(width: 1, height: 40, color: color.outlineVariant),
                        Expanded(child: _buildQuickStat(context, Icons.category, categoriesAsync.when(data: (c) => c.length.toString(), loading: () => '...', error: (_, __) => '0'), 'Categories')),
                        Container(width: 1, height: 40, color: color.outlineVariant),
                        Expanded(child: FutureBuilder(future: budgetsAsync, builder: (context, snapshot) => _buildQuickStat(context, Icons.pie_chart, snapshot.hasData ? (snapshot.data as List).length.toString() : '...', 'Budgets'))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final achievementsAsync = ref.watch(achievementsProvider);
                    return achievementsAsync.when(
                      data: (achievements) {
                        final visible = achievements.where((a) => a.isVisible).toList();
                        final unlocked = visible.where((a) => a.isUnlocked).toList();
                        return Card(
                          elevation: 0,
                          color: color.surfaceContainerLow,
                          child: InkWell(
                            onTap: () => setState(() => _achievementsExpanded = !_achievementsExpanded),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.emoji_events, color: color.primary, size: 24),
                                      const SizedBox(width: 12),
                                      Text('Your Achievements', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      Text('${unlocked.length}/${visible.length}', style: textTheme.bodyMedium?.copyWith(color: color.primary, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(_achievementsExpanded ? Icons.expand_less : Icons.expand_more, color: color.onSurfaceVariant),
                                    ],
                                  ),
                                  if (_achievementsExpanded) ...[const SizedBox(height: 16), const BadgeShowcase()],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => Card(
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events, color: color.primary, size: 24),
                              const SizedBox(width: 12),
                              Text('Your Achievements', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Core Settings'),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.account_balance_wallet_outlined, 'Accounts', 'Manage your accounts', () { HapticFeedback.mediumImpact(); context.push('/manage-accounts'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.category_outlined, 'Categories', 'Manage your categories', () { HapticFeedback.mediumImpact(); context.push('/manage-categories'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.lock, 'Security', 'PIN or Fingerprint', () { HapticFeedback.mediumImpact(); context.push('/security'); }),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'App & Data'),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.notifications_outlined, 'Notifications', 'Daily & weekly summaries', () { HapticFeedback.mediumImpact(); context.push('/notification-settings'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.sms, 'SMS Import', 'Auto-import transactions', () { HapticFeedback.mediumImpact(); context.push('/sms-import'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.backup, 'Backup & Restore', 'Manage your data', () { HapticFeedback.mediumImpact(); context.push('/backup-restore'); }),
                FutureBuilder<bool>(future: MarketplaceService().isPluginEnabled('com.mudra.low_balance_alert'), builder: (context, snapshot) { if (!(snapshot.data ?? false)) return const SizedBox.shrink(); return Column(children: [const SizedBox(height: 12), _buildSettingCard(context, Icons.account_balance_wallet_outlined, 'Low Balance Threshold', '₹${SharedPrefsUtil.instance.getLowBalanceThreshold().toStringAsFixed(0)}', () => _showThresholdBottomSheet(context, ref, color, textTheme))]); }),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Appearance'),
                const SizedBox(height: 12),
                _buildThemeModeCard(context, ref, color, textTheme),
                const SizedBox(height: 12),
                _buildAccessibilityCard(context, ref, color, textTheme),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.language, 'Language', 'Change app language', () { HapticFeedback.mediumImpact(); context.push('/choose-language'); }),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Advanced'),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.dashboard_customize_outlined, 'Dashboard Layout', 'Customize widgets & cards', () { HapticFeedback.mediumImpact(); context.push('/dashboard-customize'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.extension_outlined, 'Plugins', 'Manage extensions', () { HapticFeedback.mediumImpact(); context.push('/marketplace'); }),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Support & Legal'),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.help_outline, 'Help & Support', 'FAQs and feature guides', () { HapticFeedback.mediumImpact(); context.push('/help'); }),
                const SizedBox(height: 12),
                _buildSettingCard(context, Icons.info_outline, 'About App', 'Version & Info', () { HapticFeedback.mediumImpact(); context.push('/about'); }),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showLogoutBottomSheet(context, ref, color, textTheme),
                    icon: Icon(Icons.logout, size: 18, color: color.error),
                    label: Text('Logout', style: textTheme.bodyMedium?.copyWith(color: color.error)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      loading: () => Center(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonLoader(
              width: double.infinity,
              height: 220,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 70,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value, String label) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color.primary, size: 20),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildThemeModeCard(BuildContext context, WidgetRef ref, ColorScheme color, TextTheme textTheme) {
    final currentTheme = ref.watch(themeModeProvider);
    final ctxt = AppLocalizations.of(context)!;
    String modeText;
    switch (currentTheme) {
      case AppThemeMode.light: modeText = ctxt.app_settings_theme_mode_light; break;
      case AppThemeMode.dark: modeText = ctxt.app_settings_theme_mode_dark; break;
      case AppThemeMode.amoled: modeText = ctxt.app_settings_theme_mode_amoled; break;
      case AppThemeMode.system: modeText = ctxt.app_settings_theme_mode_system_default; break;
    }
    return _buildSettingCard(context, Icons.brightness_6_outlined, 'Theme Mode', modeText, () {
      HapticFeedback.mediumImpact();
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: color.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Select Theme Mode', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...AppThemeMode.values.map((mode) {
                final isSelected = currentTheme == mode;
                String label;
                IconData icon;
                switch (mode) {
                  case AppThemeMode.light: label = ctxt.app_settings_theme_mode_light; icon = Icons.light_mode; break;
                  case AppThemeMode.dark: label = ctxt.app_settings_theme_mode_dark; icon = Icons.dark_mode; break;
                  case AppThemeMode.amoled: label = ctxt.app_settings_theme_mode_amoled; icon = Icons.circle; break;
                  case AppThemeMode.system: label = ctxt.app_settings_theme_mode_system_default; icon = Icons.phone_android; break;
                }
                return Card(
                  elevation: 0,
                  color: isSelected ? color.primaryContainer : color.surfaceContainerHighest,
                  child: ListTile(
                    title: Text(label),
                    leading: Icon(icon, color: isSelected ? color.onPrimaryContainer : color.onSurface),
                    trailing: isSelected ? Icon(Icons.check, color: color.onPrimaryContainer) : null,
                    onTap: () { HapticFeedback.mediumImpact(); ref.read(themeModeProvider.notifier).setTheme(mode); context.pop(); },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAccessibilityCard(BuildContext context, WidgetRef ref, ColorScheme color, TextTheme textTheme) {
    final prefs = SharedPrefsUtil.instance;
    final isHighContrast = prefs.getHighContrastMode();
    return _buildSettingCard(context, Icons.accessibility_new, 'Accessibility', isHighContrast ? 'High Contrast Enabled' : 'Standard', () {
      HapticFeedback.mediumImpact();
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => StatefulBuilder(
          builder: (context, setModalState) {
            final currentHighContrast = prefs.getHighContrastMode();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: color.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Accessibility Options', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHighest,
                    child: SwitchListTile(
                      title: const Text('High Contrast Mode'),
                      subtitle: const Text('Improves readability for low vision'),
                      value: currentHighContrast,
                      onChanged: (val) {
                        HapticFeedback.mediumImpact();
                        prefs.setHighContrastMode(val);
                        ref.read(highContrastModeProvider.notifier).set(val);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      surfaceTintColor: color.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.onPrimaryContainer, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? color.error : color.primary;

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      surfaceTintColor: color.surfaceTint,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
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
                Icons.chevron_right,
                color: color.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThresholdBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ColorScheme color,
    TextTheme textTheme,
  ) async {
    final prefsService = SharedPrefsUtil.instance;
    final currentThreshold = prefsService.getLowBalanceThreshold();
    final controller = TextEditingController(
      text: currentThreshold.toStringAsFixed(2),
    );

    final newThreshold = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
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
                keyboardType: const TextInputType.numberWithOptions(
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
                  fillColor: color.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text.trim());
                        if (value != null) context.pop(value);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
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

    if (newThreshold != null && context.mounted) {
      prefsService.setLowBalanceThreshold(newThreshold);
      SnackbarService.success(
        'Threshold updated to ₹${newThreshold.toStringAsFixed(2)}',
      );
    }
  }

  void _showLogoutBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.logout, size: 48, color: Colors.redAccent),
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
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final prefs = SharedPrefsUtil.instance;
                        final lang = prefs.getLanguage();
                        final isar = await ref
                            .read(isarServiceProvider)
                            .getInstance();
                        await isar.writeTxn(() async => await isar.clear());
                        prefs.clear();
                        prefs.setLanguage(lang);
                        ref.invalidate(userProfileProvider);
                        ref.invalidate(accountsProvider);
                        ref.invalidate(categoryListProvider);
                        ref.invalidate(budgetServiceProvider);
                        if (ctx.mounted) ctx.go('/onboarding');
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
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
  }
}
