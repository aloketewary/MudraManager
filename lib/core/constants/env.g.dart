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
    3738979932,
    2799680621,
    524233,
    3444373740,
    4200099164,
    3697178331,
    3959928033,
    764704281,
    2711930089,
    1434352176,
    122122146,
    491606771,
    1676276557,
    1692337701,
    1391139510,
    1942492506,
    4227974902,
    438744603,
    2257907063,
    4256145538,
    1273046937,
    4021882916,
    3849637133,
    779399244,
    795360064,
    1244921238,
    3988948050,
    2657965473,
    2904285945,
    481063089,
    1308642339,
    3595898959,
  ];

  static const List<int> _envieddataencryptKey = <int>[
    3738979868,
    2799680577,
    524182,
    3444373648,
    4200099099,
    3697178295,
    3959928031,
    764704375,
    2711930045,
    1434352233,
    122122235,
    491606749,
    1676276518,
    1692337778,
    1391139534,
    1942492462,
    4227974792,
    438744645,
    2257906958,
    4256145633,
    1273047022,
    4021883006,
    3849637187,
    779399170,
    795360101,
    1244921271,
    3988947988,
    2657965469,
    2904285906,
    481063056,
    1308642316,
    3595898916,
  ];

  static final String encryptKey = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptKey.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptKey[i] ^ _enviedkeyencryptKey[i]),
  );

  static const List<int> _enviedkeyencryptIv = <int>[
    3889297153,
    3309131664,
    2383871867,
    4198425721,
    2771278419,
    314841219,
    855446886,
    3642590451,
    87193248,
    3791599924,
    706551923,
    2204328753,
    575271618,
    1564289178,
    1027437279,
    153163760,
  ];

  static const List<int> _envieddataencryptIv = <int>[
    3889297208,
    3309131695,
    2383871766,
    4198425610,
    2771278433,
    314841253,
    855446820,
    3642590367,
    87193339,
    3791599872,
    706551876,
    2204328801,
    575271554,
    1564289246,
    1027437190,
    153163718,
  ];

  static final String encryptIv = String.fromCharCodes(
    List<int>.generate(
      _envieddataencryptIv.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataencryptIv[i] ^ _enviedkeyencryptIv[i]),
  );
}
