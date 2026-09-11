import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/app_mode_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/profile/presentation/screens/profile_screen.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/quick_stat_item.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

/// Profile/settings surface based on doc/ux/design/bottom_nav_example.png.
///
/// Existing profile actions remain available below the reference-inspired
/// sections. The screen intentionally uses the app's providers and routes,
/// rather than replacing them with presentation-only controls.
class ProfileReferenceScreen extends ConsumerWidget {
  const ProfileReferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: Stack(
        children: [
          const _ProfileAmbientBackdrop(),
          SafeArea(
            child: profileAsync.when(
              data: (profile) => RefreshIndicator(
                color: color.primary,
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(accountsProvider);
                  ref.invalidate(categoryListProvider);
                  ref.invalidate(dailyStreakProvider);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      toolbarHeight:
                          spacing.touchTarget + spacing.elementGap * 3,
                      leadingWidth: spacing.cardInner + spacing.touchTarget,
                      backgroundColor: color.surface,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      scrolledUnderElevation: 0,
                      centerTitle: true,
                      titleSpacing: 0,
                      title: Text(
                        'Settings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                      ),
                      leading: Padding(
                        padding: EdgeInsets.only(left: spacing.cardInner),
                        child: _ReferenceCircleButton(
                          icon: LucideIcons.arrowLeft,
                          tooltip: 'Back',
                          onTap: () => context.pop(),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: EdgeInsets.only(right: spacing.cardInner),
                          child: PopupMenuButton<String>(
                            tooltip: 'More options',
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  HapticFeedback.mediumImpact();
                                  context.push(AppRoutes.editProfile);
                                case 'appearance':
                                  HapticFeedback.mediumImpact();
                                  context.push(AppRoutes.appearance);
                                case 'logout':
                                  HapticFeedback.mediumImpact();
                                  _showLogoutBottomSheet(context, ref);
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                spacing.radiusMedium,
                              ),
                            ),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit profile'),
                              ),
                              PopupMenuItem(
                                value: 'appearance',
                                child: Text('Appearance'),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Text('Log out'),
                              ),
                            ],
                            child: const _ReferenceCircleButton(
                              icon: LucideIcons.ellipsis,
                              tooltip: 'More options',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.elementGap,
                        spacing.cardHorizontal,
                        spacing.cardVertical +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _ReferenceProfileHeader(
                            profile: profile,
                            onEdit: () {
                              HapticFeedback.mediumImpact();
                              context.push(AppRoutes.editProfile);
                            },
                          ),
                          SizedBox(height: spacing.sectionGap),
                          _ReferenceSectionTitle(
                            title: 'Subscription',
                            color: color,
                          ),
                          SizedBox(height: spacing.elementGap),
                          const _ReferenceSubscriptionCard(),
                          SizedBox(height: spacing.sectionGap),
                          _ReferenceSectionTitle(
                            title: l10n(context).section_appearance,
                            color: color,
                          ),
                          SizedBox(height: spacing.elementGap),
                          const _AppearanceChoices(),
                          SizedBox(height: spacing.sectionGap),
                          ..._buildReferenceLinks(context, ref),
                          SizedBox(height: spacing.sectionGap),
                          const _ReferenceQuickStats(),
                          SizedBox(height: spacing.sectionGap),
                          const AmbientBrandSection(showSignature: true),
                          if (kDebugMode) ...[
                            SizedBox(height: spacing.sectionGap),
                            _ReferenceSettingRow(
                              icon: LucideIcons.bug,
                              title: 'Debug entitlement controls',
                              subtitle: 'Developer-only tools',
                              onTap: () => context.push(AppRoutes.appSettings),
                            ),
                          ],
                          SizedBox(height: spacing.sectionGap),
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  _showLogoutBottomSheet(context, ref),
                              icon: Icon(
                                LucideIcons.logOut,
                                size: 18,
                                color: color.error,
                              ),
                              label: Text(
                                l10n(context).profile_logout,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: color.error),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => ListView(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardHorizontal,
                  spacing.cardVertical,
                  spacing.cardHorizontal,
                  spacing.cardVertical + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  const _ReferenceTopBar(),
                  SizedBox(height: spacing.sectionGap),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 118,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  ...List.generate(
                    7,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.elementGap),
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 68,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                  ),
                ],
              ),
              error: (error, _) => _ReferenceErrorView(
                message: BuddyMessages.errorWith('$error'),
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReferenceLinks(BuildContext context, WidgetRef ref) {
    final ctxt = l10n(context);
    final pendingCount = ref.watch(pendingCountProvider).value ?? 0;
    final isSimple = ref.watch(isSimpleModeProvider);
    final spacing = ref.watch(spacingProvider);

    List<Widget> group({
      required String title,
      required List<Widget> rows,
    }) {
      return [
        _ReferenceSectionTitle(
          title: title,
          color: Theme.of(context).colorScheme,
        ),
        SizedBox(height: spacing.elementGap),
        _ReferenceSettingsGroup(children: rows),
        SizedBox(height: spacing.sectionGap),
      ];
    }

    _ReferenceSettingRow row({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      String? badge,
    }) {
      return _ReferenceSettingRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        badge: badge,
        grouped: true,
        onTap: onTap,
      );
    }

    return [
      ...group(
        title: 'Core Settings',
        rows: [
          row(
            icon: LucideIcons.walletCards,
            title: ctxt.profile_accounts,
            subtitle: ctxt.profile_manageAccounts,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.manageAccounts);
            },
          ),
          row(
            icon: LucideIcons.layoutGrid,
            title: ctxt.profile_categories,
            subtitle: ctxt.profile_manageCategories,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.manageCategories);
            },
          ),
          row(
            icon: LucideIcons.coins,
            title: ctxt.title_currency,
            subtitle: _baseCurrencySubtitle(ref),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.currencySettings);
            },
          ),
          row(
            icon: LucideIcons.lockKeyhole,
            title: ctxt.title_security,
            subtitle: ctxt.profile_pinFingerprint,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.security);
            },
          ),
        ],
      ),
      ...group(
        title: 'App & Data',
        rows: [
          row(
            icon: LucideIcons.database,
            title: 'Data Control Preference',
            subtitle: ctxt.profile_manageData,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.backupRestore);
            },
          ),
          row(
            icon: LucideIcons.bell,
            title: ctxt.profile_notifications,
            subtitle: ctxt.profile_dailyWeeklySummaries,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.notificationSettings);
            },
          ),
          row(
            icon: LucideIcons.smartphone,
            title: ctxt.profile_autoImport,
            subtitle: pendingCount > 0
                ? '$pendingCount pending review'
                : ctxt.profile_autoImportDesc,
            badge: pendingCount > 0 ? '$pendingCount' : null,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(
                pendingCount > 0 ? AppRoutes.smsActivity : AppRoutes.smsImport,
              );
            },
          ),
          row(
            icon: LucideIcons.trophy,
            title: ctxt.title_achievements,
            subtitle: ctxt.profile_yourAchievements,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.achievements);
            },
          ),
        ],
      ),
      ...group(
        title: 'Preferences',
        rows: [
          row(
            icon: LucideIcons.palette,
            title: 'Customize Mudra Manager',
            subtitle: ctxt.profile_themeDisplay,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.appearance);
            },
          ),
          row(
            icon: LucideIcons.languages,
            title: ctxt.profile_language,
            subtitle:
                Locale(SharedPrefsUtil.instance.getLanguage()).displayName(),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.chooseLanguage);
            },
          ),
          row(
            icon: LucideIcons.layoutDashboard,
            title: isSimple ? ctxt.mode_switchToFull : ctxt.mode_switchToSimple,
            subtitle: isSimple ? ctxt.mode_fullDesc : ctxt.mode_simpleDesc,
            onTap: () async {
              HapticFeedback.mediumImpact();
              final current = ref.read(appModeProvider);
              await ref.read(appModeProvider.notifier).setMode(
                    current == AppMode.simple ? AppMode.full : AppMode.simple,
                  );
            },
          ),
        ],
      ),
      ...group(
        title: 'Advanced',
        rows: [
          row(
            icon: LucideIcons.arrowLeftRight,
            title: ctxt.profile_importExport,
            subtitle: ctxt.profile_importExportDesc,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.importExport);
            },
          ),
          row(
            icon: LucideIcons.puzzle,
            title: ctxt.title_plugins,
            subtitle: ctxt.profile_manageExtensions,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.marketplace);
            },
          ),
        ],
      ),
      ...group(
        title: 'Support & Legal',
        rows: [
          row(
            icon: LucideIcons.circleQuestionMark,
            title: ctxt.profile_helpSupport,
            subtitle: ctxt.profile_faqs,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.help);
            },
          ),
          row(
            icon: LucideIcons.info,
            title: ctxt.profile_aboutApp,
            subtitle: ctxt.profile_versionInfo,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.about);
            },
          ),
        ],
      ),
    ];
  }

  String _baseCurrencySubtitle(WidgetRef ref) {
    final code = ref.watch(baseCurrencyProvider).value ?? 'INR';
    return '$code - ${currencyName(code)}';
  }

  Future<void> _showLogoutBottomSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.read(spacingProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sectionGap,
          spacing.elementGap,
          spacing.sectionGap,
          spacing.sectionGap,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                BuddyMessages.logoutTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                BuddyMessages.logoutMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              SizedBox(height: spacing.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(BuddyMessages.deleteCancel),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color.error,
                        foregroundColor: color.onError,
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final prefs = SharedPrefsUtil.instance;
                        final language = prefs.getLanguage();
                        final isar =
                            await ref.read(isarServiceProvider).getInstance();
                        await isar.writeTxn(() async => isar.clear());
                        await prefs.clear();
                        await prefs.setLanguage(language);
                        BaseCurrency.sync('INR');
                        if (sheetContext.mounted) {
                          sheetContext.go(AppRoutes.onboarding);
                        }
                      },
                      child: Text(BuddyMessages.deleteConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAmbientBackdrop extends StatelessWidget {
  const _ProfileAmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isDark = color.brightness == Brightness.dark;
    final glowAlpha = isDark ? 0.035 : 0.022;

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.surface,
                      Color.lerp(color.surface, color.primary, glowAlpha)!,
                      color.surface,
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -150,
              right: -110,
              child: _ambientOrb(
                color.primary,
                isDark ? 0.11 : 0.08,
                300,
              ),
            ),
            Positioned(
              bottom: -180,
              left: -140,
              child: _ambientOrb(
                color.tertiary,
                isDark ? 0.08 : 0.055,
                340,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientOrb(Color color, double alpha, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context)!;

class _ReferenceTopBar extends ConsumerWidget {
  const _ReferenceTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.cardInner,
        spacing.elementGap * 2,
        spacing.cardInner,
        spacing.elementGap,
      ),
      child: Row(
        children: [
          _ReferenceCircleButton(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Back',
            onTap: () {},
          ),
          Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit profile')),
              PopupMenuItem(value: 'appearance', child: Text('Appearance')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
            child: const _ReferenceCircleButton(
              icon: LucideIcons.ellipsis,
              tooltip: 'More options',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceProfileHeader extends ConsumerWidget {
  const _ReferenceProfileHeader({
    required this.profile,
    required this.onEdit,
  });

  final dynamic profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final name = FieldEncryptionService.safeDisplay(
      profile?.name,
      l10n(context).profile_awesomeUser,
    );
    final email = profile?.email as String?;
    final streak = ref.watch(dailyStreakProvider);

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Edit profile',
          child: GestureDetector(
            onTap: onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: spacing.touchTarget * 2 + spacing.elementGap * 2,
                  height: spacing.touchTarget * 2 + spacing.elementGap * 2,
                  padding: EdgeInsets.all(spacing.elementGap * 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.surface,
                        color.primaryContainer.withValues(alpha: 0.32),
                      ],
                    ),
                    border: Border.all(
                      color: color.onSurface.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.primary.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: color.shadow.withValues(alpha: 0.06),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: LevelRingAvatar(
                    profileName: name,
                    spacing: spacing,
                    reduceMotion: MediaQuery.of(context).disableAnimations,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: spacing.touchTargetSmall * 0.85,
                    height: spacing.touchTargetSmall * 0.85,
                    decoration: BoxDecoration(
                      color: color.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.outlineVariant),
                    ),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 17,
                      color: color.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.elementGap * 2),
        Text(
          name,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color.onSurface,
          ),
        ),
        if (email != null && email.isNotEmpty) ...[
          SizedBox(height: spacing.elementGapMin),
          Text(
            FieldEncryptionService.safeDisplay(email),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
        if (streak != null || profile?.createdAt != null) ...[
          SizedBox(height: spacing.elementGap * 1.5),
          _ReferenceHeroBadges(
            streak: streak,
            memberSince: profile?.createdAt as DateTime?,
          ),
        ],
      ],
    );
  }
}

class _ReferenceHeroBadges extends ConsumerWidget {
  const _ReferenceHeroBadges({
    required this.streak,
    required this.memberSince,
  });

  final dynamic streak;
  final DateTime? memberSince;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final badges = <Widget>[];

    if (streak != null && streak.currentCount > 0) {
      badges.add(
        _heroBadge(
          context,
          icon: LucideIcons.flame,
          label: l10n(context).profile_dayStreakLabel(streak.currentCount),
          containerColor: color.tertiaryContainer,
          onContainerColor: color.onTertiaryContainer,
          textTheme: textTheme,
          spacing: spacing,
        ),
      );
    }
    if (memberSince != null) {
      badges.add(
        _heroBadge(
          context,
          icon: LucideIcons.calendar,
          label: _formatMemberSince(memberSince!),
          containerColor: color.primaryContainer,
          onContainerColor: color.onPrimaryContainer,
          textTheme: textTheme,
          spacing: spacing,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < badges.length; index++) ...[
          if (index > 0) SizedBox(width: spacing.elementGap),
          badges[index],
        ],
      ],
    );
  }

  Widget _heroBadge(
    BuildContext context, {
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
}

class _ReferenceQuickStats extends ConsumerWidget {
  const _ReferenceQuickStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final streak = ref.watch(dailyStreakProvider);
    final ctxt = l10n(context);
    final stats = <Widget>[
      QuickStatItem(
        icon: LucideIcons.wallet,
        value: (accountsAsync.asData?.value as List?)?.length.toString() ?? '0',
        label: ctxt.profile_accountsLabel,
        loading: accountsAsync.isLoading,
      ),
      QuickStatItem(
        icon: LucideIcons.layoutGrid,
        value:
            (categoriesAsync.asData?.value as List?)?.length.toString() ?? '0',
        label: ctxt.profile_categoriesLabel,
        loading: categoriesAsync.isLoading,
      ),
      QuickStatItem(
        icon: LucideIcons.chartPie,
        value: '0',
        label: ctxt.profile_budgetsLabel,
      ),
      if (streak?.longestCount != null)
        QuickStatItem(
          icon: LucideIcons.flame,
          value: '${streak!.longestCount}',
          label: ctxt.profile_bestStreakLabel,
          accentColor: color.tertiary,
        ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.cardVerticalMax,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.surface.withValues(alpha: 0.86),
            color.primaryContainer.withValues(alpha: 0.16),
            color.surface.withValues(alpha: 0.74),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: color.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++)
            Expanded(child: stats[index]),
        ],
      ),
    );
  }
}

class _ReferenceSubscriptionCard extends ConsumerWidget {
  const _ReferenceSubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return ref.watch(proPlanInfoProvider).when(
          loading: () => const SizedBox(height: 80),
          error: (_, __) => _subscriptionContent(
            context,
            ref,
            title: 'Upgrade to Pro',
            subtitle: 'Unlock advanced features',
            icon: LucideIcons.sparkles,
          ),
          data: (info) {
            final title = info.isPro
                ? info.label
                : info.isTrial
                    ? 'Full Access'
                    : 'Upgrade to Pro';
            final subtitle = info.isPro
                ? 'Active subscription'
                : info.isTrial
                    ? 'Enjoy full access'
                    : 'Unlock advanced features';
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.upgrade);
              },
              child: Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.surface,
                      Color.lerp(
                        color.surface,
                        color.primary,
                        color.brightness == Brightness.dark ? 0.15 : 0.08,
                      )!,
                      color.surfaceContainerLow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: color.primary.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.primary.withValues(alpha: 0.045),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: color.onSurface.withValues(alpha: 0.025),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.transparent,
                      color.primary.withValues(alpha: 0.045),
                      Colors.transparent,
                    ],
                    stops: const [0.28, 0.52, 0.76],
                  ),
                ),
                child: Row(
                  children: [
                    _ReferenceIconTile(
                      icon: info.isPro ? LucideIcons.crown : LucideIcons.star,
                      color: color.primary,
                      filled: true,
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.upgrade);
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontalMax,
                        ),
                        minimumSize: Size(
                          0,
                          spacing.touchTargetSmall + spacing.elementGapMin,
                        ),
                        backgroundColor: color.inverseSurface,
                        foregroundColor: color.onInverseSurface,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(info.isPro ? 'Manage' : 'See Plan'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _subscriptionContent(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.upgrade),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                color.surface,
                color.primary,
                color.brightness == Brightness.dark ? 0.18 : 0.06,
              )!,
              color.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: color.primary.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: color.primary.withValues(alpha: 0.045),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: color.onSurface.withValues(alpha: 0.025),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.transparent,
              color.primary.withValues(alpha: 0.045),
              Colors.transparent,
            ],
            stops: const [0.28, 0.52, 0.76],
          ),
        ),
        child: Row(
          children: [
            _ReferenceIconTile(icon: icon, color: color.primary, filled: true),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.push(AppRoutes.upgrade),
              style: FilledButton.styleFrom(
                backgroundColor: color.inverseSurface,
                foregroundColor: color.onInverseSurface,
                shape: const StadiumBorder(),
              ),
              child: const Text('See Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceChoices extends ConsumerWidget {
  const _AppearanceChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final currentMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(themeNotifierProvider);
    final choices = [
      (
        label: 'System',
        icon: LucideIcons.slidersHorizontal,
        selected: currentMode == AppThemeMode.system &&
            currentTheme != AppColorTheme.dynamic,
        onTap: () =>
            ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.system),
      ),
      (
        label: 'For You',
        icon: LucideIcons.sunMoon,
        selected: currentTheme == AppColorTheme.dynamic,
        onTap: () async {
          await ref
              .read(themeNotifierProvider.notifier)
              .setTheme(AppColorTheme.dynamic);
          await ref
              .read(themeModeProvider.notifier)
              .setTheme(AppThemeMode.system);
        },
      ),
      (
        label: 'Dark',
        icon: LucideIcons.moon,
        selected: currentMode == AppThemeMode.dark ||
            currentMode == AppThemeMode.amoled,
        onTap: () =>
            ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.dark),
      ),
      (
        label: 'Light',
        icon: LucideIcons.sun,
        selected: currentMode == AppThemeMode.light,
        onTap: () =>
            ref.read(themeModeProvider.notifier).setTheme(AppThemeMode.light),
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < choices.length; index++) ...[
          Expanded(
            child: _AppearanceChoice(
              label: choices[index].label,
              icon: choices[index].icon,
              selected: choices[index].selected,
              onTap: () {
                HapticFeedback.lightImpact();
                choices[index].onTap();
              },
              color: color,
            ),
          ),
          if (index != choices.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _AppearanceChoice extends ConsumerWidget {
  const _AppearanceChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final borderColor = selected ? color.primary : color.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: spacing.touchTargetSmall * 1.6,
              height: spacing.touchTargetSmall * 1.6,
              decoration: BoxDecoration(
                color: selected
                    ? color.primaryContainer.withValues(alpha: 0.5)
                    : color.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor.withValues(alpha: selected ? 0.85 : 0.65),
                  width: selected ? spacing.strokeNormal : spacing.strokeThin,
                ),
              ),
              child: Icon(
                icon,
                size: spacing.iconLG,
                color: selected ? color.primary : color.onSurface,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceSectionTitle extends StatelessWidget {
  const _ReferenceSectionTitle({
    required this.title,
    required this.color,
  });

  final String title;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color.onSurface,
            letterSpacing: -0.1,
          ),
    );
  }
}

class _ReferenceSettingsGroup extends ConsumerWidget {
  const _ReferenceSettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            SizedBox(height: spacing.elementGap),
        ],
      ],
    );
  }
}

