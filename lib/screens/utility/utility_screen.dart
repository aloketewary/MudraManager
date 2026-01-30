import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/screens/budget/budget_dashboard.dart';
import 'package:mudra_manager/screens/goal/goal_screen.dart';
import 'package:mudra_manager/screens/profile/manage_account_screen.dart';
import 'package:mudra_manager/screens/profile/manage_categories_screen.dart';

class UtilityScreen extends StatelessWidget {
  const UtilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final utilities = [
      _UtilityItem(
        title: "Budgets",
        subtitle: "Manage your spending limits",
        icon: Icons.pie_chart_outline,
        color: Colors.orange,
        destination: const BudgetDashboard(),
      ),
      _UtilityItem(
        title: "Goals",
        subtitle: "Track your savings progress",
        icon: Icons.emoji_flags_outlined,
        color: Colors.blue,
        destination: const GoalScreen(),
      ),
      _UtilityItem(
        title: "Accounts",
        subtitle: "Manage your accounts",
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.purple,
        destination: const ManageAccountScreen(),
      ),
      _UtilityItem(
        title: "Categories",
        subtitle: "Manage your categories",
        icon: Icons.category_outlined,
        color: Colors.teal,
        destination: const ManageCategoriesScreen(),
      ),
    ];

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.0,
        ),
        itemCount: utilities.length,
        itemBuilder: (context, index) {
          final item = utilities[index];
          return _UtilityCard(item: item);
        },
      ),
    );
  }
}

class _UtilityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget destination;

  _UtilityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

class _UtilityCard extends StatelessWidget {
  final _UtilityItem item;

  const _UtilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color.withValues(alpha: 0.15),
            item.color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: item.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (item.title == "Budgets") {
              context.push('/budget-dashboard');
            } else if (item.title == "Goals") {
              context.push('/goal-screen');
            } else if (item.title == "Accounts") {
              context.push('/manage-accounts');
            } else if (item.title == "Categories") {
              context.push('/manage-categories');
            }
          },
          child: Stack(
            children: [
              // Background Icon Watermark
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    item.icon,
                    size: 120,
                    color: item.color.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.color, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
