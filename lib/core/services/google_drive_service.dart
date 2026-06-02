import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:mudra_manager/core/constants/env.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/state_value.dart';

/// Google Drive backup service using appDataFolder (hidden, app-private).
class GoogleDriveService {
  static final _log = AppLog(getLogger(), 'GoogleDrive');
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  static bool _initialized = false;
  static GoogleSignInAccount? _account;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final clientId = Env.googleServerClientId;
    _log.i('Initializing GoogleSignIn, serverClientId: ${clientId.isNotEmpty ? '${clientId.substring(0, 8)}...' : 'EMPTY'}');
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: clientId.isNotEmpty ? clientId : null,
      );
    } catch (e) {
      _log.w('Initialize with serverClientId failed, retrying without: $e');
      await GoogleSignIn.instance.initialize();
    }
    _initialized = true;
  }

  /// Authenticate and authorize Drive appdata scope.
  static Future<bool> signIn() async {
    try {
      _initialized = false;
      await _ensureInitialized();
      _log.i('Attempting authenticate...');
      _account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      _log.i('Authenticated: ${_account!.email}, authorizing scopes...');
      await _account!.authorizationClient.authorizeScopes(_scopes);
      _log.i('Signed in and authorized: ${_account!.email}');
      return true;
    } on GoogleSignInException catch (e) {
      _log.e('Sign-in failed: code=${e.code}, desc=${e.description}');
      _account = null;
      return false;
    } catch (e, st) {
      _log.e('Sign-in failed unexpectedly', e, st);
      _account = null;
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    _account = null;
    _log.i('Signed out');
  }

  static bool get isSignedIn => _account != null;
  static String? get userEmail => _account?.email;

  static Future<drive.DriveApi?> _getDriveApi() async {
    if (_account == null) return null;
    final headers = await _account!.authorizationClient.authorizationHeaders(
      _scopes,
    );
    if (headers == null) return null;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  /// Upload an encrypted .mudra backup file to appDataFolder.
  static Future<bool> uploadBackup(String localPath) async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      final file = File(localPath);
      if (!file.existsSync()) return false;

      final fileName = localPath.split('/').last;
      final fileSize = file.lengthSync();

      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/octet-stream';

      await api.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), fileSize),
      );

      _log.i('Uploaded: $fileName ($fileSize bytes)');
      return true;
    } catch (e) {
      _log.e('Upload failed', e);
      return false;
    }
  }

  /// List all .mudra backup files in appDataFolder.
  static Future<List<DriveBackupInfo>> listBackups() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return [];

      final result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name contains '.mudra'",
        orderBy: 'modifiedTime desc',
        $fields: 'files(id, name, size, modifiedTime)',
        pageSize: 20,
      );

      return (result.files ?? []).map((f) => DriveBackupInfo(
            id: f.id ?? '',
            name: f.name ?? 'unknown',
            size: int.tryParse(f.size ?? '0') ?? 0,
            date: f.modifiedTime ?? DateTime.now(),
          ),).toList();
    } catch (e) {
      _log.e('List failed', e);
      return [];
    }
  }

  /// Download a backup file from Drive to a temp path.
  static Future<String?> downloadBackup(String fileId) async {
    try {
      final api = await _getDriveApi();
      if (api == null) return null;

      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await Directory.systemTemp.createTemp('mudra_restore_');
      final tempFile = File('${tempDir.path}/restore.mudra');
      final sink = tempFile.openWrite();
      await for (final chunk in media.stream) {
        sink.add(chunk);
      }
      await sink.close();

      _log.i('Downloaded: ${tempFile.path}');
      return tempFile.path;
    } catch (e) {
      _log.e('Download failed', e);
      return null;
    }
  }

  /// Delete a backup file from Drive.
  static Future<bool> deleteBackup(String fileId) async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;
      await api.files.delete(fileId);
      _log.i('Deleted: $fileId');
      return true;
    } catch (e) {
      _log.e('Delete failed', e);
      return false;
    }
  }
}

class DriveBackupInfo {
  final String id;
  final String name;
  final int size;
  final DateTime date;

  DriveBackupInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
  });
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

// Riverpod providers

final driveSignedInProvider = NotifierProvider<StateValue<bool>, bool>(
  () => StateValue(GoogleDriveService.isSignedIn),
);

final driveEmailProvider = NotifierProvider<StateValue<String?>, String?>(
  () => StateValue(GoogleDriveService.userEmail),
);

final driveBackupsProvider =
    FutureProvider.autoDispose<List<DriveBackupInfo>>((ref) async {
  if (!GoogleDriveService.isSignedIn) return [];
  return GoogleDriveService.listBackups();
});
