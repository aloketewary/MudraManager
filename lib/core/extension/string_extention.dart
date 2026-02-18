extension StringUtil on String {
  String substringAfterLast(String delimeter) {
    final pos = lastIndexOf(delimeter);
    return pos != -1 ? substring(pos + 1, length) : this;
  }

  String substringAfter(String delimeter) {
    final pos = indexOf(delimeter);
    return pos != -1 ? substring(pos + 1, length) : this;
  }

  String substringBefore(String delimeter) {
    final pos = indexOf(delimeter);
    return pos != -1 ? substring(0, pos) : this;
  }

  String substringBeforeLast(String delimeter) {
    final pos = lastIndexOf(delimeter);
    return pos != -1 ? substring(0, pos) : this;
  }

  int toInt({int defaultValue = 0}) {
    return int.tryParse(this) ?? defaultValue;
  }

  bool isNotNumeric() {
    return double.tryParse(replaceAll(',', '')) == null;
  }

  double toDouble({double defaultValue = 0}) {
    return double.tryParse(replaceAll(',', '')) ?? defaultValue;
  }

  String toNumericOnly() {
    return replaceAll(RegExp(r'[^0-9.]'), '');
  }
}
