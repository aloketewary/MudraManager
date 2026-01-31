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
    198022958,
    1778281329,
    94631901,
    3232899383,
    1746125604,
    3452453115,
    1959921327,
    4126026211,
    1573648660,
    4112778814,
    2426797104,
    1168270044,
    148231389,
    2859384922,
    1075493109,
    3076533069,
    3201248381,
    2142119586,
    4167864917,
    1057376237,
    1304090867,
    1107781977,
    4053869643,
    4100712548,
    1799940073,
    3100150798,
    1224196760,
    3045713002,
    226855785,
    1075008273,
    1461702383,
    3912040152,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    198023022,
    1778281309,
    94631810,
    3232899403,
    1746125667,
    3452453015,
    1959921297,
    4126026125,
    1573648704,
    4112778855,
    2426797161,
    1168270066,
    148231350,
    2859384845,
    1075493005,
    3076533049,
    3201248259,
    2142119676,
    4167864876,
    1057376142,
    1304090756,
    1107781891,
    4053869573,
    4100712490,
    1799940044,
    3100150831,
    1224196830,
    3045712982,
    226855746,
    1075008304,
    1461702336,
    3912040115,
  ];

  static final String encryptKey = String.fromCharCodes(List<int>.generate(
    _envieddataencryptKey.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]));

  static const List<int> _enviedkeyencryptIv = <int>[
    3785304422,
    208286154,
    1389624023,
    366547599,
    2751545863,
    3562645772,
    290832821,
    1619562890,
    143912585,
    2832381402,
    1351942654,
    2802779748,
    2641343822,
    1121705199,
    2212349530,
    2825894382,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    3785304415,
    208286197,
    1389623994,
    366547708,
    2751545909,
    3562645802,
    290832887,
    1619562982,
    143912658,
    2832381422,
    1351942601,
    2802779700,
    2641343758,
    1121705131,
    2212349443,
    2825894360,
  ];

  static final String encryptIv = String.fromCharCodes(List<int>.generate(
    _envieddataencryptIv.length,
    (int i) => i,
    growable: false,
  ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]));
}
