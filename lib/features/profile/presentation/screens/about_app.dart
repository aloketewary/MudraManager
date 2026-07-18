import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_theme.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/made_with_love_footer.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _versionTapCount = 0;
  bool _devModeEnabled = false;
  final InAppReview _inAppReview = InAppReview.instance;
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  void _onVersionTap() {
    setState(() {
      _versionTapCount++;
      if (_versionTapCount >= 5 && !_devModeEnabled) {
        _devModeEnabled = true;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  LucideIcons.code,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 12),
                Text(ctxt.about_developerMode),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _requestReview() async {
    HapticFeedback.mediumImpact();
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      await _inAppReview.openStoreListing();
    }
  }

  void _launchURL(String url, AppSpacing spacing) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      SnackbarService.error(ctxt.about_couldNotOpenLink, spacing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final spacing = ref.watch(spacingProvider);
    final prefsAsync = ref.watch(hasFullAccessProvider);

    return Scaffold(
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _AboutContent(
                  reduceMotion: reduceMotion,
                  onVersionTap: _onVersionTap,
                  devModeEnabled: _devModeEnabled,
                  requestReview: _requestReview,
                  launchURL: _launchURL,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AboutContent extends ConsumerWidget {
  final bool reduceMotion;
  final VoidCallback onVersionTap;
  final bool devModeEnabled;
  final VoidCallback requestReview;
  final void Function(String, AppSpacing) launchURL;

  const _AboutContent({
    required this.reduceMotion,
    required this.onVersionTap,
    required this.devModeEnabled,
    required this.requestReview,
    required this.launchURL,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: [
            _HeroCard(
              reduceMotion: reduceMotion,
              isDark: isDark,
              info: info,
              onVersionTap: onVersionTap,
              devModeEnabled: devModeEnabled,
            ),
            SizedBox(height: spacing.sectionGap),
            _PrivacyInfoCard(color: color, textTheme: textTheme, spacing: spacing, ctxt: ctxt),
            SizedBox(height: spacing.sectionGap),
            SectionHeader(ctxt.about_legalTransparency, subtitle: ctxt.about_legalCount),
            SizedBox(height: spacing.elementGap),
            SettingsGroupCard(
              items: [
                SettingItem(
                  icon: LucideIcons.fileText,
                  title: ctxt.about_privacyPolicy,
                  subtitle: ctxt.about_privacyPolicyDesc,
                  onTap: () => launchURL('https://mudramanager.com/privacy.html', spacing),
                  selected: false,
                ),
                SettingItem(
                  icon: LucideIcons.fileCheck,
                  title: ctxt.about_termsOfService,
                  subtitle: ctxt.about_termsDesc,
                  onTap: () => launchURL('https://mudramanager.com/terms.html', spacing),
                  selected: false,
                ),
                SettingItem(
                  icon: LucideIcons.package,
                  title: ctxt.about_openSourceLicenses,
                  subtitle: ctxt.about_openSourceDesc,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LicenseScreen(
                          appName: info?.appName,
                          version: info?.version,
                        ),
                      ),
                    );
                  },
                  selected: false,
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            SectionHeader(ctxt.about_supportConnect, subtitle: ctxt.about_supportCount),
            SizedBox(height: spacing.elementGap),
            SettingsGroupCard(
              items: [
                SettingItem(
                  icon: LucideIcons.refreshCw,
                  title: ctxt.about_checkForUpdates,
                  subtitle: ctxt.about_checkForUpdatesDesc,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      final updateInfo = await InAppUpdate.checkForUpdate();
                      if (!context.mounted) return;

                      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
                        if (updateInfo.flexibleUpdateAllowed) {
                          await InAppUpdate.startFlexibleUpdate();
                          await InAppUpdate.completeFlexibleUpdate();
                        } else if (updateInfo.immediateUpdateAllowed) {
                          await InAppUpdate.performImmediateUpdate();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ctxt.about_latestVersion),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      SnackbarService.error(ctxt.about_unableToCheck, spacing);
                    }
                  },
                  selected: false,
                ),
                SettingItem(
                  icon: LucideIcons.globe,
                  title: ctxt.about_officialWebsite,
                  subtitle: ctxt.about_visitWebsite,
                  onTap: () => launchURL('https://mudramanager.com', spacing),
                  selected: false,
                ),
                SettingItem(
                  icon: LucideIcons.mail,
                  title: ctxt.about_contactSupport,
                  subtitle: ctxt.about_contactSupportDesc,
                  onTap: () => launchURL('https://mudramanager.com/support.html', spacing),
                  selected: false,
                ),
                SettingItem(
                  icon: LucideIcons.star,
                  title: ctxt.about_rateApp,
                  subtitle: ctxt.about_rateAppDesc,
                  onTap: requestReview,
                  selected: false,
                ),
              ],
            ),
            if (devModeEnabled) ...[
              SizedBox(height: spacing.sectionGap),
              SectionHeader(ctxt.about_developerModeSection, subtitle: ''),
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: color.errorContainer,
                  border: Border.all(color: color.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.terminal, color: color.onErrorContainer, size: 20),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        'Build: ${info?.buildNumber ?? 'N/A'}\nPackage: ${info?.packageName ?? 'N/A'}',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.monoFontFamily,
                          color: color.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: spacing.sectionGap),
            const AmbientBrandSection(showSignature: false, absorbBottomInset: false),
            SizedBox(height: spacing.elementGap),
            MadeWithLoveFooter(appName: info?.appName),
          ],
        );
      },
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final PackageInfo? info;
  final VoidCallback onVersionTap;
  final bool devModeEnabled;

  const _HeroCard({
    required this.reduceMotion,
    required this.isDark,
    required this.info,
    required this.onVersionTap,
    required this.devModeEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 800);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner + 8),
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
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: duration,
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.2), width: 2),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/logo/logo.png', width: 56, height: 56),
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          Text(
            ctxt.about_mudraManager,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.about_secureFinancial,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          GestureDetector(
            onTap: onVersionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shield, size: 14, color: accent),
                  SizedBox(width: spacing.elementGapMin),
                  Text(
                    'v${info?.version ?? '1.0.0'} (Stable)',
                    style: textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (devModeEnabled) ...[
                    SizedBox(width: spacing.elementGapMin),
                    Icon(LucideIcons.code, size: 14, color: accent),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyInfoCard extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _PrivacyInfoCard({
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.shieldCheck, color: Color(0xFF4CAF50), size: 20),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: Text(
              ctxt.about_privacyDesc,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseScreen extends ConsumerWidget {
  final String? appName;
  final String? version;

  const LicenseScreen({super.key, this.appName, this.version});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.about_openSourceLicenses)),
      body: FutureBuilder<LicenseData>(
        future: LicenseRegistry.licenses.fold<LicenseData>(
          LicenseData(0, []),
          (prev, license) => LicenseData(prev.count + 1, [...prev.licenses, license]),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: spacing.sectionGap),
                  Text(
                    ctxt.about_loadingLicenses,
                    style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.primary.withValues(alpha: 0.12),
                          color.primary.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(color: color.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.shieldCheck, color: color.primary, size: 28),
                        ),
                        SizedBox(height: spacing.sectionGap),
                        Text(
                          appName ?? ctxt.about_mudraManager,
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (version != null) ...[
                          SizedBox(height: spacing.elementGap),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(spacing.radiusSmall),
                            ),
                            child: Text(
                              'Version $version',
                              style: textTheme.labelLarge?.copyWith(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: spacing.sectionGap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.package, color: color.primary, size: 18),
                            SizedBox(width: spacing.elementGap),
                            Text(
                              ctxt.about_packageCount(data.count),
                              style: textTheme.titleSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final license = data.licenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(spacing.radiusSmall),
                          side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(LucideIcons.fileText, color: color.primary, size: 18),
                            ),
                            title: Text(
                              license.packages.join(', '),
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${license.paragraphs.length} license ${license.paragraphs.length == 1 ? 'paragraph' : 'paragraphs'}',
                                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                              ),
                            ),
                            children: license.paragraphs.map((para) {
                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  para.text,
                                  style: textTheme.bodySmall?.copyWith(color: color.onSurface, height: 1.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    childCount: data.licenses.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}

class LicenseData {
  final int count;
  final List<LicenseEntry> licenses;
  LicenseData(this.count, this.licenses);
}