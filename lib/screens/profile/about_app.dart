import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mudra_manager/components/made_with_love_footer.dart';

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
                expandedHeight: 240,
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
                          SizedBox(height: 40),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: color.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset('assets/logo/rupee.png', width: 64, height: 64),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Mudra Manager",
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (info != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.surface.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Version ${info.version}",
                                style: textTheme.labelLarge?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: color.primary,
                                size: 32,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Smart personal finance app that helps you track expenses, manage budgets, and organize transactions effortlessly with AI-powered SMS parsing.",
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
                      SizedBox(height: 32),
                      _buildSectionHeader(context, "Features", Icons.star_outline),
                      SizedBox(height: 16),
                      _buildFeatureGrid(context, color, textTheme),
                      SizedBox(height: 32),
                      _buildSectionHeader(context, "Development Team", Icons.group_outlined),
                      SizedBox(height: 16),
                      _buildTeamList(context, color, textTheme),
                      SizedBox(height: 32),
                      _buildSectionHeader(context, "Legal & Support", Icons.info_outline),
                      SizedBox(height: 16),
                      _buildInfoCard(context, color, textTheme, Icons.privacy_tip_outlined, "Privacy Policy", "How we protect your data", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('https://aloketewary.github.io/MudraManager/privacy-policy.html');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, Icons.description_outlined, "Terms & Conditions", "App usage terms and conditions", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('https://aloketewary.github.io/MudraManager//terms-conditions.html');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, Icons.email_outlined, "Contact Support", "aloke@duck.com", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('mailto:aloke@duck.com');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, Icons.verified_user_outlined, "Open Source Licenses", "View third-party licenses", () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LicenseScreen(appName: info?.appName, version: info?.version)));
                      }),
                      SizedBox(height: 40),
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color.onPrimaryContainer, size: 20),
        ),
        SizedBox(width: 12),
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

  Widget _buildFeatureGrid(BuildContext context, ColorScheme color, TextTheme textTheme) {
    final features = [
      (Icons.sms_outlined, "SMS Auto-Import", "Automatic transaction detection"),
      (Icons.pie_chart_outline, "Budget Tracking", "Smart spending limits"),
      (Icons.analytics_outlined, "Insights & Reports", "Detailed financial analytics"),
      (Icons.security, "Secure & Private", "Local-first data storage"),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: 0,
          color: color.surfaceContainerHighest,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(feature.$1, color: color.onPrimaryContainer, size: 20),
                ),
                SizedBox(height: 8),
                Flexible(
                  child: Text(
                    feature.$2,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: color.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2),
                Flexible(
                  child: Text(
                    feature.$3,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamList(BuildContext context, ColorScheme color, TextTheme textTheme) {
    final team = [
      ("Aloke Tewary", "Product Designer & Developer", Icons.design_services, color.primary),
      ("Sougata Chakraborty", "Backend & Quality Assurance", Icons.engineering, color.secondary),
    ];
    return Column(
      children: team.map((member) => Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: color.surfaceContainerHighest,
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
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
            padding: EdgeInsets.only(top: 4),
            child: Text(
              member.$2,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color.onPrimaryContainer, size: 24),
              ),
              SizedBox(width: 16),
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
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.onSurfaceVariant, size: 20),
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
        title: Text("Open Source Licenses"),
        backgroundColor: color.surface,
        surfaceTintColor: color.surfaceTint,
      ),
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
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
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
                  padding: EdgeInsets.all(20),
                  child: Card(
                    elevation: 0,
                    color: color.primaryContainer,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
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
                          SizedBox(height: 16),
                          Text(
                            appName ?? "Mudra Manager",
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color.onPrimaryContainer,
                            ),
                          ),
                          if (version != null) ...[ 
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Version $version",
                                style: textTheme.labelLarge?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: color.onPrimaryContainer,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "${data.count} open source packages",
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
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final license = data.licenses[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: color.surfaceContainerHighest,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            leading: Container(
                              padding: EdgeInsets.all(8),
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
                              license.packages.join(", "),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color.onSurface,
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '${license.paragraphs.length} license ${license.paragraphs.length == 1 ? 'paragraph' : 'paragraphs'}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                            children: license.paragraphs.map((para) => Container(
                              margin: EdgeInsets.only(top: 12),
                              padding: EdgeInsets.all(16),
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
                            )).toList(),
                          ),
                        ),
                      );
                    },
                    childCount: data.licenses.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
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
