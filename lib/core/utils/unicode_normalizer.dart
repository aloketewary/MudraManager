/// Normalizes Unicode styled text (bold, italic, sans-serif, monospace, etc.)
/// to plain ASCII. RCS messages from some banks use Mathematical Bold Unicode
/// characters (e.g. 𝐑𝐬 instead of Rs) which break regex-based parsers.
///
/// Covers:
/// - Mathematical Bold (U+1D400–1D433, U+1D41A–1D44D)
/// - Mathematical Italic (U+1D434–1D467)
/// - Mathematical Bold Italic (U+1D468–1D49B)
/// - Mathematical Sans-Serif (U+1D5A0–1D5D3)
/// - Mathematical Sans-Serif Bold (U+1D5D4–1D607)
/// - Mathematical Sans-Serif Italic (U+1D608–1D63B)
/// - Mathematical Sans-Serif Bold Italic (U+1D63C–1D66F)
/// - Mathematical Monospace (U+1D670–1D6A3)
/// - Mathematical Bold Digits (U+1D7CE–1D7D7)
/// - Mathematical Double-Struck Digits (U+1D7D8–1D7E1)
/// - Mathematical Sans-Serif Digits (U+1D7E2–1D7EB)
/// - Mathematical Sans-Serif Bold Digits (U+1D7EC–1D7F5)
/// - Mathematical Monospace Digits (U+1D7F6–1D7FF)
/// - Fullwidth ASCII (U+FF01–FF5E)
String normalizeUnicode(String input) {
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    final normalized = _normalizeRune(rune);
    buffer.writeCharCode(normalized);
  }

  return buffer.toString();
}

int _normalizeRune(int rune) {
  // ── Letters: Mathematical styled A-Z / a-z ──
  // Each style block has 26 uppercase then 26 lowercase

  const letterRanges = [
    (0x1D400, 0x1D419, 0x41), // Bold A-Z
    (0x1D41A, 0x1D433, 0x61), // Bold a-z
    (0x1D434, 0x1D44D, 0x41), // Italic A-Z
    (0x1D44E, 0x1D467, 0x61), // Italic a-z
    (0x1D468, 0x1D481, 0x41), // Bold Italic A-Z
    (0x1D482, 0x1D49B, 0x61), // Bold Italic a-z
    (0x1D49C, 0x1D4B5, 0x41), // Script A-Z
    (0x1D4B6, 0x1D4CF, 0x61), // Script a-z
    (0x1D4D0, 0x1D4E9, 0x41), // Bold Script A-Z
    (0x1D4EA, 0x1D503, 0x61), // Bold Script a-z
    (0x1D504, 0x1D51D, 0x41), // Fraktur A-Z
    (0x1D51E, 0x1D537, 0x61), // Fraktur a-z
    (0x1D538, 0x1D551, 0x41), // Double-Struck A-Z
    (0x1D552, 0x1D56B, 0x61), // Double-Struck a-z
    (0x1D56C, 0x1D585, 0x41), // Bold Fraktur A-Z
    (0x1D586, 0x1D59F, 0x61), // Bold Fraktur a-z
    (0x1D5A0, 0x1D5B9, 0x41), // Sans-Serif A-Z
    (0x1D5BA, 0x1D5D3, 0x61), // Sans-Serif a-z
    (0x1D5D4, 0x1D5ED, 0x41), // Sans-Serif Bold A-Z
    (0x1D5EE, 0x1D607, 0x61), // Sans-Serif Bold a-z
    (0x1D608, 0x1D621, 0x41), // Sans-Serif Italic A-Z
    (0x1D622, 0x1D63B, 0x61), // Sans-Serif Italic a-z
    (0x1D63C, 0x1D655, 0x41), // Sans-Serif Bold Italic A-Z
    (0x1D656, 0x1D66F, 0x61), // Sans-Serif Bold Italic a-z
    (0x1D670, 0x1D689, 0x41), // Monospace A-Z
    (0x1D68A, 0x1D6A3, 0x61), // Monospace a-z
  ];

  for (final (start, end, asciiBase) in letterRanges) {
    if (rune >= start && rune <= end) {
      return asciiBase + (rune - start);
    }
  }

  // ── Digits: Mathematical styled 0-9 ──
  const digitRanges = [
    (0x1D7CE, 0x1D7D7), // Bold
    (0x1D7D8, 0x1D7E1), // Double-Struck
    (0x1D7E2, 0x1D7EB), // Sans-Serif
    (0x1D7EC, 0x1D7F5), // Sans-Serif Bold
    (0x1D7F6, 0x1D7FF), // Monospace
  ];

  for (final (start, end) in digitRanges) {
    if (rune >= start && rune <= end) {
      return 0x30 + (rune - start); // '0' = 0x30
    }
  }

  // ── Fullwidth ASCII (U+FF01–FF5E → U+0021–007E) ──
  if (rune >= 0xFF01 && rune <= 0xFF5E) {
    return rune - 0xFF01 + 0x21;
  }

  return rune;
}
