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
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

final lowBalancePluginProvider = FutureProvider.autoDispose((ref) async {
  return await MarketplaceService().isPluginEnabled('com.mudra.low_balance_alert');
});

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            expandedHeight: 200,
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
                              const SizedBox(width: 12),
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
                      : const SizedBox.shrink(),
                  background: Container(
                    decoration: BoxDecoration(color: color.primaryContainer),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
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
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.shadow.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
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
                          const SizedBox(height: 12),
                          Text(
                            profile?.name ?? 'Unknown',
                            style: textTheme.titleLarge?.copyWith(
                              color: color.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? '',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          if (profile?.phone != null &&
                              profile!.phone!.isNotEmpty) ...{
                            const SizedBox(height: 2),
                            Text(
                              profile.phone!,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onPrimaryContainer.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          },
                        ],
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
                _AnimatedCard(
                  delay: 0,
                  child: SizedBox(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.category,
                            categoriesAsync.when(
                              data: (categories) =>
                                  categories.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            'Categories',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder(
                            future: budgetsAsync,
                            builder: (context, snapshot) => _buildStatCard(
                              context,
                              Icons.pie_chart,
                              snapshot.hasData
                                  ? (snapshot.data as List).length.toString()
                                  : '...',
                              'Budgets',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _AnimatedCard(delay: 100, child: BadgeShowcase()),
                const SizedBox(height: 20),
                _AnimatedCard(
                  child: _buildSectionHeader(context, 'Management'),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  child: _buildSettingCard(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Accounts',
                    'Manage your accounts',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/manage-accounts');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  child: _buildSettingCard(
                    context,
                    Icons.category_outlined,
                    'Categories',
                    'Manage your categories',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/manage-categories');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedCard(
                  delay: 350,
                  child: _buildSectionHeader(context, 'Account & Data'),
                ),
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: MarketplaceService().isPluginEnabled('com.mudra.low_balance_alert'),
                  builder: (context, snapshot) {
                    final isPluginEnabled = snapshot.data ?? false;
                    if (!isPluginEnabled) return const SizedBox.shrink();
                    
                    return _AnimatedCard(
                      delay: 400,
                      child: _buildSettingCard(
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
                    );
                  },
                ),
                FutureBuilder<bool>(
                  future: MarketplaceService().isPluginEnabled('com.mudra.low_balance_alert'),
                  builder: (context, snapshot) {
                    final isPluginEnabled = snapshot.data ?? false;
                    return isPluginEnabled ? const SizedBox(height: 12) : const SizedBox.shrink();
                  },
                ),
                _AnimatedCard(
                  delay: 450,
                  child: _buildSettingCard(
                    context,
                    Icons.backup,
                    'Backup & Restore',
                    'Manage your data',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/backup-restore');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedCard(
                  delay: 500,
                  child: _buildSectionHeader(context, 'Preferences'),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 550,
                  child: _buildSettingCard(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    'Daily & weekly summaries',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/notification-settings');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 600,
                  child: _buildSettingCard(
                    context,
                    Icons.settings,
                    'App Settings',
                    'Customize your experience',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/app-settings');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 700,
                  child: _buildSettingCard(
                    context,
                    Icons.lock,
                    'Security',
                    'PIN or Fingerprint',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/security');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 750,
                  child: _buildSettingCard(
                    context,
                    Icons.sms,
                    'SMS Import',
                    'Auto-import transactions',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/sms-import');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedCard(
                  delay: 750,
                  child: _buildSectionHeader(context, 'About'),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 800,
                  child: _buildSettingCard(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    'FAQs and feature guides',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/help');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 850,
                  child: _buildSettingCard(
                    context,
                    Icons.info_outline,
                    'About App',
                    'Version & Info',
                    () {
                      HapticFeedback.mediumImpact();
                      context.push('/about');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedCard(
                  delay: 900,
                  child: _buildSectionHeader(context, 'Danger Zone'),
                ),
                const SizedBox(height: 12),
                _AnimatedCard(
                  delay: 950,
                  child: _buildSettingCard(
                    context,
                    Icons.logout,
                    'Logout',
                    'Clear all data',
                    () =>
                        _showLogoutBottomSheet(context, ref, color, textTheme),
                    isDestructive: true,
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