class _ReferenceSettingRow extends ConsumerStatefulWidget {
  const _ReferenceSettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.grouped = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;
  final bool grouped;

  @override
  ConsumerState<_ReferenceSettingRow> createState() =>
      _ReferenceSettingRowState();
}

class _ReferenceSettingRowState extends ConsumerState<_ReferenceSettingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 180),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.985,
  ).animate(
    CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ),
  );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final radius = BorderRadius.circular(
      widget.grouped ? spacing.radiusLarge : spacing.radiusMedium,
    );

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surface.withValues(alpha: 0.96),
              color.primaryContainer.withValues(
                alpha: widget.grouped ? 0.08 : 0.05,
              ),
            ],
          ),
          borderRadius: radius,
          border: Border.all(
            color: color.onSurface.withValues(alpha: 0.055),
          ),
          boxShadow: [
            BoxShadow(
              color: color.shadow.withValues(alpha: 0.07),
              blurRadius: widget.grouped ? 18 : 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: color.surface.withValues(alpha: 0.8),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardInner,
                vertical: widget.grouped
                    ? spacing.cardVerticalMax + spacing.elementGapMin
                    : spacing.cardVerticalMax,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: spacing.touchTarget,
                    height: spacing.touchTarget,
                    child: Icon(
                      widget.icon,
                      size: spacing.iconMD,
                      color: color.onSurface,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onSurface,
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.badge != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin,
                      ),
                      decoration: BoxDecoration(
                        color: color.errorContainer,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusLarge),
                      ),
                      child: Text(
                        widget.badge!,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                  ],
                  Icon(
                    LucideIcons.arrowRight,
                    size: spacing.iconMD,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceIconTile extends ConsumerWidget {
  const _ReferenceIconTile({
    required this.icon,
    required this.color,
    required this.filled,
  });

  final IconData icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return Container(
      width: spacing.touchTarget,
      height: spacing.touchTarget,
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.26),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: filled ? null : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: spacing.iconLG),
    );
  }
}

class _ReferenceCircleButton extends ConsumerWidget {
  const _ReferenceCircleButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        minimumSize: Size.square(spacing.touchTarget),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: spacing.iconLG),
    );
  }
}

class _ReferenceErrorView extends ConsumerWidget {
  const _ReferenceErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              color: color.error,
              size: spacing.iconXL,
            ),
            SizedBox(height: spacing.elementGap * 2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            SizedBox(height: spacing.elementGap * 2),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 17),
              label: Text(l10n(context).common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
