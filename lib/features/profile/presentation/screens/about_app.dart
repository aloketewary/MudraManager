import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/shared/widgets/made_with_love_footer.dart';
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

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      SnackbarService.error(ctxt.about_couldNotOpenLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.about_title)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── HERO CARD ──
              _buildHeroCard(info, color, textTheme, spacing, isDark),
              const SizedBox(height: 24),

              // ── DATA ETHICS ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
              ),
              const SizedBox(height: 24),

              // ── LEGAL & TRANSPARENCY ──
              _buildSectionHeader(
                AppLocalizations.of(context)!.about_legalTransparency,
                ctxt.about_legalCount,
                color,
                textTheme,
              ),
              const SizedBox(height: 10),
              _buildGroupedCard(
                color,
                textTheme,
                spacing,
                [
                  _ItemData(
                    LucideIcons.fileText,
                    AppLocalizations.of(context)!.about_privacyPolicy,
                    AppLocalizations.of(context)!.about_privacyPolicyDesc,
                    () {
                      HapticFeedback.mediumImpact();
                      _launchURL('https://mudramanager.com/privacy.html');
                    },
                  ),
                  _ItemData(
                    LucideIcons.fileCheck,
                    AppLocalizations.of(context)!.about_termsOfService,
                    AppLocalizations.of(context)!.about_termsDesc,
                    () {
                      HapticFeedback.mediumImpact();
                      _launchURL('https://mudramanager.com/terms.html');
                    },
                  ),
                  _ItemData(
                    LucideIcons.package,
                    AppLocalizations.of(context)!.about_openSourceLicenses,
                    AppLocalizations.of(context)!.about_openSourceDesc,
                    () {
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── SUPPORT & CONNECT ──
              _buildSectionHeader(
                AppLocalizations.of(context)!.about_supportConnect,
                ctxt.about_supportCount,
                color,
                textTheme,
              ),
              const SizedBox(height: 10),
              _buildGroupedCard(
                color,
                textTheme,
                spacing,
                [
                  _ItemData(
                    LucideIcons.refreshCw,
                    AppLocalizations.of(context)!.about_checkForUpdates,
                    AppLocalizations.of(context)!.about_checkForUpdatesDesc,
                    () async {
                      HapticFeedback.mediumImpact();
                      try {
                        final updateInfo = await InAppUpdate.checkForUpdate();
                        if (!context.mounted) return;

                        if (updateInfo.updateAvailability ==
                            UpdateAvailability.updateAvailable) {
                          if (updateInfo.flexibleUpdateAllowed) {
                            await InAppUpdate.startFlexibleUpdate();
                            await InAppUpdate.completeFlexibleUpdate();
                          } else if (updateInfo.immediateUpdateAllowed) {
                            await InAppUpdate.performImmediateUpdate();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ctxt.about_latestVersion,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        SnackbarService.error(ctxt.about_unableToCheck);
                      }
                    },
                  ),
                  _ItemData(
                    LucideIcons.globe,
                    AppLocalizations.of(context)!.about_officialWebsite,
                    AppLocalizations.of(context)!.about_visitWebsite,
                    () {
                      HapticFeedback.mediumImpact();
                      _launchURL('https://mudramanager.com');
                    },
                  ),
                  _ItemData(
                    LucideIcons.mail,
                    AppLocalizations.of(context)!.about_contactSupport,
                    AppLocalizations.of(context)!.about_contactSupportDesc,
                    () {
                      HapticFeedback.mediumImpact();
                      _launchURL('https://mudramanager.com/support.html');
                    },
                  ),
                  _ItemData(
                    LucideIcons.star,
                    AppLocalizations.of(context)!.about_rateApp,
                    AppLocalizations.of(context)!.about_rateAppDesc,
                    _requestReview,
                  ),
                ],
              ),

              // ── DEVELOPER MODE ──
              if (_devModeEnabled) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(
                    ctxt.about_developerModeSection, '', color, textTheme),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: color.errorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.terminal,
                          color: color.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Build: ${info?.buildNumber ?? 'N/A'}\nPackage: ${info?.packageName ?? 'N/A'}',
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: color.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              MadeWithLoveFooter(appName: info?.appName),
            ],
          );
        },
      ),
    );
  }

  // ── HERO CARD ──
  Widget _buildHeroCard(
    PackageInfo? info,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final accent = color.primary;
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
          // Animated icon with glow ring
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 56,
                  height: 56,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.about_mudraManager,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.about_secureFinancial,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Version badge (tappable easter egg)
          GestureDetector(
            onTap: _onVersionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shield, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'v${info?.version ?? '1.0.0'} (Stable)',
                    style: textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_devModeEnabled) ...[
                    const SizedBox(width: 6),
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

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── GROUPED CARD ──
  Widget _buildGroupedCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    List<_ItemData> items,
  ) {
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
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
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
                        child: Icon(item.icon, color: color.primary, size: 20),
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
                        LucideIcons.chevronRight,
                        color: color.onSurfaceVariant,
                        size: 18,
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
}

// ── ITEM DATA ──
class _ItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ItemData(this.icon, this.title, this.subtitle, this.onTap);
}

// ── LICENSE SCREEN ──
class LicenseScreen extends StatelessWidget {
  final String? appName;
  final String? version;

  const LicenseScreen({super.key, this.appName, this.version});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          title: Text(ctxt.about_openSourceLicenses),),
      body: FutureBuilder<LicenseData>(
        future: LicenseRegistry.licenses.fold<LicenseData>(
          LicenseData(0, []),
          (prev, license) =>
              LicenseData(prev.count + 1, [...prev.licenses, license]),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    ctxt.about_loadingLicenses,
                    style: textTheme.bodyLarge?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
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
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.primary.withValues(alpha: 0.12),
                          color.primary.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: color.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.shieldCheck,
                            color: color.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appName ?? ctxt.about_mudraManager,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (version != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.package,
                              color: color.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
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
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.fileText,
                                color: color.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              license.packages.join(', '),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${license.paragraphs.length} license ${license.paragraphs.length == 1 ? 'paragraph' : 'paragraphs'}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                            children: license.paragraphs
                                .map(
                                  (para) => Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: color.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      para.text,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurface,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
