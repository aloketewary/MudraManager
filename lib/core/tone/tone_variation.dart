import 'dart:math';

final _random = Random();

/// Picks a random string from a list of variations.
/// Use this inside TonePack implementations to avoid repetitive messages.
String pickRandom(List<String> variants) => variants[_random.nextInt(variants.length)];
