// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const List<int> _enviedkeyencryptKey = <int>[
    2090846518,
    1649653217,
    705559378,
    1977853124,
    931859371,
    650785071,
    3329757954,
    276409,
    2081358794,
    982469837,
    521714026,
    2200987984,
    1812212530,
    934095529,
    1212593785,
    3008655008,
    2451082428,
    2565408039,
    3534709723,
    3978233152,
    3999162605,
    3813290406,
    2811751667,
    1127621882,
    102781025,
    663475905,
    4129736141,
    1025198157,
    3491056799,
    4093890040,
    234543504,
    1119045341,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    2090846582,
    1649653197,
    705559309,
    1977853112,
    931859436,
    650785091,
    3329758012,
    276439,
    2081358750,
    982469780,
    521713971,
    2200988030,
    1812212569,
    934095614,
    1212593665,
    3008655060,
    2451082434,
    2565408121,
    3534709666,
    3978233123,
    3999162522,
    3813290492,
    2811751613,
    1127621812,
    102780996,
    663475936,
    4129736075,
    1025198193,
    3491056820,
    4093890009,
    234543551,
    1119045302,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    2809388320,
    2652179503,
    171570816,
    881136495,
    3480520910,
    2504505384,
    1373093387,
    2146257787,
    3640020008,
    3529634710,
    1630731254,
    4218927487,
    2484213802,
    779284628,
    1105673187,
    4035693991,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    2809388313,
    2652179472,
    171570925,
    881136412,
    3480520956,
    2504505358,
    1373093449,
    2146257687,
    3640020083,
    3529634722,
    1630731201,
    4218927407,
    2484213866,
    779284688,
    1105673146,
    4035693969,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
