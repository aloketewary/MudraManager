import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(requireEnvFile: true)
abstract class Env {
  @EnviedField(varName: 'ENCRYPT_KEY', obfuscate: true)
  static String encryptKey = _Env.encryptKey;

  @EnviedField(varName: 'ENCRYPT_IV', obfuscate: true)
  static String encryptIv = _Env.encryptIv;

  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true, defaultValue: '')
  static String googleServerClientId = _Env.googleServerClientId;
}