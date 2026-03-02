import 'package:mudra_manager/core/utils/fake_data_generator.dart';

class GuestModeUtil {
  static double applyGuestMode(double value, bool isGuestMode) {
    if (!isGuestMode) return value;
    return FakeDataGenerator.generateFakeAmount();
  }

  static String formatWithGuestMode(double value, bool isGuestMode, String Function(double) formatter) {
    if (!isGuestMode) return formatter(value);
    return formatter(FakeDataGenerator.generateFakeAmount());
  }
}
