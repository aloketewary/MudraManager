import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingProvider = FutureProvider.autoDispose<String>((ref) async {
  return _updateGreeting(); // Your async greeting logic
});

String _updateGreeting() {
  final hour = DateTime.now().hour;
  String greeting = 'Hello';
  if (hour < 12) {
    greeting = 'Good morning';
  } else if (hour < 17) {
    greeting = 'Good afternoon';
  } else if (hour < 20) {
    greeting = 'Good evening';
  } else {
    greeting = 'Good night';
  }
  return greeting;
}