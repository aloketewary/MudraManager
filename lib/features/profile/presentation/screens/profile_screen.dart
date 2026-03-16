import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
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
  return await MarketplaceService()
      .isPluginEnabled('com.mudra.low_balance_alert');
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
    final spacing = ref.watch(spacingProvider);
    final iconDataList = MudraManagerAvatarIcons.iconDataList;
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync =
        ref.watch(budgetServiceProvider).getFilterBudget(DateTime.now());
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      data: (profile) => CustomScrollView(
        slivers: [
          // ── HERO HEADER ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showAboutSheet(color, textTheme),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.biggest.height <=
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
                  background: _buildHeroBackground(
                    profile,
                    iconDataList,
                    color,
                    textTheme,
                    isDark,
                  ),
                );
              },
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── QUICK STATS ──
                _buildQuickStatsRow(
                  accountsAsync,
                  categoriesAsync,
                  budgetsAsync,
                  color,
                  textTheme,
                  spacing,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── ACHIEVEMENTS ──
                _buildAchievementsCard(color, textTheme, spacing),
                const SizedBox(height: 24),

                // ── CORE SETTINGS ──
                _buildSectionHeader('Core Settings', color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color,
                  textTheme,
                  spacing,
                  items: [
                    _SettingItem(
                      Icons.account_balance_wallet_outlined,
                      'Accounts',
                      'Manage your accounts',
                      () => context.push('/manage-accounts'),
                    ),
                    _SettingItem(
                      Icons.category_outlined,
                      'Categories',
                      'Manage your categories',
                      () => context.push('/manage-categories'),
                    ),
                    _SettingItem(
                      Icons.lock,
                      'Security',
                      'PIN or Fingerprint',
                      () => context.push('/security'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── APP & DATA ──
                _buildSectionHeader('App & Data', color, textTheme),
                const SizedBox(height: 10),
                _buildAppDataGroup(
                  color,
                  textTheme,
                  spacing,
                ),
                const SizedBox(height: 24),

                // ── APPEARANCE ──
                // ── APPEARANCE ──
                _buildSectionHeader('Appearance', color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color,
                  textTheme,
                  spacing,
                  items: [
                    _SettingItem(
                      LucideIcons.palette,
                      'Appearance',
                      'Theme, language & display',
                      () => context.push('/appearance'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── ADVANCED ──
                _buildSectionHeader('Advanced', color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color,
                  textTheme,
                  spacing,
                  items: [
                    _SettingItem(
                      Icons.dashboard_customize_outlined,
                      'Dashboard Layout',
                      'Customize widgets & cards',
                      () => context.push('/dashboard-customize'),
                    ),
                    _SettingItem(
                      Icons.extension_outlined,
                      'Plugins',
                      'Manage extensions',
                      () => context.push('/marketplace'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── SUPPORT & LEGAL ──
                _buildSectionHeader('Support & Legal', color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color,
                  textTheme,
                  spacing,
                  items: [
                    _SettingItem(
                      Icons.help_outline,
                      'Help & Support',
                      'FAQs and feature guides',
                      () => context.push('/help'),
                    ),
                    _SettingItem(
                      Icons.info_outline,
                      'About App',
                      'Version & Info',
                      () => context.push('/about'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── LOGOUT ──
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        _showLogoutBottomSheet(context, ref, color, textTheme),
                    icon: Icon(Icons.logout, size: 18, color: color.error),
                    label: Text(
                      'Logout',
                      style: textTheme.bodyMedium?.copyWith(color: color.error),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      loading: () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SkeletonLoader(
            width: double.infinity,
            height: 220,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            6,
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
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ── HERO BACKGROUND ──
  Widget _buildHeroBackground(
    dynamic profile,
    List<IconData> iconDataList,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            color.primaryContainer.withValues(alpha: 0.6),
            color.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          color.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Avatar with level ring
                  _buildAvatarWithLevel(
                    profile,
                    iconDataList,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 14),
                  // Name
                  Text(
                    profile?.name ?? 'Unknown',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (profile?.email != null && profile!.email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.email!,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Streak + member since row
                  _buildHeroBadges(profile, color, textTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithLevel(
    dynamic profile,
    List<IconData> iconDataList,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final userLevelAsync = ref.watch(userLevelProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/edit-profile');
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Level ring
          userLevelAsync.maybeWhen(
            data: (level) {
              if (level == null) return const SizedBox(width: 80, height: 80);
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                tween: Tween(
                  begin: 0.0,
                  end: level.progressPercent.clamp(0.0, 1.0),
                ),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color.primary),
                    ),
                  );
                },
              );
            },
            orElse: () => const SizedBox(width: 80, height: 80),
          ),
          // Avatar
          SizedBox(
            width: 64,
            height: 64,
            child: ClipOval(
              child: BoringAvatar(
                name: profile.name,
                palette: BoringAvatarPalette([
                  color.primary,
                  color.tertiary,
                  color.primaryContainer,
                  color.tertiaryContainer,
                ]),
                type: BoringAvatarType.beam,
              ),
            ),
          ),
          // Level badge
          userLevelAsync.maybeWhen(
            data: (level) {
              if (level == null) return const SizedBox.shrink();
              return Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lv${level.level}',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadges(
    dynamic profile,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final streak = ref.watch(dailyStreakProvider);
    final memberSince = profile?.createdAt;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (streak != null && streak.currentCount > 0) ...[
          _heroBadge(
            icon: LucideIcons.flame,
            label: '${streak.currentCount} day streak',
            badgeColor: const Color(0xFFFF9800),
            color: color,
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
        ],
        if (memberSince != null)
          _heroBadge(
            icon: LucideIcons.calendar,
            label: _formatMemberSince(memberSince),
            badgeColor: color.primary,
            color: color,
            textTheme: textTheme,
          ),
      ],
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String label,
    required Color badgeColor,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemberSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 30) return '${diff.inDays}d member';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo member';
    return '${(diff.inDays / 365).floor()}y member';
  }

  // ── QUICK STATS ROW ──
  Widget _buildQuickStatsRow(
    AsyncValue accountsAsync,
    AsyncValue categoriesAsync,
    Future budgetsAsync,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final streak = ref.watch(dailyStreakProvider);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _quickStat(
                Icons.account_balance_wallet,
                accountsAsync.when(
                  data: (a) => (a as List).length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                'Accounts',
                color,
                textTheme,
              ),
            ),
            _divider(color),
            Expanded(
              child: _quickStat(
                Icons.category,
                categoriesAsync.when(
                  data: (c) => (c as List).length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                'Categories',
                color,
                textTheme,
              ),
            ),
            _divider(color),
            Expanded(
              child: FutureBuilder(
                future: budgetsAsync,
                builder: (context, snapshot) => _quickStat(
                  Icons.pie_chart,
                  snapshot.hasData
                      ? (snapshot.data as List).length.toString()
                      : '...',
                  'Budgets',
                  color,
                  textTheme,
                ),
              ),
            ),
            if (streak != null && streak.longestCount > 0) ...[
              _divider(color),
              Expanded(
                child: _quickStat(
                  LucideIcons.flame,
                  '${streak.longestCount}',
                  'Best Streak',
                  color,
                  textTheme,
                  accentColor: const Color(0xFFFF9800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickStat(
    IconData icon,
    String value,
    String label,
    ColorScheme color,
    TextTheme textTheme, {
    Color? accentColor,
  }) {
    final c = accentColor ?? color.primary;
    return Column(
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: c,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _divider(ColorScheme color) {
    return Container(width: 1, height: 36, color: color.outlineVariant);
  }

  // ── ACHIEVEMENTS ──
  Widget _buildAchievementsCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final achievementsAsync = ref.watch(achievementsProvider);
        return achievementsAsync.when(
          data: (achievements) {
            final visible = achievements.where((a) => a.isVisible).toList();
            final unlocked = visible.where((a) => a.isUnlocked).toList();
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(),
              color: color.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                side: BorderSide(
                  color: color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                onTap: () => setState(
                  () => _achievementsExpanded = !_achievementsExpanded,
                ),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: color.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Achievements',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${unlocked.length}/${visible.length}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _achievementsExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: color.onSurfaceVariant,
                          ),
                        ],
                      ),
                      if (_achievementsExpanded) ...[
                        const SizedBox(height: 16),
                        const BadgeShowcase(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => Card(
            elevation: 0,
            margin: const EdgeInsets.only(),
            color: color.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(
                color: color.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: color.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Your Achievements',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme,
  ) {
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

  // ── GROUPED SETTINGS CARD ──
  Widget _buildGroupedCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    required List<_SettingItem> items,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  item.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: color.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: textTheme.bodySmall?.copyWith(
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
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 58,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── APP & DATA GROUP (with conditional low balance) ──
  Widget _buildAppDataGroup(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final items = <_SettingItem>[
      _SettingItem(
        Icons.notifications_outlined,
        'Notifications',
        'Daily & weekly summaries',
        () => context.push('/notification-settings'),
      ),
      _SettingItem(
        Icons.sms,
        'SMS Import',
        'Auto-import transactions',
        () => context.push('/sms-import'),
      ),
      _SettingItem(
        Icons.backup,
        'Backup & Restore',
        'Manage your data',
        () => context.push('/backup-restore'),
      ),
    ];

    return Consumer(
      builder: (context, ref, _) {
        final pluginAsync = ref.watch(lowBalancePluginProvider);
        final extraItems = [...items];
        if (pluginAsync.valueOrNull == true) {
          extraItems.add(
            _SettingItem(
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
        }
        return _buildGroupedCard(color, textTheme, spacing, items: extraItems);
      },
    );
  }

  // ── BOTTOM SHEETS ──

  void _showAboutSheet(ColorScheme color, TextTheme textTheme) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.person, size: 64, color: color.primary),
            const SizedBox(height: 16),
            Text(
              'About Mudra Manager',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
  }

  void _showThemeModeSheet(ColorScheme color, TextTheme textTheme) {
    HapticFeedback.mediumImpact();
    final ctxt = AppLocalizations.of(context)!;
    final currentTheme = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            Text(
              'Select Theme Mode',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...AppThemeMode.values.map((mode) {
              final isSelected = currentTheme == mode;
              String label;
              IconData icon;
              switch (mode) {
                case AppThemeMode.light:
                  label = ctxt.app_settings_theme_mode_light;
                  icon = Icons.light_mode;
                  break;
                case AppThemeMode.dark:
                  label = ctxt.app_settings_theme_mode_dark;
                  icon = Icons.dark_mode;
                  break;
                case AppThemeMode.amoled:
                  label = ctxt.app_settings_theme_mode_amoled;
                  icon = Icons.circle;
                  break;
                case AppThemeMode.system:
                  label = ctxt.app_settings_theme_mode_system_default;
                  icon = Icons.phone_android;
                  break;
              }
              return Card(
                elevation: 0,
                color: isSelected
                    ? color.primaryContainer
                    : color.surfaceContainerHighest,
                child: ListTile(
                  title: Text(label),
                  leading: Icon(
                    icon,
                    color:
                        isSelected ? color.onPrimaryContainer : color.onSurface,
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: color.onPrimaryContainer)
                      : null,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(themeModeProvider.notifier).setTheme(mode);
                    context.pop();
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAccessibilitySheet(ColorScheme color, TextTheme textTheme) {
    HapticFeedback.mediumImpact();
    final prefs = SharedPrefsUtil.instance;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentHighContrast = prefs.getHighContrastMode();
          return Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Text(
                  'Accessibility Options',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                  fillColor:
                      color.surfaceContainerHighest.withValues(alpha: 0.3),
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
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout? All data will be cleared.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
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
                        final isar =
                            await ref.read(isarServiceProvider).getInstance();
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

// ── HELPER CLASS ──
class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingItem(this.icon, this.title, this.subtitle, this.onTap);
}
