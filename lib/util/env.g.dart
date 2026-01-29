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
    3182990239,
    1724444082,
    323789175,
    2344148154,
    4171108505,
    1252801336,
    2082842422,
    48245889,
    1811363141,
    3450099246,
    597536923,
    1857030020,
    648940034,
    887167380,
    3378748783,
    3209314810,
    1456769866,
    4257177599,
    3002528368,
    120253496,
    3081622577,
    3001422856,
    3877299113,
    2912581568,
    1205672441,
    4198650144,
    2646210127,
    3260180057,
    3229603924,
    174526122,
    1687772583,
    1829863368,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    3182990303,
    1724444062,
    323789096,
    2344148166,
    4171108574,
    1252801364,
    2082842376,
    48245999,
    1811363089,
    3450099319,
    597536962,
    1857030058,
    648940137,
    887167427,
    3378748695,
    3209314702,
    1456769844,
    4257177505,
    3002528265,
    120253531,
    3081622598,
    3001422930,
    3877299175,
    2912581518,
    1205672412,
    4198650113,
    2646210057,
    3260180069,
    3229603967,
    174526091,
    1687772552,
    1829863331,
  ];

  static final String encryptKey = String.fromCharCodes(List<int>.generate(
    _envieddataencryptKey.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]));

  static const List<int> _enviedkeyencryptIv = <int>[
    2570617873,
    405995984,
    2987983516,
    3412190978,
    2630865421,
    1437482379,
    3135442947,
    2114177343,
    2370544357,
    528993900,
    2554320971,
    1336175591,
    3231664782,
    4184253811,
    3725696419,
    731757354,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    2570617896,
    405996015,
    2987983601,
    3412191089,
    2630865471,
    1437482413,
    3135443009,
    2114177363,
    2370544318,
    528993880,
    2554321020,
    1336175543,
    3231664846,
    4184253751,
    3725696506,
    731757340,
  ];

  static final String encryptIv = String.fromCharCodes(List<int>.generate(
    _envieddataencryptIv.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]));
}
