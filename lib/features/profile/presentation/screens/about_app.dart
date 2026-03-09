import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/made_with_love_footer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _versionTapCount = 0;
  bool _devModeEnabled = false;
  final InAppReview _inAppReview = InAppReview.instance;

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
                Icon(LucideIcons.code, color: Theme.of(context).colorScheme.onInverseSurface),
                const SizedBox(width: 12),
                const Text('Developer Mode Activated! 🚀'),
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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return CustomScrollView(
            slivers: [
              // Hero Brand Identity
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.primary.withValues(alpha: 0.15),
                        color.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                      child: Column(
                        children: [
                          // App Icon with glassmorphism
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: color.surface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.primary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.primary.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo/rupee.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // App Name
                          Text(
                            'Mudra Manager',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          Text(
                            'Secure Financial Command',
                            style: textTheme.titleMedium?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Version Badge (tappable for easter egg)
                          GestureDetector(
                            onTap: _onVersionTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: color.primaryContainer,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: color.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.shield,
                                    size: 16,
                                    color: color.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Version ${info?.version ?? '1.0.0'} (Stable Build)',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: color.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_devModeEnabled) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      LucideIcons.code,
                                      size: 16,
                                      color: color.onPrimaryContainer,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Data Ethics Statement
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.shieldCheck,
                                color: color.onSecondaryContainer,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Your data is encrypted locally. We never sell your financial information.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Legal & Transparency Block
                      _buildSectionHeader(context, 'Legal & Transparency', LucideIcons.scale),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.fileText,
                        'Privacy Policy',
                        'How we protect your data',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL('https://mudramanager.com/privacy.html');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.fileCheck,
                        'Terms of Service',
                        'App usage terms and conditions',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL('https://mudramanager.com/terms.html');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.package,
                        'Open Source Licenses',
                        'Third-party libraries we use',
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
                      const SizedBox(height: 32),
                      
                      // Support & Social Block
                      _buildSectionHeader(context, 'Support & Connect', LucideIcons.headphones),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.refreshCw,
                        'Check for Updates',
                        'Manually check app version',
                        () {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You\'re on the latest version ${info?.version ?? '1.0.0'}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.globe,
                        'Official Website',
                        'Visit mudramanager.com',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL('https://mudramanager.com');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.mail,
                        'Contact Support',
                        'Get help or report issues',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL('https://mudramanager.com/support.html');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        context,
                        color,
                        textTheme,
                        LucideIcons.star,
                        'Rate the App',
                        'Share your experience on the store',
                        _requestReview,
                      ),
                      
                      if (_devModeEnabled) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'Developer Mode', LucideIcons.code),
                        const SizedBox(height: 16),
                        Card.filled(
                          color: color.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.terminal, color: color.onErrorContainer, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Debug Info',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: color.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Build: ${info?.buildNumber ?? 'N/A'}\nPackage: ${info?.packageName ?? 'N/A'}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: color.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                      MadeWithLoveFooter(appName: info?.appName),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: color.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card.outlined(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class LicenseScreen extends StatelessWidget {
  final String? appName;
  final String? version;

  const LicenseScreen({super.key, this.appName, this.version});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
        backgroundColor: color.surface,
        surfaceTintColor: color.surfaceTint,
      ),
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
                    'Loading licenses...',
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
                  child: Card(
                    elevation: 0,
                    color: color.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user,
                              color: color.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appName ?? 'Mudra Manager',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color.onPrimaryContainer,
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
                                color: color.surface.withValues(alpha: 0.9),
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
                                Icons.inventory_2_outlined,
                                color: color.onPrimaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${data.count} open source packages',
                                style: textTheme.titleMedium?.copyWith(
                                  color: color.onPrimaryContainer,
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
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final license = data.licenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            20,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: color.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            license.packages.join(', '),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
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
                                    color: color.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
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
                  }, childCount: data.licenses.length),
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
