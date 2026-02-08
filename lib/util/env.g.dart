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
    329893142,
    1417201946,
    1274205438,
    229106945,
    1640150785,
    1213890844,
    4224223650,
    3577231579,
    2301136191,
    2316282680,
    2875322625,
    1263205666,
    1201257338,
    1861661349,
    3766706109,
    3696371678,
    2306028098,
    1077310935,
    3126234231,
    3731047228,
    2525366886,
    2486532364,
    2657994311,
    2509248643,
    2831456701,
    1213009356,
    4281270694,
    1436413764,
    3208621801,
    2500646344,
    3884550985,
    2642057281,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    329893206,
    1417201974,
    1274205345,
    229107069,
    1640150854,
    1213890928,
    4224223644,
    3577231541,
    2301136235,
    2316282721,
    2875322712,
    1263205644,
    1201257233,
    1861661426,
    3766706117,
    3696371626,
    2306028092,
    1077310857,
    3126234126,
    3731047263,
    2525366801,
    2486532438,
    2657994249,
    2509248717,
    2831456664,
    1213009389,
    4281270752,
    1436413816,
    3208621762,
    2500646377,
    3884551014,
    2642057258,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    2100272515,
    3461492774,
    4149258019,
    4051743683,
    3554009562,
    445195885,
    1085650956,
    4006664112,
    2352805346,
    2482604344,
    417270235,
    4130949670,
    3233286166,
    2139646155,
    3455684470,
    695632020,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    2100272570,
    3461492761,
    4149258062,
    4051743664,
    3554009576,
    445195851,
    1085651022,
    4006664156,
    2352805305,
    2482604300,
    417270252,
    4130949750,
    3233286230,
    2139646095,
    3455684399,
    695632034,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
