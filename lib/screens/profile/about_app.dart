import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';


class LicenseScreen extends StatelessWidget {
  final String? appName;
  final String? version;
  
  const LicenseScreen({super.key, this.appName, this.version});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text("Licenses")),
      body: FutureBuilder<LicenseData>(
        future: LicenseRegistry.licenses.fold<LicenseData>(
          LicenseData(0, []),
          (prev, license) => LicenseData(prev.count + 1, [...prev.licenses, license]),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.glassGradient(color.primary, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: AppColors.glassShadow(color.primary, isDark),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Icon(Icons.verified_user, color: color.primary, size: 48),
                    ),
                    SizedBox(height: 16),
                    Text(appName ?? "Mudra Manager", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                    if (version != null) ...[
                      SizedBox(height: 8),
                      Text("Version $version", style: textTheme.bodyMedium?.copyWith(color: color.primary.withValues(alpha: 0.75))),
                    ],
                    SizedBox(height: 16),
                    Text("${data.count} packages", style: textTheme.titleMedium?.copyWith(color: color.primary.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ...data.licenses.map((license) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildLicenseCard(context, color, textTheme, isDark, license),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLicenseCard(BuildContext context, ColorScheme color, TextTheme textTheme, bool isDark, LicenseEntry license) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.glassGradient(color.primary, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppColors.glassShadow(color.primary, isDark),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Icon(Icons.description_outlined, color: color.primary, size: 20),
        ),
        title: Text(license.packages.join(", "), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color.primary, letterSpacing: -0.2)),
        children: license.paragraphs.map((para) => Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(para.text, style: textTheme.bodySmall?.copyWith(color: color.primary.withValues(alpha: 0.75), height: 1.5)),
        )).toList(),
      ),
    );
  }
}

class LicenseData {
  final int count;
  final List<LicenseEntry> licenses;
  LicenseData(this.count, this.licenses);
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.glassGradient(color.primary, isDark).map((c) => c.withValues(alpha: (c.a * 3).clamp(0, 1))).toList(),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.2), blurRadius: 24, offset: Offset(0, 8))],
                            ),
                            child: Image.asset('assets/logo/rupee.png', width: 80, height: 80),
                          ),
                          SizedBox(height: 20),
                          Text("Mudra Manager", style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                          SizedBox(height: 8),
                          if (info != null) Text("v${info.version}", style: textTheme.bodyLarge?.copyWith(color: color.primary.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Smart personal finance app that helps you track expenses, manage budgets, and organize transactions effortlessly.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant, height: 1.5),
                      ),
                      SizedBox(height: 32),
                      _buildFeatureGrid(context, color, textTheme, isDark),
                      SizedBox(height: 32),
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text("MEET THE TEAM", style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color.primary, letterSpacing: 0.5, fontSize: 12)),
                      ),
                      SizedBox(height: 16),
                      _buildTeamGrid(context, color, textTheme, isDark),
                      SizedBox(height: 32),
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text("MORE INFORMATION", style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color.primary, letterSpacing: 0.5, fontSize: 12)),
                      ),
                      SizedBox(height: 16),
                      _buildInfoCard(context, color, textTheme, isDark, Icons.privacy_tip_outlined, "Privacy Policy", "View our privacy policy", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('https://YOUR_USERNAME.github.io/mudra_manager/privacy-policy.html');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, isDark, Icons.description_outlined, "Terms & Conditions", "View terms and conditions", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('https://YOUR_USERNAME.github.io/mudra_manager/terms-conditions.html');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, isDark, Icons.email_outlined, "Contact Us", "support@mudramanager.app", () {
                        HapticFeedback.mediumImpact();
                        _launchURL('mailto:support@mudramanager.app');
                      }),
                      SizedBox(height: 12),
                      _buildInfoCard(context, color, textTheme, isDark, Icons.verified_user_outlined, "License", "MIT License", () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LicenseScreen(appName: info?.appName, version: info?.version)));
                      }),
                      SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Made with ', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color.onSurface.withValues(alpha: 0.6))),
                                Icon(Icons.favorite, size: 28, color: Colors.red),
                                Text(' in India', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('© ${DateTime.now().year} ${info?.appName ?? "Mudra Manager"}', style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
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

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildFeatureGrid(BuildContext context, ColorScheme color, TextTheme textTheme, bool isDark) {
    final features = [
      (Icons.sms_outlined, "SMS Auto-Import", Color(0xFF06B6D4)),
      (Icons.pie_chart_outline, "Budget Tracking", Color(0xFFF59E0B)),
      (Icons.bar_chart, "Insights & Reports", Color(0xFF6366F1)),
      (Icons.lock_outline, "Secure & Private", Color(0xFF10B981)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.glassGradient(feature.$3, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: feature.$3.withValues(alpha: 0.3), width: 1.5),
            boxShadow: AppColors.glassShadow(feature.$3, isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: feature.$3.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Icon(feature.$1, color: feature.$3, size: 28),
              ),
              SizedBox(height: 12),
              Text(feature.$2, textAlign: TextAlign.center, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: feature.$3, letterSpacing: -0.2)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamGrid(BuildContext context, ColorScheme color, TextTheme textTheme, bool isDark) {
    final team = [
      ("Aloke Tewary", "Product Designer", Icons.design_services, Color(0xFF06B6D4)),
      ("Aloke Tewary", "Flutter Developer", Icons.code, Color(0xFF6366F1)),
      ("Sougata Chakraborty", "Backend & Testing", Icons.storage_outlined, Color(0xFF10B981)),
    ];
    return Column(
      children: team.map((member) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.glassGradient(member.$4, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: member.$4.withValues(alpha: 0.3), width: 1.5),
            boxShadow: AppColors.glassShadow(member.$4, isDark),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: member.$4.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Icon(member.$3, color: member.$4, size: 26),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.$1, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: member.$4, letterSpacing: -0.2)),
                    SizedBox(height: 4),
                    Text(member.$2, style: textTheme.bodyMedium?.copyWith(color: member.$4.withValues(alpha: 0.75), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }



  Widget _buildInfoCard(BuildContext context, ColorScheme color, TextTheme textTheme, bool isDark, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final gradientColors = AppColors.glassGradient(color.primary, isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: AppColors.glassShadow(color.primary, isDark),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Icon(icon, color: color.primary, size: 26),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color.primary, letterSpacing: -0.2)),
                  SizedBox(height: 4),
                  Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: color.primary.withValues(alpha: 0.75), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.primary.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
