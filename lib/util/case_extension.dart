extension CaseExtension on String {
  String toCamelCase() {
    return toLowerCase().split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join('');
  }

  String toPascalCase() {
    return toLowerCase().split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String toSnakeCase() {
    return replaceAll(' ', '_').toLowerCase();
  }

  String toKebabCase() {
    return replaceAll(' ', '-').toLowerCase();
  }

  String toTitleCase() {
    return toLowerCase().split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String capitalize() {
    return toLowerCase().split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
