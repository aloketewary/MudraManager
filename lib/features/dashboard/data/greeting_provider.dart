import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';

enum DayPeriod { morning, afternoon, evening, night }

final dayPeriodProvider = Provider<DayPeriod>((ref) {
  final hour = DateTime.now().hour;
  if (hour < 12) return DayPeriod.morning;
  if (hour < 17) return DayPeriod.afternoon;
  if (hour < 20) return DayPeriod.evening;
  return DayPeriod.night;
});

/// Old key-based provider (used by translate())
final greetingProvider = Provider<String>((ref) {
  final period = ref.watch(dayPeriodProvider);
  return switch (period) {
    DayPeriod.morning => 'good_morning',
    DayPeriod.afternoon => 'good_afternoon',
    DayPeriod.evening || DayPeriod.night => 'good_evening',
  };
});

/// Tone-aware greeting without name (for AnimatedGreeting's first text)
final toneGreetingProvider = Provider<String>((ref) {
  final tone = ref.watch(tonePackProvider);
  final period = ref.watch(dayPeriodProvider);
  // Pass placeholder, then strip it to get just the greeting part
  const placeholder = '\u200B'; // zero-width space
  final full = switch (period) {
    DayPeriod.morning => tone.greetingMorning(placeholder),
    DayPeriod.afternoon => tone.greetingAfternoon(placeholder),
    DayPeriod.evening || DayPeriod.night => tone.greetingEvening(placeholder),
  };
  // Remove the placeholder and trim trailing comma/space
  return full.replaceAll(placeholder, '').replaceAll(RegExp(r'[,!]\s*$'), '').trim();
});