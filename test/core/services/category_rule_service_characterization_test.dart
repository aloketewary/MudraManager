import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStorage = <String, String>{};
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      final arguments = call.arguments as Map<dynamic, dynamic>?;
      final key = arguments?['key'] as String?;
      switch (call.method) {
        case 'read':
          return key == null ? null : secureStorage[key];
        case 'write':
          if (key != null) {
            secureStorage[key] = arguments?['value'] as String? ?? '';
          }
          return null;
        case 'delete':
          if (key != null) secureStorage.remove(key);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'readAll':
          return secureStorage;
        case 'containsKey':
          return key != null && secureStorage.containsKey(key);
        default:
          throw MissingPluginException('Unsupported method ${call.method}');
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  late Directory tempDirectory;
  late Isar isar;
  late CategoryRuleService service;

  setUp(() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    tempDirectory = await Directory.systemTemp.createTemp(
      'category_rule_service_characterization_',
    );
    isar = await Isar.open(
      [CategoryRuleSchema],
      directory: tempDirectory.path,
    );
    service = CategoryRuleService(isar);
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  TransactionInfo transaction({String recipient = 'Vendor'}) {
    return TransactionInfo(
      address: '',
      sender: '',
      body: 'Payment to $recipient',
      account: AccountDetails(sendTo: recipient, no: '1234'),
      money: '100',
    );
  }

  group('CategoryRuleService persistence baseline', () {
    test(
        'reads persisted rules and writes learned rule inside Isar transaction',
        () async {
      await service.learnFromCategorization(
        transaction(),
        'category-a',
      );

      final persisted = (await service.getAllRules()).single;
      expect(persisted.recipientName, 'vendor');
      expect(persisted.categoryId, 'category-a');
      expect(persisted.matchCount, 1);

      // Default confidence 50 qualifies learned matching (> 40 threshold).
      expect(
        await service.suggestCategory(transaction()),
        'category-a',
      );
    });

    test('round-trips encrypted fields through service read and write',
        () async {
      await FieldEncryptionService.initialize();
      expect(FieldEncryptionService.isReady, isTrue);

      final seeded = CategoryRule(
        recipientName: 'vendor',
        merchantName: 'merchant',
        accountNumber: '1234',
        amountMin: 10,
        amountMax: 200,
        categoryId: 'category-a',
        matchCount: 4,
        confidence: 80,
      )..lastUsed = DateTime(2024, 1, 1);
      seeded.encryptFields();

      await isar.writeTxn(() async {
        await isar.categoryRules.put(seeded);
      });

      final rawBeforeRead = (await isar.categoryRules.where().findAll()).single;
      expect(
        FieldEncryptionService.isEncrypted(rawBeforeRead.recipientName),
        isTrue,
      );
      expect(
        FieldEncryptionService.isEncrypted(rawBeforeRead.merchantName),
        isTrue,
      );
      expect(
        FieldEncryptionService.isEncrypted(rawBeforeRead.accountNumber),
        isTrue,
      );

      final txn = transaction(recipient: '  VENDOR  ');
      expect(await service.suggestCategory(txn), 'category-a');

      final decrypted = (await service.getAllRules()).single;
      expect(decrypted.recipientName, 'vendor');
      expect(decrypted.merchantName, 'merchant');
      expect(decrypted.accountNumber, '1234');

      await service.learnFromCategorization(txn, 'category-b');

      final rawAfterWrite = (await isar.categoryRules.where().findAll()).single;
      expect(rawAfterWrite.id, seeded.id);
      expect(rawAfterWrite.categoryId, 'category-b');
      expect(rawAfterWrite.matchCount, 5);
      expect(rawAfterWrite.confidence, 90);
      expect(rawAfterWrite.amountMin, 10);
      expect(rawAfterWrite.amountMax, 200);
      expect(
        FieldEncryptionService.isEncrypted(rawAfterWrite.recipientName),
        isTrue,
      );
      expect(
        FieldEncryptionService.isEncrypted(rawAfterWrite.merchantName),
        isTrue,
      );
      expect(
        FieldEncryptionService.isEncrypted(rawAfterWrite.accountNumber),
        isTrue,
      );

      final decryptedAfterWrite = (await service.getAllRules()).single;
      expect(decryptedAfterWrite.recipientName, 'vendor');
      expect(decryptedAfterWrite.merchantName, 'merchant');
      expect(decryptedAfterWrite.accountNumber, '1234');
      expect(await service.suggestCategory(txn), 'category-b');
    });

    test(
        'reads encrypted persisted fields before matching after reopening Isar',
        () async {
      await FieldEncryptionService.initialize();
      expect(FieldEncryptionService.isReady, isTrue);

      await service.learnFromCategorization(
        transaction(recipient: '  REOPENED VENDOR  '),
        'category-a',
      );
      final databasePath = tempDirectory.path;
      await isar.close();
      isar = await Isar.open(
        [CategoryRuleSchema],
        directory: databasePath,
      );
      service = CategoryRuleService(isar);

      final raw = (await isar.categoryRules.where().findAll()).single;
      expect(FieldEncryptionService.isEncrypted(raw.recipientName), isTrue);
      expect(
        await service.suggestCategory(
          transaction(recipient: 'reopened vendor'),
        ),
        'category-a',
      );
      expect(
        (await service.getAllRules()).single.recipientName,
        'reopened vendor',
      );
    });

    test('propagates persistence failure after encrypted upsert', () async {
      await FieldEncryptionService.initialize();
      expect(FieldEncryptionService.isReady, isTrue);
      await isar.close();

      await expectLater(
        service.learnFromCategorization(transaction(), 'category-a'),
        throwsA(isA<Object>()),
      );
    });

    test('updates matching rule while retaining ranking metadata', () async {
      final existing = CategoryRule(
        recipientName: 'Vendor',
        accountNumber: '1234',
        categoryId: 'category-a',
        matchCount: 4,
        confidence: 80,
      );
      await isar.writeTxn(() async {
        await isar.categoryRules.put(existing);
      });
      final originalLastUsed = existing.lastUsed;

      await service.learnFromCategorization(
        transaction(),
        'category-b',
      );

      final persisted = (await isar.categoryRules.where().findAll()).single;
      expect(persisted.id, existing.id);
      expect(persisted.categoryId, 'category-b');
      expect(persisted.matchCount, 5);
      expect(persisted.confidence, 90);
      expect(
        persisted.lastUsed.isAfter(originalLastUsed) ||
            persisted.lastUsed.isAtSameMomentAs(originalLastUsed),
        isTrue,
      );
    });
    test('updates normalized identity variants without creating duplicates',
        () async {
      await service.learnFromCategorization(
        transaction(recipient: '  VENDOR  '),
        'category-a',
      );
      await service.learnFromCategorization(
        transaction(recipient: 'vendor'),
        'category-b',
      );

      final persisted = (await service.getAllRules()).single;
      expect(persisted.recipientName, 'vendor');
      expect(persisted.categoryId, 'category-b');
      expect(persisted.matchCount, 2);
    });

    test('forwards available category IDs to shared matcher', () async {
      await service.learnFromCategorization(
        transaction(),
        'category-a',
      );

      expect(
        await service.suggestCategory(
          transaction(),
          availableCategoryIds: {'category-other'},
        ),
        isNull,
      );
      expect(
        await service.suggestCategory(
          transaction(),
          availableCategoryIds: {'category-a'},
        ),
        'category-a',
      );
    });

    test('retains account and amount evidence during category correction',
        () async {
      final existing = CategoryRule(
        recipientName: ' Vendor ',
        merchantName: ' Legacy Merchant ',
        accountNumber: ' 1234 ',
        amountMin: 10,
        amountMax: 200,
        categoryId: 'category-a',
        matchCount: 6,
        confidence: 95,
      );
      await isar.writeTxn(() async {
        await isar.categoryRules.put(existing);
      });

      await service.learnFromCategorization(
        transaction(),
        'category-c',
      );

      final persisted = (await service.getAllRules()).single;
      expect(persisted.id, existing.id);
      expect(persisted.categoryId, 'category-c');
      expect(persisted.matchCount, 7);
      expect(persisted.confidence, 100);
      expect(persisted.accountNumber, ' 1234 ');
      expect(persisted.amountMin, 10);
      expect(persisted.amountMax, 200);
      expect(persisted.merchantName, ' Legacy Merchant ');
    });

    test('propagates database failures from learning', () async {
      await isar.close();

      await expectLater(
        service.learnFromCategorization(transaction(), 'category-a'),
        throwsA(isA<Object>()),
      );
    });
  });
}
