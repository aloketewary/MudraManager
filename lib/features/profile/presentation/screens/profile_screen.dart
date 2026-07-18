import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/app_mode_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/quick_stat_item.dart';
import 'package:mudra_manager/shared/widgets/subscription_status_card.dart';

/// Level ring avatar with motion-aware animation and gradient level badge.
class LevelRingAvatar extends ConsumerWidget {
  const LevelRingAvatar({
    super.key,
    required this.profileName,
    required this.spacing,
    required this.reduceMotion,
  });

  final String profileName;
  final AppSpacing spacing;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userLevelAsync = ref.watch(userLevelProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        userLevelAsync.maybeWhen(
          data: (level) {
            if (level == null) return const SizedBox(width: 80, height: 80);
            final progress = level.progressPercent.clamp(0.0, 1.0);
            if (reduceMotion) {
              return SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color.primary),
                ),
              );
            }
            return TweenAnimationBuilder<double>(
              duration: spacing.animHero,
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: progress),
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
              name: profileName,
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
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGapMin + 2,
                  vertical: spacing.elementGapUltraMin,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.primary,
                      color.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
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
}

/// Error view with retry action for profile loading failures.
class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({
    super.key,
    required this.message,
    required this.spacing,
    required this.onRetry,
  });

  final String message;
  final AppSpacing spacing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardHorizontalMax),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: spacing.iconXL,
              color: color.error,
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final streakAsync = ref.watch(dailyStreakProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final List<QuickStatItem> stats = [
      QuickStatItem(
        icon: LucideIcons.wallet,
        value: (accountsAsync.asData?.value as List?)?.length.toString() ?? '0',
        label: l10n.profile_accountsLabel,
        loading: accountsAsync.isLoading,
      ),
      QuickStatItem(
        icon: LucideIcons.layoutGrid,
        value: (categoriesAsync.asData?.value as List?)?.length.toString() ?? '0',
        label: l10n.profile_categoriesLabel,
        loading: categoriesAsync.isLoading,
      ),
      QuickStatItem(
        icon: LucideIcons.chartPie,
        value: '0',
        label: l10n.profile_budgetsLabel,
      ),
      if (streakAsync?.longestCount != null)
        QuickStatItem(
          icon: LucideIcons.flame,
          value: '${streakAsync!.longestCount}',
          label: l10n.profile_bestStreakLabel,
          accentColor: color.tertiary,
        ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(categoryListProvider);
        ref.invalidate(dailyStreakProvider);
      },
      child: profileAsync.when(
        data: (profile) => AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : spacing.animNormal,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          key: ValueKey(profileAsync.isLoading),
          child: CustomScrollView(
          slivers: [
            // ── HERO HEADER ──
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final isCollapsed = constraints.biggest.height <=
                      kToolbarHeight + MediaQuery.of(context).padding.top + 20;
                  return FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: EdgeInsets.only(
                      left: isCollapsed ? spacing.elementGap : spacing.cardHorizontalMax,
                      bottom: spacing.elementGap * 2,
                    ),
                    title: isCollapsed
                        ? Padding(
                            padding: EdgeInsets.only(left: spacing.elementGap),
                            child: Text(
                              FieldEncryptionService.safeDisplay(
                                profile?.name,
                                l10n.profile_awesomeUser,
                              ),
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
                      color,
                      textTheme,
                      isDark,
                      spacing,
                      streakAsync,
                      reduceMotion,
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
                  // Per-stat tonal chip containers instead of single box + dividers
                  Row(
                    children: stats.asMap().entries.expand((entry) {
                      final stat = entry.value;
                      final isLast = entry.key == stats.length - 1;
                      return [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.cardHorizontalMax,
                              vertical: spacing.cardVertical,
                            ),
                            decoration: BoxDecoration(
                              // Glassy translucent surface matching SettingsGroupCard
                              color: color.surface.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
                              border: Border.all(
                                color: color.outlineVariant.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.onSurface.withValues(alpha: 0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: stat,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast) SizedBox(width: spacing.elementGap),
                      ];
                    }).toList(),
                  ),
                  SizedBox(height: spacing.elementGap * 2),

                  // ── SUBSCRIPTION STATUS ──
                  const SubscriptionStatusCard(),
                  SizedBox(height: spacing.elementGap * 2),
                  // ── CORE SETTINGS ──
                  SectionHeader(l10n.section_coreSettings),
                  SettingsGroupCard(
                    items: [
                      SettingItem(
                        icon: LucideIcons.wallet,
                        title: l10n.profile_accounts,
                        subtitle: l10n.profile_manageAccounts,
                        onTap: () => context.push(AppRoutes.manageAccounts),
                      ),
                      SettingItem(
                        icon: LucideIcons.layoutGrid,
                        title: l10n.profile_categories,
                        subtitle: l10n.profile_manageCategories,
                        onTap: () => context.push(AppRoutes.manageCategories),
                      ),
                      SettingItem(
                        icon: LucideIcons.coins,
                        title: l10n.title_currency,
                        subtitle: _baseCurrencySubtitle(ref),
                        onTap: () => context.push(AppRoutes.currencySettings),
                      ),
                      SettingItem(
                        icon: LucideIcons.lock,
                        title: l10n.title_security,
                        subtitle: l10n.profile_pinFingerprint,
                        onTap: () => context.push(AppRoutes.security),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap * 2),

                  // ── APP & DATA ──
                  SectionHeader(l10n.section_appData),
                  _buildAppDataGroup(color, textTheme, spacing),
                  SizedBox(height: spacing.elementGap * 2),

                  // ── APPEARANCE ──
                  SectionHeader(l10n.section_appearance),
                  SettingsGroupCard(
                    items: [
                      SettingItem(
                        icon: LucideIcons.palette,
                        title: l10n.title_appearance,
                        subtitle: l10n.profile_themeDisplay,
                        onTap: () => context.push(AppRoutes.appearance),
                      ),
                      SettingItem(
                        icon: LucideIcons.languages,
                        title: l10n.profile_language,
                        subtitle: Locale(SharedPrefsUtil.instance.getLanguage()).displayName(),
                        onTap: () => context.push(AppRoutes.chooseLanguage),
                      ),
                      SettingItem(
                        icon: LucideIcons.layoutGrid,
                        title: ref.watch(isSimpleModeProvider)
                            ? l10n.mode_switchToFull
                            : l10n.mode_switchToSimple,
                        subtitle: ref.watch(isSimpleModeProvider)
                            ? l10n.mode_fullDesc
                            : l10n.mode_simpleDesc,
                        onTap: () async {
                          final notifier = ref.read(appModeProvider.notifier);
                          final current = ref.read(appModeProvider);
                          await notifier.setMode(
                            current == AppMode.simple
                                ? AppMode.full
                                : AppMode.simple,
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.elementGap * 2),

                  // ── ADVANCED ──
                  if (!ref.watch(isSimpleModeProvider)) ...[
                    SectionHeader(l10n.section_advanced),
                    SettingsGroupCard(
                      items: [
                        SettingItem(
                          icon: LucideIcons.layoutDashboard,
                          title: l10n.title_dashboardLayout,
                          subtitle: l10n.profile_customizeWidgets,
                          onTap: () => context.push(AppRoutes.dashboardCustomize),
                          trailing: const ProBadge(),
                        ),
                        SettingItem(
                          icon: LucideIcons.arrowLeftRight,
                          title: l10n.profile_importExport,
                          subtitle: l10n.profile_importExportDesc,
                          onTap: () => context.push(AppRoutes.importExport),
                        ),
                        SettingItem(
                          icon: LucideIcons.puzzle,
                          title: l10n.title_plugins,
                          subtitle: l10n.profile_manageExtensions,
                          onTap: () => context.push(AppRoutes.marketplace),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGap * 2),
                  ],

                  // ── SUPPORT & LEGAL ──
                  SectionHeader(l10n.section_supportLegal),
                  SettingsGroupCard(
                    items: [
                      SettingItem(
                        icon: LucideIcons.circleQuestionMark,
                        title: l10n.profile_helpSupport,
                        subtitle: l10n.profile_faqs,
                        onTap: () => context.push(AppRoutes.help),
                      ),
                      SettingItem(
                        icon: LucideIcons.info,
                        title: l10n.profile_aboutApp,
                        subtitle: l10n.profile_versionInfo,
                        onTap: () => context.push(AppRoutes.about),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.sectionGap * 1.33),
                  if (kDebugMode) ...[
                    const SectionHeader('Debug'),
                    _buildDebugEntitlementCard(color, textTheme, spacing),
                    SizedBox(height: spacing.elementGap * 2),
                  ],
                  // ── LOGOUT ──
                  Center(
                    child: Semantics(
                      label: l10n.profile_logout,
                      button: true,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showLogoutBottomSheet(context, ref, color, textTheme),
                        icon: Icon(LucideIcons.logOut, size: 18, color: color.error),
                        label: Text(
                          l10n.profile_logout,
                          style: textTheme.bodyMedium?.copyWith(color: color.error),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontalMax,
                            vertical: spacing.elementGap * 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sectionGap * 1.33),

                  // ── APP FOOTER ──
                  const AmbientBrandSection(showSignature: true),
                ]),
              ),
            ),
          ],
          ),
        ),
        loading: () => ListView(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
          children: [
            SkeletonLoader(
              width: double.infinity,
              height: 220,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            SizedBox(height: spacing.elementGap * 2),
            ...List.generate(
              6,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 70,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        error: (e, _) => ProfileErrorView(
          message: BuddyMessages.errorWith('$e'),
          spacing: spacing,
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
    );
  }

  /// Debug-only entitlement toggles
  Widget _buildDebugEntitlementCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final isProAsync = ref.watch(isProProvider);
        final isPro = isProAsync.value ?? false;

        return SettingsGroupCard(
          items: [
            SettingItem(
              icon: isPro ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
              title: isPro
                  ? l10n.profile_proActiveLabel
                  : l10n.profile_freeTierLabel,
              subtitle: 'Current entitlement state',
              onTap: () {},
            ),
            SettingItem(
              icon: LucideIcons.crown,
              title: 'Grant Pro (yearly)',
              subtitle: 'Debug: grant yearly plan',
              onTap: isPro
                  ? () {}
                  : () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(entitlementServiceProvider).grantPro(
                            source: 'debug',
                            productId: EntitlementProducts.yearlyPlan,
                            purchaseToken:
                                'dbg_${DateTime.now().millisecondsSinceEpoch}',
                          );
                      invalidateEntitlements(ref);
                      SnackbarService.success('Pro granted (debug)', spacing);
                    },
            ),
            SettingItem(
              icon: LucideIcons.timer,
              title: 'Grant Pro (1 min expiry)',
              subtitle: 'Debug: grant with short expiry',
              onTap: isPro
                  ? () {}
                  : () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(entitlementServiceProvider).grantPro(
                            source: 'debug',
                            productId:
                                '${EntitlementProducts.subscription}_${EntitlementProducts.monthlyPlan}',
                            purchaseToken:
                                'dbg_${DateTime.now().millisecondsSinceEpoch}',
                            expiresAt:
                                DateTime.now().add(const Duration(minutes: 1)),
                          );
                      ref.invalidate(isProProvider);
                      ref.invalidate(proPlanInfoProvider);
                      SnackbarService.success(
                          'Pro granted, expires in 1 min', spacing,);
                    },
            ),
            SettingItem(
              icon: LucideIcons.ban,
              title: 'Revoke Pro',
              subtitle: 'Debug: revoke entitlement',
              onTap: !isPro
                  ? () {}
                  : () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(entitlementServiceProvider).revokePro();
                      ref.invalidate(isProProvider);
                      ref.invalidate(proPlanInfoProvider);
                      SnackbarService.success('Pro revoked', spacing);
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroBadges(
    dynamic profile,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    dynamic streakAsync,
    bool reduceMotion,
  ) {
    final memberSince = profile?.createdAt;

    return AnimatedOpacity(
      opacity: (streakAsync != null || memberSince != null) ? 1.0 : 0.0,
      duration: spacing.animFast,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (streakAsync != null && streakAsync.currentCount > 0) ...[
            SizedBox(width: spacing.elementGap),
            _heroBadge(
              icon: LucideIcons.flame,
              label: l10n.profile_dayStreakLabel(streakAsync.currentCount),
              containerColor: color.tertiaryContainer,
              onContainerColor: color.onTertiaryContainer,
              textTheme: textTheme,
              spacing: spacing,
            ),
          ],
          if (memberSince != null) ...[
            SizedBox(width: spacing.elementGap),
            _heroBadge(
              icon: LucideIcons.calendar,
              label: _formatMemberSince(memberSince),
              containerColor: color.primaryContainer,
              onContainerColor: color.onPrimaryContainer,
              textTheme: textTheme,
              spacing: spacing,
            ),
          ],
        ],
      ),
    );
  }

  // ── HERO BACKGROUND ──
  Widget _buildHeroBackground(
    dynamic profile,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
    AppSpacing spacing,
    dynamic streakAsync,
    bool reduceMotion,
  ) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.5),
            radius: 1.2,
            colors: [
              color.primary.withValues(alpha: isDark ? 0.25 : 0.2),
              color.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              color.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow behind avatar - draws focus to identity
            Positioned(
              top: spacing.sectionGap * 2.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: spacing.elementGap * 2.5),
                    // Avatar with level ring + glassmorphism ring
                    LevelRingAvatar(
                      profileName: FieldEncryptionService.safeDisplay(
                          profile?.name, l10n.profile_awesomeUser,),
                      spacing: spacing,
                      reduceMotion: reduceMotion,
                    ),
                    SizedBox(height: spacing.elementGap * 2.25),
                    // Glass surface behind identity block (name/edit + email)
                    Container(
                      decoration: BoxDecoration(
                        color: color.surface.withValues(
                          alpha: isDark ? 0.1 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.outlineVariant.withValues(
                            alpha: isDark ? 0.2 : 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: l10n.common_edit,
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.push(AppRoutes.editProfile);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.cardHorizontalMax,
                                  vertical: spacing.elementGap,
                                ),
                                decoration: BoxDecoration(
                                  color: color.primaryContainer.withValues(alpha: isDark ? 0.1 : 0.06),
                                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FieldEncryptionService.safeDisplay(
                                          profile?.name, l10n.profile_unknown,),
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: spacing.elementGap),
                                    Container(
                                      padding: EdgeInsets.all(spacing.elementGapMin + 2),
                                      decoration: BoxDecoration(
                                        color: color.onSurfaceVariant.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                                      ),
                                      child: Icon(
                                        LucideIcons.pencil,
                                        size: spacing.iconXS,
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (profile?.email != null && profile!.email!.isNotEmpty) ...[
                            SizedBox(height: spacing.elementGap * 1.25),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.elementGap * 1.5,
                                vertical: spacing.elementGapMin + 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.onSurfaceVariant.withValues(alpha: spacing.opacitySubtle),
                                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                              ),
                              child: Text(
                                FieldEncryptionService.safeDisplay(profile.email),
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.elementGap * 2),
                    // Streak + member since row
                    _buildHeroBadges(profile, color, textTheme, spacing, streakAsync, reduceMotion),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Uses Material 3 tonal container pairs (container/onContainer) so
  /// text-on-badge contrast is guaranteed by the color scheme, not by
  /// eyeballing an alpha value on top of an arbitrary accent color.
  Widget _heroBadge({
    required IconData icon,
    required String label,
    required Color containerColor,
    required Color onContainerColor,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap * 1.5,
        vertical: spacing.elementGapMin + 2,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: containerColor.withValues(alpha: spacing.opacityMedium),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: spacing.iconXS, color: onContainerColor),
          SizedBox(width: spacing.elementGapMin + 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: onContainerColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
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

  // ── APP & DATA GROUP (with conditional pending-review badge) ──
  Widget _buildAppDataGroup(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final pendingCount = ref.watch(pendingCountProvider).value ?? 0;

        return SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.bell,
              title: l10n.profile_notifications,
              subtitle: l10n.profile_dailyWeeklySummaries,
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
            SettingItem(
              icon: LucideIcons.bellRing,
              title: l10n.profile_autoImport,
              subtitle: pendingCount > 0
                  ? '$pendingCount pending review'
                  : l10n.profile_autoImportDesc,
              onTap: () => context.push(
                pendingCount > 0 ? AppRoutes.smsActivity : AppRoutes.smsImport,
              ),
              trailing: pendingCount > 0
                  ? Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.error,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          color: color.onError,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : null,
            ),
            SettingItem(
              icon: LucideIcons.cloudUpload,
              title: l10n.profile_backupRestore,
              subtitle: l10n.profile_manageData,
              onTap: () => context.push(AppRoutes.backupRestore),
              trailing: const ProBadge(),
            ),
            SettingItem(
              icon: LucideIcons.trophy,
              title: l10n.title_achievements,
              subtitle: l10n.profile_yourAchievements,
              onTap: () => context.push(AppRoutes.achievements),
            ),
          ],
        );
      },
    );
  }

  // ── BOTTOM SHEETS ──

  void _showLogoutBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final spacing = ref.read(spacingProvider);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(spacing.sectionGap),
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
              SizedBox(height: spacing.sectionGap),
              // Tonal error icon container
              Container(
                padding: EdgeInsets.all(spacing.elementGap * 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.error.withValues(alpha: 0.12),
                      color.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
                ),
                child: Icon(LucideIcons.logOut, size: spacing.iconLG, color: color.error),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                BuddyMessages.logoutTitle,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                BuddyMessages.logoutMessage,
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: spacing.elementGap),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                        ),
                      ),
                      child: Text(BuddyMessages.deleteCancel),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final prefs = SharedPrefsUtil.instance;
                        final lang = prefs.getLanguage();
                        final isar =
                            await ref.read(isarServiceProvider).getInstance();
                        await isar.writeTxn(() async => await isar.clear());
                        await prefs.clear();
                        await prefs.setLanguage(lang);
                        BaseCurrency.sync('INR');
                        ref.invalidate(baseCurrencyProvider);
                        ref.invalidate(currencyServiceProvider);
                        ref.invalidate(userProfileProvider);
                        ref.invalidate(accountsProvider);
                        ref.invalidate(categoryListProvider);
                        ref.invalidate(budgetServiceProvider);
                        if (ctx.mounted) ctx.go(AppRoutes.onboarding);
                      },
                      style: FilledButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: spacing.elementGap),
                        backgroundColor: color.error,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                        ),
                      ),
                      child: Text(BuddyMessages.logoutConfirm),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGapMin),
            ],
          ),
        );
      },
    );
  }

  String _baseCurrencySubtitle(WidgetRef ref) {
    final async = ref.watch(baseCurrencyProvider);
    final code = async.value ?? 'INR';
    return '$code — ${currencyName(code)}';
  }
}
