
extension StringUtil on String {

  subStringAfterLast(String delimeter) {
    final pos = lastIndexOf(delimeter);
    return pos != -1 ? substring(pos + 1, length) : this;
  }

   String subStringAfter(String delimeter) {
     final pos = indexOf(delimeter);
     return pos != -1 ? substring(pos + 1, length) : this;
  }

  subStringBefore(String delimeter) {
    final pos = indexOf(delimeter);
    return pos != -1 ? substring(0, pos) : this;
  }

  subStringBeforeLast(String delimeter) {
    final pos = lastIndexOf(delimeter);
    return pos != -1 ? substring(0, pos) : this;
  }

  toInt({int defaultValue = 0}) {
    return int.tryParse(this) ?? defaultValue;
  }

  bool isNan() {
    return int.tryParse(this)?.isNaN ?? false;
  }

  double toDouble({double defaultValue = 0}) {
    return double.tryParse(this) ?? defaultValue;
  }
}
