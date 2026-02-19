import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/backup/data/account_backup.dart';
import 'package:mudra_manager/features/backup/data/budget_backup.dart';
import 'package:mudra_manager/features/backup/data/budget_category_allocation_backup.dart';
import 'package:mudra_manager/features/backup/data/category_backup.dart';
import 'package:mudra_manager/features/backup/data/goal_backup.dart';
import 'package:mudra_manager/features/backup/data/notification_backup.dart';
import 'package:mudra_manager/features/backup/data/pending_transaction_backup.dart';
import 'package:mudra_manager/features/backup/data/recurring_transaction_backup.dart';
import 'package:mudra_manager/features/backup/data/tag_backup.dart';
import 'package:mudra_manager/features/backup/data/transaction_backup.dart';
import 'package:mudra_manager/features/backup/data/user_profile_backup.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const _backupFileName = 'mudra_backup';
  static const _backupFileNameExtension = '.mudra';
  static final _log = AppLog(getLogger(), 'BackupService');

  /// Create encrypted backup with password
  static Future<String?> createEncryptedBackup(
    String password, {
    bool includeAttachments = true,
  }) async {
    final isar = Isar.getInstance();
    if (isar == null) return null;

    final dbData = await exportAll(isar);
    final settings = await SharedPrefsUtil.instance.exportAll();
    final recordCount = dbData.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    final content = jsonEncode({
      'db': dbData,
      'settings': settings,
      'includeAttachments': includeAttachments,
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
    });

    final key = _deriveKey(password);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(content, iv: iv);

    final hash = sha256.convert(utf8.encode(content)).toString();
    final finalData = jsonEncode({
      'data': encrypted.base64,
      'iv': iv.base64,
      'hash': hash,
    });

    final dateTime = DateTime.now();
    final filePath = await saveBackupFile(utf8.encode(finalData), dateTime);

    if (filePath != null) {
      final fileSize = File(filePath).lengthSync();
      await _saveBackupMetadata(
        isar,
        dateTime,
        fileSize,
        filePath,
        includeAttachments,
        recordCount,
      );
      await SharedPrefsUtil.instance.saveBackupDate(dateTime);
      _log.i('Backup created: $filePath ($recordCount records)');
    }

    return filePath;
  }

  /// Restore backup with password
  static Future<String?> restoreEncryptedBackup(
    BuildContext context,
    Isar isar,
    String password,
  ) async {
    await FilePicker.platform.clearTemporaryFiles();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      dialogTitle: 'Select Backup File',
    );

    if (result == null || result.files.single.path == null) return null;
    if (result.files.first.extension != 'mudra') {
      SnackbarService.error('Invalid file type, select `.mudra` file');
      return null;
    }

    try {
      final selectedFile = File(result.files.single.path!);
      final fileContent = await selectedFile.readAsString();
      final backupData = jsonDecode(fileContent);

      final key = _deriveKey(password);
      final iv = encrypt.IV.fromBase64(backupData['iv']);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decrypt64(backupData['data'], iv: iv);
      final data = jsonDecode(decrypted);

      final hash = sha256.convert(utf8.encode(decrypted)).toString();
      if (hash != backupData['hash']) {
        SnackbarService.error('Backup file corrupted or tampered');
        return null;
      }

      if (data['db'] != null) {
        await performRestore(isar, data['db']);
      }
      if (data['settings'] != null) {
        await SharedPrefsUtil.instance.importAll(data['settings']);
      }

      _log.i('Backup restored successfully');
      return 'success';
    } catch (e) {
      _log.e('Restore failed', e);
      SnackbarService.error('Invalid password or corrupted file');
      return null;
    }
  }

  static encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  static Future<void> _saveBackupMetadata(
    Isar isar,
    DateTime date,
    int size,
    String path,
    bool includesAttachments,
    int recordCount,
  ) async {
    final metadata = BackupMetadata.create(
      backupDate: date,
      fileSize: size,
      fileName: path.split('/').last,
      filePath: path,
      includesAttachments: includesAttachments,
      recordCount: recordCount,
    );
    await isar.writeTxn(() => isar.backupMetadatas.put(metadata));
  }

  static Future<List<BackupMetadata>> getBackupHistory() async {
    final isar = Isar.getInstance();
    if (isar == null) return [];
    return await isar.backupMetadatas.where().sortByBackupDateDesc().findAll();
  }

  static Future<BackupMetadata?> getLastBackup() async {
    final isar = Isar.getInstance();
    if (isar == null) return null;
    return await isar.backupMetadatas
        .where()
        .sortByBackupDateDesc()
        .findFirst();
  }

  static Future<Map<String, List<Map<String, dynamic>>>> exportAll(
    Isar isar,
  ) async {
    final backupData = <String, List<Map<String, dynamic>>>{};

    // Backup Accounts
    final accounts = await isar.accounts.where().findAll();
    backupData['Account'] = accounts
        .map((account) => AccountBackup.fromAccount(account).toBackupJson())
        .toList();

    // Backup Categories
    final categories = await isar.categorys.where().findAll();
    backupData['Category'] = categories
        .map((category) => CategoryBackup.fromCategory(category).toBackupJson())
        .toList();

    // Backup Tags
    final tags = await isar.tags.where().findAll();
    backupData['Tag'] = tags
        .map((tag) => TagBackup.fromTag(tag).toBackupJson())
        .toList();

    // Backup Recurring Transactions
    final recurringTransactions = await isar.recurringTransactions
        .where()
        .findAll();
    backupData['RecurringTransaction'] = recurringTransactions
        .map(
          (rt) => RecurringTransactionBackup.fromRecurringTransaction(
            rt,
          ).toBackupJson(),
        )
        .toList();

    // Backup Notification Records
    final notificationRecords = await isar.notificationRecords
        .where()
        .findAll();
    backupData['NotificationRecord'] = notificationRecords
        .map(
          (nr) => NotificationRecordBackup.fromNotificationRecord(
            nr,
          ).toBackupJson(),
        )
        .toList();

    // Backup Pending Transactions
    final pendingTransactions = await isar.pendingTransactions
        .where()
        .findAll();
    backupData['PendingTransaction'] = pendingTransactions
        .map(
          (pt) => PendingTransactionBackup.fromPendingTransaction(
            pt,
          ).toBackupJson(),
        )
        .toList();

    // Backup User Profiles (assuming you have this collection)
    final userProfiles = await isar.userProfiles.where().findAll();
    backupData['UserProfile'] = userProfiles
        .map((up) => UserProfileBackup.fromUserProfile(up).toBackupJson())
        .toList();

    // Backup Goals
    final goals = await isar.goals.where().findAll();
    backupData['Goal'] = goals
        .map((goal) => GoalBackup.fromGoal(goal).toBackupJson())
        .toList();

    // Backup Budgets
    final budgets = await isar.budgets.where().findAll();
    backupData['Budget'] = budgets
        .map((budget) => BudgetBackup.fromBudget(budget).toBackupJson())
        .toList();

    // Backup Budget Category Allocations
    final budgetCategoryAllocations = await isar.budgetCategoryAllocations
        .where()
        .findAll();
    backupData['BudgetCategoryAllocation'] = budgetCategoryAllocations
        .map(
          (bca) => BudgetCategoryAllocationBackup.fromBudgetCategoryAllocation(
            bca,
          ).toBackupJson(),
        )
        .toList();

    // Backup Transactions
    final transactions = await isar.transactions.where().findAll();
    backupData['Transaction'] = transactions
        .map((tx) => TransactionBackup.fromTransaction(tx).toBackupJson())
        .toList();

    _log.i('DB export completed: ${backupData.values.fold<int>(0, (sum, list) => sum + list.length)} records');
    return backupData;
  }

  static Future<void> performRestore(
    Isar isar,
    Map<String, dynamic> backupData,
  ) async {
    final restoredObjects = <String, Map<int, dynamic>>{};
    // --- First Pass: Deserialize basic objects ---
    for (final entry in backupData.entries) {
      final collectionName = entry.key;
      final List<dynamic> itemsJson = entry.value as List<dynamic>;
      final modelMap = <int, dynamic>{};
      for (final itemJson in itemsJson) {
        dynamic model;
        switch (collectionName) {
          case 'Account':
            model = AccountBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'Category':
            model = CategoryBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'Tag':
            model = TagBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'RecurringTransaction':
            model = RecurringTransactionBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'NotificationRecord':
            model = NotificationRecordBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'PendingTransaction':
            model = PendingTransactionBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'UserProfile':
            model = UserProfileBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'Goal':
            model = GoalBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'Budget':
            model = BudgetBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'BudgetCategoryAllocation':
            model = BudgetCategoryAllocationBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
          case 'Transaction':
            model = TransactionBackup().fromBackupJson(
              Map<String, dynamic>.from(itemJson),
              {},
            );
            break;
        }
        if (model != null && model.id != null) {
          modelMap[model.id as int] = model;
        }
      }
      restoredObjects[collectionName] = modelMap;
    }
    // --- Second Pass: Resolve links and save to Isar ---
    await isar.writeTxn(() async {
      for (final entry in backupData.entries) {
        final collectionName = entry.key;
        final List<dynamic> itemsJson = entry.value as List<dynamic>;
        final modelMap = restoredObjects[collectionName]!;
        for (final itemJson in itemsJson) {
          final id = itemJson['id'] as int?;
          final restoredModel = modelMap[id];
          if (restoredModel != null) {
            dynamic fullyLinkedModel;
            switch (collectionName) {
              case 'Account':
                fullyLinkedModel = AccountBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.accounts.put(fullyLinkedModel);
                break;
              case 'Category':
                fullyLinkedModel = CategoryBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.categorys.put(fullyLinkedModel);
                break;
              case 'Tag':
                fullyLinkedModel = TagBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.tags.put(fullyLinkedModel);
                break;
              case 'RecurringTransaction':
                final rt = RecurringTransactionBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.recurringTransactions.put(rt);
                await rt.category.save();
                await rt.account.save();
                fullyLinkedModel = rt;
                break;
              case 'NotificationRecord':
                fullyLinkedModel = NotificationRecordBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.notificationRecords.put(fullyLinkedModel);
                break;
              case 'PendingTransaction':
                fullyLinkedModel = PendingTransactionBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.pendingTransactions.put(fullyLinkedModel);
                break;
              case 'UserProfile':
                fullyLinkedModel = UserProfileBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.userProfiles.put(fullyLinkedModel);
                break;
              case 'Goal':
                final goal = GoalBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.goals.put(goal);
                await goal.linkedAccount.save();
                fullyLinkedModel = goal;
                break;
              case 'Budget':
                final budget = BudgetBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.budgets.put(budget);
                await budget.categories.save();
                await budget.allocations.save();
                fullyLinkedModel = budget;
                break;
              case 'BudgetCategoryAllocation':
                final bca = BudgetCategoryAllocationBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.budgetCategoryAllocations.put(bca);
                await bca.category.save();
                await bca.budget.save();
                fullyLinkedModel = bca;
                break;
              case 'Transaction':
                final tx = TransactionBackup().fromBackupJson(
                  Map<String, dynamic>.from(itemJson),
                  restoredObjects,
                );
                await isar.transactions.put(tx);
                await tx.account.save();
                await tx.category.save();
                await tx.recurringTransactionSource.save();
                await tx.related.save();
                await tx.tags.save();
                fullyLinkedModel = tx;
                break;
            }
          }
        }
      }
    });
    _log.i('Restore completed successfully');
  }

  static Future<Directory?> pickBackupFolder() async {
    final String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      return Directory(selectedDir);
    }
    return null;
  }

  static Future<String?> saveBackupFile(
    Uint8List content,
    DateTime dateTime,
  ) async {
    final userDir = await pickBackupFolder();
    final dir = await getApplicationDocumentsDirectory();
    final directory = userDir ?? dir;
    final fileName =
        '${_backupFileName}_${DateFormat('yyyyMMdd_HHmmss').format(dateTime)}$_backupFileNameExtension';
    final file = File('${directory.path}/$fileName');
    await file.create(recursive: true);
    await file.writeAsBytes(content);
    _log.d('Backup saved at ${file.path}');
    return file.path;
  }
}
