import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart'
    show MudraManagerAvatarIcons;
import 'package:mudra_manager/util/snackbar_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var iconDataList = MudraManagerAvatarIcons.iconDataList;
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref
        .watch(budgetServiceProvider)
        .getFilterBudget(DateTime.now());
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;

    return profileAsync.when(
      data:
          (profile) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: SizedBox.shrink(),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCollapsed =
                        constraints.biggest.height <=
                        kToolbarHeight +
                            MediaQuery.of(context).padding.top +
                            20;
                    return FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                      title:
                          isCollapsed
                              ? Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: color.primaryContainer,
                                        child: Icon(
                                          iconDataList[profile?.avatarIndex ?? 0],
                                          size: 16,
                                          color: color.onPrimaryContainer,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          profile?.name ?? 'Unknown',
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: color.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox.shrink(),
                      background: Container(
                        decoration: BoxDecoration(
                          color: color.primaryContainer,
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color.surface,
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: color.primary,
                                      child: Icon(
                                        iconDataList[profile?.avatarIndex ?? 0],
                                        size: 40,
                                        color: color.onPrimary,
                                      ),
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
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: color.surface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.shadow.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: color.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                profile?.name ?? 'Unknown',
                                style: textTheme.titleLarge?.copyWith(
                                  color: color.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                profile?.email ?? '',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              if (profile?.phone != null &&
                                  profile!.phone!.isNotEmpty) ...[
                                SizedBox(height: 2),
                                Text(
                                  profile.phone!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onPrimaryContainer.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(
                      height: 150,
                      child: Row(
                      children: [
                          Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.account_balance_wallet,
                            accountsAsync.when(
                              data: (accounts) => accounts.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            'Accounts',
                          ),
                        ),
                          SizedBox(width: 12),
                          Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.category,
                            categoriesAsync.when(
                              data:
                                  (categories) =>
                                      categories.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            'Categories',
                          ),
                        ),
                          SizedBox(width: 12),
                          Expanded(
                          child: FutureBuilder(
                            future: budgetsAsync,
                            builder:
                                (context, snapshot) => _buildStatCard(
                                  context,
                                  Icons.pie_chart,
                                  snapshot.hasData
                                      ? (snapshot.data as List).length
                                          .toString()
                                      : '...',
                                  'Budgets',
                                ),
                          ),
                        ),
                      ],
                    ),
                    ),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Management'),
                    SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      Icons.receipt_long_outlined,
                      'Bills',
                      'Manage recurring bills',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/bills');
                      },
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Accounts',
                      'Manage your accounts',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/manage-accounts');
                      },
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.category_outlined,
                      'Categories',
                      'Manage your categories',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/manage-categories');
                      },
                    ),
                    SizedBox(height: 32),
                    _buildSectionHeader(context, 'Account & Data'),
                    SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Low Balance Threshold',
                      '₹${SharedPrefsUtil.instance.getLowBalanceThreshold().toStringAsFixed(0)}',
                      () => _showThresholdBottomSheet(
                        context,
                        ref,
                        color,
                        textTheme,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.backup,
                      'Backup & Restore',
                      'Manage your data',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/backup-restore');
                      },
                    ),
                    SizedBox(height: 32),
                    _buildSectionHeader(context, 'Preferences'),
                    SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      'Daily & weekly summaries',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/notification-settings');
                      },
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.settings,
                      'App Settings',
                      'Customize your experience',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/app-settings');
                      },
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.lock,
                      'Security',
                      'PIN or Fingerprint',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/security');
                      },
                    ),
                    SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      Icons.sms,
                      'SMS Import',
                      'Auto-import transactions',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/sms-import');
                      },
                    ),
                    SizedBox(height: 32),
                    _buildSectionHeader(context, 'About'),
                    SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      Icons.info_outline,
                      'About App',
                      'Version & Info',
                      () {
                        HapticFeedback.mediumImpact();
                        context.push('/about');
                      },
                    ),
                    SizedBox(height: 32),
                    _buildSectionHeader(context, 'Danger Zone'),
                    SizedBox(height: 16),
                    _buildSettingCard(
                      context,
                      Icons.logout,
                      'Logout',
                      'Clear all data',
                      () => _showLogoutBottomSheet(
                        context,
                        ref,
                        color,
                        textTheme,
                      ),
                      isDestructive: true,
                    ),
                    SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
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
        padding: const EdgeInsets.all(12),
        child: Column(
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
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
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
      padding: EdgeInsets.only(left: 4),
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
      color: color.surfaceContainer,
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
      shape: RoundedRectangleBorder(
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
              SizedBox(height: 24),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: color.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Set Low Balance Threshold',
                style: textTheme.titleLarge?.copyWith(
                  color: color.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Get notified when account balance falls below this amount',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text.trim());
                        if (value != null) context.pop(value);
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(24),
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
              SizedBox(height: 24),
              Icon(Icons.logout, size: 48, color: Colors.redAccent),
              SizedBox(height: 16),
              Text(
                'Logout',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to logout? All data will be cleared.',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final isar =
                            await ref.read(isarServiceProvider).getInstance();
                        await isar.writeTxn(() async => await isar.clear());
                        SharedPrefsUtil.instance.clear();
                        if (ctx.mounted) ctx.go('/onboarding');
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
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
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
