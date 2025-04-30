import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ProfileTile({super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title, style: textTheme.titleMedium),
      subtitle: Text(subtitle, style: textTheme.bodySmall,),
      leading: Icon(icon, color: color.secondary,),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: color.primary,),
    );
  }
}