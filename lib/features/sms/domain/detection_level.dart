enum DetectionSensitivity {
  strict,
  balanced,
  aggressive,
}

int getThreshold(DetectionSensitivity mode) {
  switch (mode) {
    case DetectionSensitivity.strict:
      return 70;
    case DetectionSensitivity.balanced:
      return 50;
    case DetectionSensitivity.aggressive:
      return 30;
  }
}