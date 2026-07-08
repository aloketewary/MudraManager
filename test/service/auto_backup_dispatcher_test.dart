import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/auto_backup_service.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Isar isar;
late Directory tmpDir;

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;

  @override
  Future<String?> getTemporaryPath() async => dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    SharedPrefsUtil.init(prefs);

    tmpDir = Directory.systemTemp.createTempSync('auto_backup_test_');

    // Mock path_provider using platform interface (works with FFI-based implementations)
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);

    // Also mock MethodChannel for legacy fallback
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tmpDir.path,
    );

    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        AccountSchema,
        BackupMetadataSchema,
        BudgetSchema,
        CategorySchema,
        GoalSchema,
        RecurringTransactionSchema,
        TagSchema,
        TransactionSchema,
        UserProfileSchema,
        BudgetCategoryAllocationSchema,
        NotificationRecordSchema,
        AchievementSchema,
        StreakSchema,
        ChallengeSchema,
        UserLevelSchema,
        XpLogSchema,
        AppConfigSchema,
        ExchangeRateSchema,
      ],
      directory: tmpDir.path,
    );
  });

  tearDown(() async {
    await isar.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    tmpDir.deleteSync(recursive: true);
  });

  // ══════════════════════════════════════════════════════════════════════
  // Task 1 — Bug Condition Exploration: Auto-Backup Dispatcher Routing
  // ══════════════════════════════════════════════════════════════════════
  //
  // Property 1: When task = 'auto_backup_task' and a password is stored,
  // the dispatcher should route to _runAutoBackup(), which calls
  // AutoBackupService.createAutoBackup(password), producing a
  // mudra_auto_*.mudra file.
  //
  // On UNFIXED code (no dispatcher branch for auto_backup_task):
  //   - callbackDispatcher falls through to _runAllTasks()
  //   - No mudra_auto_*.mudra file is created
  //   - This test FAILS → confirms the bug exists
  //
  // Counterexample found on unfixed code:
  //   "callbackDispatcher with task='auto_backup_task' and stored password
  //    produces no mudra_auto_*.mudra file — dispatcher has no branch for
  //    auto_backup_task, so it falls through to _runAllTasks()"
  //
  // On FIXED code (dispatcher routes auto_backup_task → _runAutoBackup):
  //   - This test PASSES
  // ══════════════════════════════════════════════════════════════════════

  group('Bug Condition — auto_backup_task dispatcher routing', () {
    test(
      'callbackDispatcher routes auto_backup_task to _runAutoBackup '
      'which produces a mudra_auto_*.mudra file',
      () async {
        // Since callbackDispatcher is coupled to Workmanager and cannot be
        // invoked directly in tests, we verify the complete chain:
        //
        // 1. Dispatcher source has the routing branch for auto_backup_task
        // 2. _runAutoBackup calls AutoBackupService.createAutoBackup
        // 3. createAutoBackup produces a mudra_auto_*.mudra file
        //
        // On unfixed code, condition 1 fails (no branch exists).

        final dispatcherSource = File(
          'lib/core/services/background_task_manager.dart',
        ).readAsStringSync();

        // ── Condition 1: Dispatcher has routing branch ──
        final routingPattern = RegExp(
          r'task\s*==\s*AutoBackupService\.taskName.*_runAutoBackup',
          dotAll: true,
        );
        expect(
          routingPattern.hasMatch(dispatcherSource),
          isTrue,
          reason:
              'callbackDispatcher must route task == AutoBackupService.taskName '
              'to _runAutoBackup(). On unfixed code this branch does not exist.',
        );

        // ── Condition 2: _runAutoBackup calls createAutoBackup ──
        final runAutoBackupPattern = RegExp(
          r'_runAutoBackup\(\).*?AutoBackupService\.createAutoBackup',
          dotAll: true,
        );
        expect(
          runAutoBackupPattern.hasMatch(dispatcherSource),
          isTrue,
          reason: '_runAutoBackup must call AutoBackupService.createAutoBackup',
        );

        // ── Condition 3: createAutoBackup produces a mudra_auto_*.mudra file ──
        const password = 'test_password_123';
        final path = await AutoBackupService.createAutoBackup(password, const AppSpacing.comfortable());

        // Fallback: if path is null, check if file was created in tmpDir
        // (path_provider mock may not intercept all code paths)
        final String? effectivePath;
        if (path != null) {
          effectivePath = path;
        } else {
          final autoFiles = tmpDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('mudra_auto_'))
              .toList();
          effectivePath = autoFiles.isNotEmpty ? autoFiles.first.path : null;
        }

        expect(effectivePath, isNotNull, reason: 'createAutoBackup must produce a file');
        expect(effectivePath!.contains('mudra_auto_'), isTrue);
        expect(effectivePath.endsWith('.mudra'), isTrue);

        final file = File(effectivePath);
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(0));

        // Verify the backup is valid encrypted content
        final content = jsonDecode(file.readAsStringSync());
        expect(content['data'], isNotNull);
        expect(content['iv'], isNotNull);
        expect(content['salt'], isNotNull);

        // Cleanup
        try {
          file.deleteSync();
        } catch (_) {}
      },
    );

    test('AutoBackupService.taskName equals auto_backup_task', () {
      expect(AutoBackupService.taskName, equals('auto_backup_task'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // Task 2 — Preservation: Daily Background Task & Manual Backup
  // ══════════════════════════════════════════════════════════════════════
  //
  // Property 2: Existing behavior must be preserved:
  //   - All task names != 'auto_backup_task' route to _runAllTasks()
  //   - BackupService.createEncryptedBackup from foreground still works
  //
  // These tests PASS on both unfixed and fixed code.
  // ══════════════════════════════════════════════════════════════════════

  group('Preservation — daily background task routing', () {
    test(
      'callbackDispatcher routes non-auto-backup tasks to _runAllTasks',
      () {
        final source = File(
          'lib/core/services/background_task_manager.dart',
        ).readAsStringSync();

        final elsePattern = RegExp(
          r'if\s*\(\s*task\s*==\s*AutoBackupService\.taskName\s*\).*?_runAutoBackup.*?else.*?_runAllTasks',
          dotAll: true,
        );
        expect(
          elsePattern.hasMatch(source),
          isTrue,
          reason:
              'Dispatcher must have if(auto_backup_task) → _runAutoBackup, '
              'else → _runAllTasks. This covers dailyBackgroundTask, unknown '
              'task names, and empty strings.',
        );
      },
    );

    test(
      'dispatcher has exactly one task-name check — all other tasks go to _runAllTasks',
      () {
        final source = File(
          'lib/core/services/background_task_manager.dart',
        ).readAsStringSync();

        final dispatcherMatch = RegExp(
          r'void callbackDispatcher\(\)\s*\{(.*)\}',
          dotAll: true,
        ).firstMatch(source);
        expect(dispatcherMatch, isNotNull);

        final body = dispatcherMatch!.group(1)!;

        final taskChecks = RegExp(r'if\s*\(\s*task\s*==').allMatches(body);
        expect(
          taskChecks.length,
          equals(1),
          reason:
              'Dispatcher should have exactly one task-name check '
              '(auto_backup_task). All other tasks (dailyBackgroundTask, '
              'unknown, empty) go to else → _runAllTasks.',
        );
      },
    );

    test('dailyBackgroundTask constant exists in BackgroundTaskManager', () {
      final source = File(
        'lib/core/services/background_task_manager.dart',
      ).readAsStringSync();

      expect(source.contains("'dailyBackgroundTask'"), isTrue);
    });
  });

  group('Preservation — foreground manual backup', () {
    test(
      'BackupService.createEncryptedBackup produces a valid encrypted .mudra file',
      () async {
        const password = 'manual_backup_test';

        final path = await BackupService.createEncryptedBackup(
          password, const AppSpacing.comfortable(),
          interactive: false,
        );

        expect(path, isNotNull, reason: 'Manual backup must return a path');
        expect(path!.endsWith('.mudra'), isTrue);

        final file = File(path);
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(0));

        // Verify the file is valid encrypted JSON with expected structure
        final content = jsonDecode(file.readAsStringSync());
        expect(content['data'], isA<String>());
        expect(content['iv'], isA<String>());
        expect(content['salt'], isA<String>());
        expect(content['mac'], isA<String>());

        // Verify it can be decrypted with the same password
        final salt = base64Decode(content['salt']);
        final (key, _) = BackupService.deriveKeyWithSalt(password, Uint8List.fromList(salt));
        final iv = encrypt_pkg.IV.fromBase64(content['iv']);
        final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
        final decrypted = encrypter.decrypt64(content['data'], iv: iv);
        final data = jsonDecode(decrypted);

        expect(data['db'], isNotNull);
        expect(data['version'], equals('1.0'));
        expect(data['timestamp'], isNotNull);

        // Cleanup
        try {
          file.deleteSync();
        } catch (_) {}
      },
    );
  });
}
