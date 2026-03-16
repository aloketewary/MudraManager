import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingProvider = Provider<String>((ref) {
  return _updateGreeting();
});

String _updateGreeting() {
  final hour = DateTime.now().hour;
  String greeting = 'hello';
  if (hour < 12) {
    greeting = 'good_morning';
  } else if (hour < 17) {
    greeting = 'good_afternoon';
  } else if (hour < 20) {
    greeting = 'good_evening';
  } else {
    greeting = 'good_night';
  }
  return greeting;
}
