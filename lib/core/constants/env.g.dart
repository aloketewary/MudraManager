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
    2491268387,
    1500102268,
    2090070164,
    3572358585,
    2162970391,
    2050814972,
    1199505176,
    630810932,
    1116081562,
    4101115886,
    3952218140,
    4198505213,
    1084075199,
    2734092887,
    3642037814,
    927491704,
    1701934711,
    2666176498,
    2617474644,
    2843428680,
    3192166113,
    832813598,
    4078639536,
    3846410058,
    2588341289,
    2934426583,
    1605060431,
    1166362754,
    1670788937,
    1234863090,
    4227553203,
    564105897,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    2491268451,
    1500102224,
    2090070219,
    3572358597,
    2162970448,
    2050814864,
    1199505190,
    630810970,
    1116081614,
    4101115831,
    3952218181,
    4198505171,
    1084075220,
    2734092800,
    3642037838,
    927491596,
    1701934601,
    2666176428,
    2617474605,
    2843428651,
    3192166038,
    832813636,
    4078639614,
    3846409988,
    2588341260,
    2934426614,
    1605060361,
    1166362814,
    1670788962,
    1234863059,
    4227553180,
    564105922,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    3082204649,
    90213082,
    4260660609,
    2618952009,
    1298199843,
    1242289384,
    506642011,
    3638921843,
    2772230820,
    1062953658,
    3220884262,
    1173873223,
    2425371473,
    1085233854,
    777556182,
    2310757506,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    3082204624,
    90213093,
    4260660716,
    2618951994,
    1298199825,
    1242289358,
    506641945,
    3638921759,
    2772230911,
    1062953614,
    3220884241,
    1173873175,
    2425371409,
    1085233914,
    777556111,
    2310757556,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
