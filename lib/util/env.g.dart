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
    3349994969,
    1145457910,
    2408660711,
    519495084,
    1895953344,
    411791150,
    2967007921,
    1876263742,
    3540785081,
    178072361,
    4267934168,
    3011964522,
    472554234,
    1570595722,
    4283110237,
    1116137346,
    1834022357,
    367235078,
    2398575808,
    2785629471,
    1228688197,
    2526915150,
    2343441707,
    3047884819,
    2131188436,
    2554538304,
    3918239156,
    3762392242,
    4127348788,
    1449602567,
    4110735722,
    1194950718,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    3349994905,
    1145457882,
    2408660664,
    519495120,
    1895953287,
    411791170,
    2967007887,
    1876263760,
    3540785133,
    178072432,
    4267934081,
    3011964484,
    472554129,
    1570595805,
    4283110181,
    1116137462,
    1834022315,
    367235160,
    2398575801,
    2785629564,
    1228688178,
    2526915092,
    2343441765,
    3047884893,
    2131188465,
    2554538337,
    3918239218,
    3762392206,
    4127348767,
    1449602598,
    4110735685,
    1194950741,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    981912954,
    4063744988,
    818022018,
    946625861,
    3368696267,
    547195063,
    3847032264,
    2429390299,
    4120449271,
    2053972008,
    1095399431,
    893416449,
    1788901266,
    3862759795,
    3143992910,
    298536823,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    981912899,
    4063744995,
    818022127,
    946625846,
    3368696313,
    547195025,
    3847032202,
    2429390263,
    4120449196,
    2053971996,
    1095399472,
    893416529,
    1788901330,
    3862759735,
    3143992855,
    298536769,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
