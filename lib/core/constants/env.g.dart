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
    412916396,
    1750908146,
    624654848,
    1974574238,
    2169948940,
    2194931558,
    2374996360,
    2188221404,
    1152204969,
    1839681398,
    2727003357,
    3009613783,
    438056526,
    775427423,
    2850989490,
    3958980998,
    2887606066,
    2187118530,
    1882879630,
    2027568812,
    2925306408,
    573468184,
    680323481,
    772363306,
    2738666587,
    2567760211,
    3859552279,
    3741854412,
    2968401650,
    1505107543,
    3470554887,
    1423756181,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    412916460,
    1750908126,
    624654943,
    1974574306,
    2169949003,
    2194931466,
    2374996406,
    2188221362,
    1152205053,
    1839681327,
    2727003268,
    3009613817,
    438056485,
    775427336,
    2850989514,
    3958981106,
    2887606092,
    2187118492,
    1882879735,
    2027568847,
    2925306463,
    573468226,
    680323543,
    772363364,
    2738666622,
    2567760242,
    3859552337,
    3741854448,
    2968401625,
    1505107574,
    3470554920,
    1423756286,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    3491521925,
    1393871757,
    1475663582,
    1112554388,
    2143833701,
    1411063506,
    1652366673,
    3319133609,
    1742909262,
    2101820085,
    2530212464,
    1981530844,
    2828405876,
    2341894106,
    990771536,
    2676807387,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    3491521980,
    1393871794,
    1475663539,
    1112554471,
    2143833687,
    1411063540,
    1652366611,
    3319133637,
    1742909205,
    2101820033,
    2530212423,
    1981530764,
    2828405812,
    2341894046,
    990771465,
    2676807405,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
