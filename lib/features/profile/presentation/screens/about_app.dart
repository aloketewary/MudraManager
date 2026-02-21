import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/shared/widgets/made_with_love_footer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              SliverAppBar.large(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.primary,
                          color.primary.withValues(alpha: 0.85),
                          color.secondary,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.surface.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo/rupee.png',
                              width: 64,
                              height: 64,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mudra Manager',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (info != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.surface.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Version ${info.version}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: color.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Smart personal finance app that helps you track expenses, manage budgets, and organize transactions effortlessly with AI-powered SMS parsing.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: color.onSurface,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        'Features',
                        Icons.star_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureGrid(context, color, textTheme),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        'Development Team',
                        Icons.group_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTeamList(context, color, textTheme),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        'Special Thanks',
                        Icons.favorite_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildThanksSection(context, color, textTheme),
                      const SizedBox(height: 16),
                      _buildPatronSection(context, color, textTheme),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        'Legal & Support',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        color,
                        textTheme,
                        Icons.privacy_tip_outlined,
                        'Privacy Policy',
                        'How we protect your data',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL(
                            'https://aloketewary.github.io/MudraManager/privacy-policy.html',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        color,
                        textTheme,
                        Icons.description_outlined,
                        'Terms & Conditions',
                        'App usage terms and conditions',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL(
                            'https://aloketewary.github.io/MudraManager//terms-conditions.html',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        color,
                        textTheme,
                        Icons.email_outlined,
                        'Contact Support',
                        'aloke@duck.com',
                        () {
                          HapticFeedback.mediumImpact();
                          _launchURL('mailto:aloke@duck.com');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        color,
                        textTheme,
                        Icons.verified_user_outlined,
                        'Open Source Licenses',
                        'View third-party licenses',
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildFeatureGrid(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final features = [
      (
        Icons.dashboard_outlined,
        'Smart Dashboard',
        'Real-time financial overview with insights',
      ),
      (
        Icons.sms_outlined,
        'SMS Auto-Import',
        'Automatic transaction detection from bank SMS',
      ),
      (
        Icons.pie_chart_outline,
        'Budget Tracking',
        'Set limits and track spending by category',
      ),
      (
        Icons.analytics_outlined,
        'Insights & Reports',
        'Detailed analytics with charts and trends',
      ),
      (
        Icons.repeat,
        'Recurring Transactions',
        'Automate regular income and expenses',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Multi-Account',
        'Manage multiple accounts in one place',
      ),
      (
        Icons.backup_outlined,
        'Backup & Restore',
        'Export and import your financial data',
      ),
      (
        Icons.security,
        'Secure & Private',
        'Local-first storage with biometric lock',
      ),
      (
        Icons.dark_mode_outlined,
        'Beautiful Themes',
        'Dynamic colors and dark mode support',
      ),
      (
        Icons.language,
        'Multi-Language',
        'Support for multiple languages',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: 0,
          color: color.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature.$1,
                    color: color.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature.$2,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: color.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  feature.$3,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamList(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final team = [
      (
        'Aloke Tewary',
        'Product Designer & Developer',
        Icons.design_services,
        color.primary,
      ),
      (
        'Sougata Chakraborty',
        'Backend & Quality Assurance',
        Icons.engineering,
        color.secondary,
      ),
    ];
    return Column(
      children: team
          .map(
            (member) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: color.surfaceContainerHighest,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: member.$4.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(member.$3, color: member.$4, size: 24),
                ),
                title: Text(
                  member.$1,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    member.$2,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildThanksSection(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism, color: color.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Beta Testers & Contributors',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A heartfelt thank you to everyone who helped test and improve Mudra Manager:',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTesterChip(context, 'Sayan Dey', color),
                _buildTesterChip(context, 'Abhijit A M', color),
                _buildTesterChip(context, 'Dhanesh C', color),
                _buildTesterChip(context, 'Jeet Sarkar', color),
                _buildTesterChip(context, 'Souvik Paul', color),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your feedback made this app better!',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTesterChip(
    BuildContext context,
    String name,
    ColorScheme color,
  ) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.primary.withValues(alpha: 0.2),
        child: Icon(Icons.person, size: 16, color: color.primary),
      ),
      label: Text(name),
      backgroundColor: color.surfaceContainerLow,
      side: BorderSide.none,
    );
  }

  Widget _buildPatronSection(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      color: color.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: color.tertiary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Patrons & Supporters',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Special thanks to our generous patrons who support the development of Mudra Manager:',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onTertiaryContainer,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPatronChip(context, 'Amrita Sarkar', color),
                _buildPatronChip(context, 'Arnab Saha', color),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: color.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Want to support? Contact us!',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onTertiaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatronChip(
    BuildContext context,
    String name,
    ColorScheme color,
  ) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.tertiary.withValues(alpha: 0.2),
        child: Icon(Icons.star, size: 16, color: color.tertiary),
      ),
      label: Text(name),
      backgroundColor: color.surface,
      side: BorderSide.none,
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
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
