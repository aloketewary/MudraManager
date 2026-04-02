import 'package:flutter/foundation.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/mudra_manager_avatar_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
                            profile?.name ?? 'Awesome User',
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
                // ── SUBSCRIPTION STATUS ──
                _buildSubscriptionCard(color, textTheme, spacing, isDark),
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
                      () => context.push(AppRoutes.manageAccounts),
                    ),
                    _SettingItem(
                      Icons.category_outlined,
                      'Categories',
                      'Manage your categories',
                      () => context.push(AppRoutes.manageCategories),
                    ),
                    _SettingItem(
                      Icons.lock,
                      'Security',
                      'PIN or Fingerprint',
                      () => context.push(AppRoutes.security),
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
                      'Theme, tone & display',
                      () => context.push(AppRoutes.appearance),
                    ),
                    _SettingItem(
                      LucideIcons.languages,
                      'Language',
                      Locale(SharedPrefsUtil.instance.getLanguage()).displayName(),
                      () => context.push(AppRoutes.chooseLanguage),
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
                      LucideIcons.layoutDashboard,
                      'Dashboard Layout',
                      'Customize widgets & cards',
                      () => context.push(AppRoutes.dashboardCustomize),
                      trailing: const ProBadge(),
                    ),
                    _SettingItem(
                      LucideIcons.arrowLeftRight,
                      'Import & Export',
                      'Excel import & export',
                      () => context.push(AppRoutes.importExport),
                    ),
                    _SettingItem(
                      LucideIcons.puzzle,
                      'Plugins',
                      'Manage extensions',
                      () => context.push(AppRoutes.marketplace),
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
                      () => context.push(AppRoutes.help),
                    ),
                    _SettingItem(
                      Icons.info_outline,
                      'About App',
                      'Version & Info',
                      () => context.push(AppRoutes.about),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                if (kDebugMode) ...[
                  _buildSectionHeader('🛠 Debug', color, textTheme),
                  const SizedBox(height: 10),
                  _buildDebugEntitlementCard(color, textTheme, spacing),
                  const SizedBox(height: 24),
                ],
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  kBottomNavigationBarHeight +
                  16,
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
      error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
    );
  }

  Widget _buildDebugEntitlementCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final isProAsync = ref.watch(isProProvider);
        final isPro = isProAsync.valueOrNull ?? false;

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Status row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isPro ? color.primary : color.error)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPro ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
                        color: isPro ? color.primary : color.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isPro ? 'Pro Active' : 'Free Tier',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                indent: 58,
                color: color.outlineVariant.withValues(alpha: 0.4),
              ),
              // Grant Pro
              InkWell(
                onTap: isPro
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(entitlementServiceProvider).grantPro(
                              source: 'debug',
                              productId: EntitlementProducts.yearlyPlan,
                              purchaseToken:
                                  'dbg_${DateTime.now().millisecondsSinceEpoch}',
                            );
                        invalidateEntitlements(ref);
                        SnackbarService.success('✅ Pro granted (debug)');
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.crown,
                          color: color.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Grant Pro (yearly)',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isPro ? color.onSurfaceVariant : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 58,
                color: color.outlineVariant.withValues(alpha: 0.4),
              ),
              // Grant Pro with 1-min expiry
              InkWell(
                onTap: isPro
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(entitlementServiceProvider).grantPro(
                              source: 'debug',
                              productId:
                                  '${EntitlementProducts.subscription}_${EntitlementProducts.monthlyPlan}',
                              purchaseToken:
                                  'dbg_${DateTime.now().millisecondsSinceEpoch}',
                              expiresAt: DateTime.now()
                                  .add(const Duration(minutes: 1)),
                            );
                        ref.invalidate(isProProvider);
                        ref.invalidate(proPlanInfoProvider);
                        SnackbarService.success(
                          '✅ Pro granted — expires in 1 min',
                        );
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              color.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.timer,
                          color: color.tertiary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Grant Pro (1 min expiry)',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isPro ? color.onSurfaceVariant : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 58,
                color: color.outlineVariant.withValues(alpha: 0.4),
              ),
              // Revoke Pro
              InkWell(
                onTap: !isPro
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(entitlementServiceProvider).revokePro();
                        ref.invalidate(isProProvider);
                        ref.invalidate(proPlanInfoProvider);
                        SnackbarService.success('🔒 Pro revoked');
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(LucideIcons.ban, color: color.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Revoke Pro',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: !isPro ? color.onSurfaceVariant : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBadges(
    dynamic profile,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final streak = ref.watch(dailyStreakProvider);
    final memberSince = profile?.createdAt;
    ref.watch(proPlanInfoProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (streak != null && streak.currentCount > 0) ...[
          const SizedBox(width: 8),
          _heroBadge(
            icon: LucideIcons.flame,
            label: '${streak.currentCount} day streak',
            badgeColor: color.tertiary,
            color: color,
            textTheme: textTheme,
          ),
        ],
        if (memberSince != null) ...[
          const SizedBox(width: 8),
          _heroBadge(
            icon: LucideIcons.calendar,
            label: _formatMemberSince(memberSince),
            badgeColor: color.primary,
            color: color,
            textTheme: textTheme,
          ),
        ],
      ],
    );
  }

  Widget _buildSubscriptionCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final planAsync = ref.watch(proPlanInfoProvider);

        return planAsync.when(
          data: (info) {
            final accent = info.isPro
                ? color.tertiary
                : info.isTrial
                    ? color.primary
                    : color.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.upgrade);
                },
                child: Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: isDark ? 0.2 : 0.12),
                        accent.withValues(alpha: isDark ? 0.08 : 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          info.isPro
                              ? LucideIcons.crown
                              : info.isTrial
                                  ? LucideIcons.gift
                                  : LucideIcons.sparkles,
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  info.isPro
                                      ? info.label
                                      : info.isTrial
                                          ? 'Full Access'
                                          : 'Upgrade to Pro',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (info.isTrial) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${info.trialDaysRemaining}d LEFT',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                                if (info.isPro) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subscriptionSubtitle(info),
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: accent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  String _subscriptionSubtitle(ProPlanInfo info) {
    if (info.isTrial) {
      final days = info.trialDaysRemaining ?? 0;
      if (days > 30) return 'Full access — enjoy all features!';
      if (days > 7) return 'Full access — $days days remaining';
      if (days > 0) return 'Full access ends in $days days';
      return 'Trial ended — upgrade to keep all features';
    }
    if (!info.isPro) return 'Unlimited accounts, analytics & more';

    if (info.expiresAt != null) {
      final days = info.expiresAt!.difference(DateTime.now()).inDays;
      if (days < 0) return 'Expired — tap to renew';
      if (days == 0) return 'Expires today';
      if (days == 1) return 'Renews tomorrow';
      return 'Renews in $days days';
    }
    return 'Active subscription';
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
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.editProfile);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile?.name ?? 'Unknown',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.pencil,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                      ],
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

    return Stack(
      alignment: Alignment.center,
      children: [
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
        SizedBox(
          width: 64,
          height: 64,
          child: ClipOval(
            child: BoringAvatar(
              name: profile?.name ?? 'Awesome User',
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
                accentColor: color.tertiary,
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
                onTap: () => context.push(AppRoutes.achievements),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                        Icons.chevron_right,
                        color: color.onSurfaceVariant,
                        size: 20,
                      ),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (item.trailing != null) item.trailing!,
                              ],
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
        () => context.push(AppRoutes.notificationSettings),
      ),
      _SettingItem(
        LucideIcons.bellRing,
        'Auto Import',
        'Auto-import from bank notifications',
        () => context.push(AppRoutes.smsImport),
      ),
      _SettingItem(
        Icons.backup,
        'Backup & Restore',
        'Manage your data',
        () => context.push(AppRoutes.backupRestore),
        trailing: const ProBadge(),
      ),
      _SettingItem(
        LucideIcons.fileText,
        'Monthly Recap',
        'View & download monthly report',
        () => context.push(AppRoutes.monthlyRecap),
        trailing: const ProBadge(),
      ),
    ];

    return Consumer(
      builder: (context, ref, _) {
        final extraItems = [...items];

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
              Icon(Icons.logout, size: 48, color: color.error),
              const SizedBox(height: 16),
              Text(
                BuddyMessages.logoutTitle,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                BuddyMessages.logoutMessage,
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
                      child: Text(BuddyMessages.deleteCancel),
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
                        if (ctx.mounted) ctx.go(AppRoutes.onboarding);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: color.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(BuddyMessages.logoutConfirm),
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
  final Widget? trailing;

  _SettingItem(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    this.trailing,
  });
}
