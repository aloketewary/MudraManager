import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/unicode_normalizer.dart';

void main() {
  group('normalizeUnicode', () {
    test('plain ASCII passes through unchanged', () {
      expect(normalizeUnicode('Rs.500 debited from a/c XX1234'), 'Rs.500 debited from a/c XX1234');
    });

    test('empty string returns empty', () {
      expect(normalizeUnicode(''), '');
    });

    test('Mathematical Bold uppercase A-Z', () {
      // 𝐀𝐁𝐂...𝐙
      expect(normalizeUnicode('𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙'), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    });

    test('Mathematical Bold lowercase a-z', () {
      expect(normalizeUnicode('𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳'), 'abcdefghijklmnopqrstuvwxyz');
    });

    test('Mathematical Bold Digits 0-9', () {
      expect(normalizeUnicode('𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗'), '0123456789');
    });

    test('mixed bold and plain', () {
      expect(normalizeUnicode('𝐑𝐬 70.00'), 'Rs 70.00');
    });

    test('Fullwidth ASCII', () {
      // Ｒｓ．５００
      expect(normalizeUnicode('\uFF32\uFF53\uFF0E\uFF15\uFF10\uFF10'), 'Rs.500');
    });

    test('real Federal Bank RCS message', () {
      const input = '𝐑𝐬 70.00 𝐬𝐞𝐧𝐭 𝐯𝐢𝐚 𝐔𝐏𝐈 𝐨𝐧 19-04-2026 𝐚𝐭 22:36:58 𝐭𝐨 Bansi Pan Shop.'
          '𝐑𝐞𝐟:610952503907.𝐍𝐨𝐭 𝐲𝐨𝐮? 𝐂𝐚𝐥𝐥 𝟏𝟖𝟎𝟎𝟒𝟐𝟓𝟏𝟏𝟗𝟗/𝐒𝐌𝐒 𝐁𝐋𝐎𝐂𝐊𝐔𝐏𝐈 𝐭𝐨 𝟗𝟖𝟗𝟓𝟎 𝟖𝟖𝟖𝟖𝟖 -𝐅𝐞𝐝𝐞𝐫𝐚𝐥 𝐁𝐚𝐧𝐤';
      final normalized = normalizeUnicode(input);

      expect(normalized, contains('Rs 70.00'));
      expect(normalized, contains('sent via UPI'));
      expect(normalized, contains('19-04-2026'));
      expect(normalized, contains('Bansi Pan Shop'));
      expect(normalized, contains('Ref:610952503907'));
      expect(normalized, contains('Not you?'));
      expect(normalized, contains('Call 18004251199'));
      expect(normalized, contains('SMS BLOCKUPI'));
      expect(normalized, contains('Federal Bank'));
    });

    test('bold digits in phone number', () {
      expect(normalizeUnicode('𝟏𝟖𝟎𝟎𝟒𝟐𝟓𝟏𝟏𝟗𝟗'), '18004251199');
    });

    test('mixed: bold keywords with plain amounts', () {
      const input = '𝐑𝐬.500.00 𝐝𝐞𝐛𝐢𝐭𝐞𝐝 from a/c XX6988';
      final normalized = normalizeUnicode(input);
      expect(normalized, 'Rs.500.00 debited from a/c XX6988');
    });

    test('preserves emojis and special chars', () {
      expect(normalizeUnicode('✅ 🎉 ₹500'), '✅ 🎉 ₹500');
    });

    test('preserves Hindi/Bengali text', () {
      expect(normalizeUnicode('खर्च ট্র্যাকার'), 'खर्च ট্র্যাকার');
    });

    test('preserves newlines and whitespace', () {
      expect(normalizeUnicode('𝐑𝐬 100\n𝐝𝐞𝐛𝐢𝐭𝐞𝐝'), 'Rs 100\ndebited');
    });

    test('Sans-Serif Bold', () {
      // 𝗔𝗕𝗖 = U+1D5D4, U+1D5D5, U+1D5D6
      expect(normalizeUnicode('𝗔𝗕𝗖'), 'ABC');
    });

    test('Monospace', () {
      // 𝙰𝙱𝙲 = U+1D670, U+1D671, U+1D672
      expect(normalizeUnicode('𝙰𝙱𝙲'), 'ABC');
    });

    test('Italic', () {
      // 𝐴𝐵𝐶 = U+1D434, U+1D435, U+1D436
      expect(normalizeUnicode('𝐴𝐵𝐶'), 'ABC');
    });

    test('real RCS: bold Rs with rupee symbol fallback', () {
      // Some banks mix ₹ symbol with bold text
      const input = '₹𝟕𝟎.𝟎𝟎 𝐬𝐞𝐧𝐭 𝐯𝐢𝐚 𝐔𝐏𝐈';
      final normalized = normalizeUnicode(input);
      expect(normalized, contains('₹70.00'));
      expect(normalized, contains('sent via UPI'));
    });

    test('performance: long message normalizes quickly', () {
      final longInput = '𝐑𝐬 500.00 𝐝𝐞𝐛𝐢𝐭𝐞𝐝 ' * 100;
      final sw = Stopwatch()..start();
      normalizeUnicode(longInput);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });
}
