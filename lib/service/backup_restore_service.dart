import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/budget.dart';
import 'package:mudra_manager/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category, GetCategoryCollection;
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/db/models/pending_transaction.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/db/models/tag.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/db/models/user_profile.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/util/env.dart' show Env;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  // Keys for Encryption
  static final encryptKey = encrypt.Key.fromUtf8(Env.encryptKey);
  static final encryptIv = encrypt.IV.fromUtf8(Env.encryptIv);
  static const _backupFileName = 'mudra_backup';
  static const _backupFileNameExtension = '.mudra';

  /// Encrypt and save backup
  static Future<void> createEncryptedBackup() async {
    var isar = Isar.getInstance();
    if (isar == null) return;
    final dbData = await exportAll(isar);
    final settings = await SharedPrefsUtil.instance.exportAll();
    final content = jsonEncode({'db': dbData, 'settings': settings});

    final encryptedData = encrypt.Encrypter(
      encrypt.AES(encryptKey),
    ).encrypt(content, iv: encryptIv);
    final encryptedBytes = encryptedData.bytes;

    var dateTime = DateTime.now();

    await saveBackupFile(encryptedBytes, dateTime);
    await SharedPrefsUtil.instance.saveBackupDate(dateTime);
  }

  /// Restore backup
  static Future<String?> restoreEncryptedBackup(BuildContext context) async {
    await FilePicker.platform.clearTemporaryFiles();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      dialogTitle: 'Select Backup File',
      // allowedExtensions: ['mudra'],
    );

    if (result == null || result.files.single.path == null) return null;
    if (result.files.first.extension != 'mudra') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid file type, select  `.mudra`  type file"),
        ),
      );
      return null;
    }
    final dir = await getApplicationDocumentsDirectory();
    final selectedFile = File(result.files.single.path!);
    final currentDbFile = File('${dir.path}/mm_temp.json');
    if (selectedFile.existsSync()) {
      final encryptedData = await selectedFile.readAsBytes();
      final decryptedData = encrypt.Encrypter(
        encrypt.AES(encryptKey),
      ).decryptBytes(encrypt.Encrypted(encryptedData), iv: encryptIv);
      await currentDbFile.writeAsBytes(decryptedData);
    }

    var isar = Isar.getInstance();
    if (isar == null) return null;

    final data = jsonDecode(currentDbFile.readAsStringSync());
    final dataMap = {'db': data['db'], 'settings': data['settings']};
    if (dataMap['db'] != null) {
      await importAll(isar, dataMap['db']);
    }
    if (dataMap['settings'] != null) {
      await SharedPrefsUtil.instance.importAll(dataMap['settings']);
    }
    return 'success';
  }

  static Future<Map<String, dynamic>> exportAll(Isar isar) async {
    return {
      'transactions':
          (await isar.transactions.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'accounts':
          (await isar.accounts.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'categorys':
          (await isar.categorys.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'budgets':
          (await isar.budgets.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'goals':
          (await isar.goals.where().findAll()).map((e) => e.toJson()).toList(),
      'recurringTransactions':
          (await isar.recurringTransactions.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'tags':
          (await isar.tags.where().findAll()).map((e) => e.toJson()).toList(),
      'userProfiles':
          (await isar.userProfiles.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'budgetCategoryAllocations':
          (await isar.budgetCategoryAllocations.where().findAll())
              .map((e) => e.toJson())
              .toList(),
      'pendingTransactions':
          (await isar.pendingTransactions.where().findAll())
              .map((e) => e.toJson())
              .toList(),
    };
  }

  static Future<void> importAll(Isar isar, Map<String, dynamic> json) async {
    await isar.writeTxn(() async {
      final txns =
          (json['transactions'] as List)
              .map((e) => Transaction.fromJson(e))
              .toList();
      final accounts =
          (json['accounts'] as List).map((e) => Account.fromJson(e)).toList();
      final categorys =
          (json['categorys'] as List).map((e) => Category.fromJson(e)).toList();
      final budgets =
          (json['budgets'] as List).map((e) => Budget.fromJson(e)).toList();
      final goals =
          (json['goals'] as List).map((e) => Goal.fromJson(e)).toList();
      final recurringTransactions =
          (json['recurringTransactions'] as List)
              .map((e) => RecurringTransaction.fromJson(e))
              .toList();
      final tags = (json['tags'] as List).map((e) => Tag.fromJson(e)).toList();
      final userProfiles =
          (json['userProfiles'] as List)
              .map((e) => UserProfile.fromJson(e))
              .toList();
      final budgetCategoryAllocations =
          (json['budgetCategoryAllocations'] as List)
              .map((e) => BudgetCategoryAllocation.fromJson(e))
              .toList();
      final pendingTransactions =
          (json['pendingTransactions'] as List)
              .map((e) => PendingTransaction.fromJson(e))
              .toList();

      await isar.transactions.clear();
      await isar.accounts.clear();
      await isar.categorys.clear();
      await isar.budgets.clear();
      await isar.goals.clear();
      await isar.recurringTransactions.clear();
      await isar.tags.clear();
      await isar.userProfiles.clear();
      await isar.budgetCategoryAllocations.clear();
      await isar.pendingTransactions.clear();

      await isar.transactions.putAll(txns);
      await isar.accounts.putAll(accounts);
      await isar.categorys.putAll(categorys);
      await isar.budgets.putAll(budgets);
      await isar.goals.putAll(goals);
      await isar.recurringTransactions.putAll(recurringTransactions);
      await isar.tags.putAll(tags);
      await isar.userProfiles.putAll(userProfiles);
      await isar.budgetCategoryAllocations.putAll(budgetCategoryAllocations);
      await isar.pendingTransactions.putAll(pendingTransactions);
    });
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static Future<Directory?> pickBackupFolder() async {
    final hasPermission = await requestStoragePermission();
    // if (!hasPermission) return null;

    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      return Directory(selectedDir);
    }
    return null;
  }

  static Future<void> saveBackupFile(
    Uint8List content,
    DateTime dateTime,
  ) async {
    final userDir = await pickBackupFolder();
    final dir = await getApplicationDocumentsDirectory();
    final directory = userDir ?? dir;
    final file = File(
      '${directory.path}/${_backupFileName}_${DateFormat('yyyyMMdd_HHmmss').format(dateTime)}$_backupFileNameExtension',
    );
    await file.create(recursive: true);
    await file.writeAsBytes(content);
    if (kDebugMode) {
      print("Backup saved at ${file.path}");
    }
  }
}
