enum PluginGroup {
  smsParser('SMS Parsers', 'Parse SMS from banks'),
  exportTemplate('Export Templates', 'Export financial data'),
  notification('Notifications', 'Get alerts & reminders'),
  budget('Budget & Spending', 'Manage budgets'),
  goals('Goals & Savings', 'Track financial goals'),
  categoryManagement('Category Management', 'Industry & regional categories'),
  utility('Utilities', 'Backup, sync & tools'),
  custom('Custom Plugins', 'User-created plugins');

  final String label;
  final String description;

  const PluginGroup(this.label, this.description);
}

class PluginMetadata {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String iconUrl;
  final int downloads;
  final double rating;
  final String packageUrl;
  final PluginGroup group;
  final List<PluginConfigOption>? configOptions;

  PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.iconUrl,
    required this.downloads,
    required this.rating,
    required this.packageUrl,
    required this.group,
    this.configOptions,
  });

  factory PluginMetadata.fromJson(Map<String, dynamic> json) => PluginMetadata(
        id: json['id'],
        name: json['name'],
        version: json['version'],
        description: json['description'],
        author: json['author'],
        iconUrl: json['iconUrl'],
        downloads: json['downloads'],
        rating: json['rating'].toDouble(),
        packageUrl: json['packageUrl'],
        group: PluginGroup.values.firstWhere(
          (g) => g.name == json['group'],
          orElse: () => PluginGroup.custom,
        ),
        configOptions: json['configOptions'] != null
            ? (json['configOptions'] as List)
                .map((e) => PluginConfigOption.fromJson(e))
                .toList()
            : null,
      );
}

class PluginConfigOption {
  final String key;
  final String label;
  final String type;
  final dynamic defaultValue;
  final String? suffix;
  final String? prefix;

  PluginConfigOption({
    required this.key,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.suffix,
    this.prefix,
  });

  factory PluginConfigOption.fromJson(Map<String, dynamic> json) =>
      PluginConfigOption(
        key: json['key'],
        label: json['label'],
        type: json['type'],
        defaultValue: json['defaultValue'],
        suffix: json['suffix'],
        prefix: json['prefix'],
      );
}
