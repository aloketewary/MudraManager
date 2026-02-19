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
    1578278614,
    1523529878,
    2895343690,
    3064060527,
    1103192151,
    4054545484,
    1559218529,
    3278655253,
    2033264743,
    486200951,
    3353270207,
    1276163535,
    552474714,
    1513844803,
    1195706943,
    306281186,
    3342807339,
    3814116602,
    327464080,
    1095855811,
    2796929124,
    1432514971,
    2317283090,
    2507033448,
    3577315705,
    3987535649,
    619854022,
    1126369400,
    1927582405,
    1645084622,
    2468976818,
    3011792925,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    1578278550,
    1523529914,
    2895343637,
    3064060435,
    1103192080,
    4054545440,
    1559218527,
    3278655355,
    2033264691,
    486200878,
    3353270246,
    1276163553,
    552474673,
    1513844756,
    1195706951,
    306281110,
    3342807381,
    3814116516,
    327464169,
    1095855776,
    2796929043,
    1432515009,
    2317283164,
    2507033382,
    3577315676,
    3987535616,
    619853952,
    1126369348,
    1927582446,
    1645084655,
    2468976797,
    3011793014,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    489277813,
    2340985476,
    592170263,
    3238444589,
    3004525608,
    3423814028,
    2528963262,
    952327464,
    3363876825,
    920309133,
    1559365983,
    353031008,
    559854850,
    2694874754,
    3596608569,
    1519459855,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    489277772,
    2340985531,
    592170362,
    3238444638,
    3004525594,
    3423814058,
    2528963324,
    952327492,
    3363876738,
    920309177,
    1559365992,
    353030960,
    559854914,
    2694874822,
    3596608608,
    1519459897,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
