import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<PackageInfo> _getAppInfo() async {
    return await PackageInfo.fromPlatform();
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    String description = "Mudra Manager is a smart personal finance app that helps you track expenses, manage budgets, and organize transactions effortlessly. With offline support, SMS auto-detection, and insightful charts, it gives you full control over your money. Simple, secure, and powerful—perfect for building better financial habits every day.";


    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About Mudra Manager",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _getAppInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Header
              Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 72,
                    color: color.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Mudra Manager",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (info != null)
                    Text(
                      "Version ${info.version} (${info.buildNumber})",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                ],
              ),

              const SizedBox(height: 32),

              // Meet the Team
              _buildSectionHeader("Meet the Minds Behind the App"),
              _buildTeamMember(
                name: "Aloke Tewary",
                role: "Product Designer",
                icon: Icons.design_services,
              ),
              _buildTeamMember(
                name: "Aloke Tewary",
                role: "Flutter Developer",
                icon: Icons.code,
              ),
              _buildTeamMember(
                name: "Sougata Chakraborty",
                role: "Backend and Testing Engineer",
                icon: Icons.storage_outlined,
              ),

              const SizedBox(height: 32),

              // Other Details
              _buildSectionHeader("More Information"),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text("Privacy Policy"),
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text("Contact Us"),
                subtitle: const Text("support@mudramanager.app"),
                onTap: () {
                  // TODO: Open email intent or form
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('License'),
                subtitle: const Text('MIT License'),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: info?.appName,
                    applicationVersion: info?.version,
                  );
                },
              ),
              const Spacer(),
              Center(
                child: Text(
                  '© ${DateTime.now().year} ${info?.appName}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(name),
      subtitle: Text(role),
    );
  }
}
