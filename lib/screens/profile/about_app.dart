import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("About Mudra Manager")),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Image.asset('assets/logo/rupee.png', width: 64, height: 64),
                    ),
                    SizedBox(height: 16),
                    Text("Mudra Manager", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (info != null) Text("Version ${info.version} (${info.buildNumber})", style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                    SizedBox(height: 16),
                    Text(
                      "Mudra Manager is a smart personal finance app that helps you track expenses, manage budgets, and organize transactions effortlessly. With offline support, SMS auto-detection, and insightful charts, it gives you full control over your money.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text("Meet the Team", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color.onSurfaceVariant)),
              SizedBox(height: 12),
              _buildTeamCard(context, color, textTheme, "Aloke Tewary", "Product Designer", Icons.design_services),
              SizedBox(height: 8),
              _buildTeamCard(context, color, textTheme, "Aloke Tewary", "Flutter Developer", Icons.code),
              SizedBox(height: 8),
              _buildTeamCard(context, color, textTheme, "Sougata Chakraborty", "Backend & Testing", Icons.storage_outlined),
              SizedBox(height: 24),
              Text("More Information", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color.onSurfaceVariant)),
              SizedBox(height: 12),
              _buildInfoCard(context, color, textTheme, Icons.privacy_tip_outlined, "Privacy Policy", "View our privacy policy", () {}),
              SizedBox(height: 8),
              _buildInfoCard(context, color, textTheme, Icons.email_outlined, "Contact Us", "support@mudramanager.app", () {}),
              SizedBox(height: 8),
              _buildInfoCard(context, color, textTheme, Icons.verified_user_outlined, "License", "MIT License", () {
                HapticFeedback.mediumImpact();
                showLicensePage(context: context, applicationName: info?.appName, applicationVersion: info?.version);
              }),
              SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Made with ',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface.withValues(alpha: 0.6),
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.1), offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                        Icon(Icons.favorite, size: 28, color: Colors.red),
                        Text(
                          ' in India',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface.withValues(alpha: 0.6),
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.1), offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('© ${DateTime.now().year} ${info?.appName ?? "Mudra Manager"}', style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, ColorScheme color, TextTheme textTheme, String name, String role, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color.primary, size: 24)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(role, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color.primary, size: 24)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
