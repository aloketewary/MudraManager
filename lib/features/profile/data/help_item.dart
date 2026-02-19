class HelpItem {
  final String id;
  final String title;
  final String icon;
  final String shortDescription;
  final String description;
  final List<String> steps;
  final List<String> tips;

  HelpItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.shortDescription,
    required this.description,
    required this.steps,
    required this.tips,
  });

  factory HelpItem.fromJson(Map<String, dynamic> json) => HelpItem(
        id: json['id'],
        title: json['title'],
        icon: json['icon'],
        shortDescription: json['shortDescription'],
        description: json['description'],
        steps: List<String>.from(json['steps']),
        tips: List<String>.from(json['tips']),
      );
}
