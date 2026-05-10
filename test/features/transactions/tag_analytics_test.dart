import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockIsarService extends IsarService {
  final Isar isar;
  MockIsarService(this.isar);

  @override
  Future<Isar> getInstance() async => isar;
}

void main() {
  late Isar isar;
  late ProviderContainer container;
  late Directory tmpDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tmpDir = Directory.systemTemp.createTempSync('tag_analytics_test_');

    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        TransactionSchema,
        CategorySchema,
        AccountSchema,
        TagSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
        TripSchema,
        TripParticipantSchema,
        TripTransactionSchema,
        SplitExpenseSchema,
        SettlementSchema,
      ],
      directory: tmpDir.path,
    );

    container = ProviderContainer(
      overrides: [
        isarServiceProvider.overrideWithValue(MockIsarService(isar)),
      ],
    );
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
    container.dispose();
  });

  test('tagSpendingProvider aggregates spending correctly', () async {
    final tag1 = Tag()..name = 'Tag1';
    final tag2 = Tag()..name = 'Tag2';

    await isar.writeTxn(() async {
      await isar.tags.putAll([tag1, tag2]);
    });

    final tx1 = Transaction.create(
      date: DateTime.now(),
      amount: 100,
      isExpense: true,
    );
    final tx2 = Transaction.create(
      date: DateTime.now(),
      amount: 200,
      isExpense: true,
    );
    final tx3 = Transaction.create(
      date: DateTime.now(),
      amount: 300,
      isExpense: false, // Income should be ignored
    );

    await isar.writeTxn(() async {
      await isar.transactions.putAll([tx1, tx2, tx3]);
      tx1.tags.add(tag1);
      tx2.tags.addAll([tag1, tag2]);
      tx3.tags.add(tag2);
      await tx1.tags.save();
      await tx2.tags.save();
      await tx3.tags.save();
    });

    final result = await container.read(tagSpendingProvider('Month').future);

    expect(result.length, 2);

    final tag1Spending = result.firstWhere((s) => s.tag.id == tag1.id);
    expect(tag1Spending.amount, 300); // 100 + 200
    expect(tag1Spending.count, 2);

    final tag2Spending = result.firstWhere((s) => s.tag.id == tag2.id);
    expect(tag2Spending.amount, 200); // Only tx2
    expect(tag2Spending.count, 1);
  });

  test('tagSpendingProvider handles empty transactions', () async {
    final result = await container.read(tagSpendingProvider('Month').future);
    expect(result, isEmpty);
  });
}
