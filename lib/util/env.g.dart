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
    1147958438,
    2183394417,
    2189042820,
    1283511835,
    2414847171,
    2586602082,
    407952901,
    2708403726,
    509926507,
    2848399699,
    94042514,
    2730891878,
    4148274525,
    2080158119,
    3176557162,
    1677792837,
    1327839105,
    1505245401,
    4137141990,
    486961080,
    86728431,
    4145035701,
    317363029,
    2842023885,
    2919895886,
    2579275933,
    3312498839,
    3545368524,
    2532848705,
    771941547,
    4292857037,
    3853639218,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    1147958502,
    2183394397,
    2189042907,
    1283511911,
    2414847108,
    2586601998,
    407952955,
    2708403808,
    509926463,
    2848399626,
    94042571,
    2730891848,
    4148274486,
    2080158192,
    3176557074,
    1677792817,
    1327839231,
    1505245319,
    4137141919,
    486961115,
    86728344,
    4145035759,
    317362971,
    2842023811,
    2919895915,
    2579275964,
    3312498897,
    3545368560,
    2532848746,
    771941514,
    4292857058,
    3853639257,
  ];

  static final String encryptKey = String.fromCharCodes(List<int>.generate(
    _envieddataencryptKey.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]));

  static const List<int> _enviedkeyencryptIv = <int>[
    2348601134,
    1419284631,
    476330856,
    3366036645,
    296830305,
    3835774422,
    2325277270,
    3061607454,
    2938777242,
    879928934,
    443422747,
    2411550597,
    2166744805,
    2488378989,
    3124892060,
    3211236023,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    2348601111,
    1419284648,
    476330757,
    3366036694,
    296830291,
    3835774448,
    2325277204,
    3061607538,
    2938777281,
    879928914,
    443422764,
    2411550677,
    2166744741,
    2488378921,
    3124892101,
    3211235969,
  ];

  static final String encryptIv = String.fromCharCodes(List<int>.generate(
    _envieddataencryptIv.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]));
}
