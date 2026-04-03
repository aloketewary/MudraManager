import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class TagMatcherService {
  static const _merchantTagMap = <String, List<String>>{
    'swiggy': ['Food Delivery'],
    'zomato': ['Food Delivery'],
    'uber eats': ['Food Delivery'],
    'amazon': ['Online Shopping'],
    'flipkart': ['Online Shopping'],
    'myntra': ['Online Shopping'],
    'uber': ['Transport'],
    'ola': ['Transport'],
    'rapido': ['Transport'],
    'irctc': ['Travel'],
    'makemytrip': ['Travel'],
    'goibibo': ['Travel'],
    'cleartrip': ['Travel'],
    'netflix': ['Subscription'],
    'spotify': ['Subscription'],
    'hotstar': ['Subscription'],
    'prime': ['Subscription'],
    'youtube': ['Subscription'],
    'gpay': ['UPI'],
    'phonepe': ['UPI'],
    'paytm': ['UPI'],
    'bigbasket': ['Groceries'],
    'blinkit': ['Groceries'],
    'zepto': ['Groceries'],
    'instamart': ['Groceries'],
    'dmart': ['Groceries'],
    'petrol': ['Fuel'],
    'fuel': ['Fuel'],
    'iocl': ['Fuel'],
    'bpcl': ['Fuel'],
    'hpcl': ['Fuel'],
    'electricity': ['Bills'],
    'broadband': ['Bills'],
    'jio': ['Bills'],
    'airtel': ['Bills'],
    'vodafone': ['Bills'],
    'vi ': ['Bills'],
    'hospital': ['Medical'],
    'pharmacy': ['Medical'],
    'apollo': ['Medical'],
    'medplus': ['Medical'],
    'rent': ['Rent'],
    'emi': ['EMI'],
    'loan': ['EMI'],
  };

  /// Suggest tags for an SMS body by matching known merchant keywords.
  /// Returns existing Tag objects where possible, or creates new ones.
  static Future<List<Tag>> suggestTagsForSms(String smsBody) async {
    final bodyLower = smsBody.toLowerCase();
    final suggestedNames = <String>{};

    for (final entry in _merchantTagMap.entries) {
      if (bodyLower.contains(entry.key)) {
        suggestedNames.addAll(entry.value);
      }
    }

    if (suggestedNames.isEmpty) return [];

    final isar = await IsarService().getInstance();
    final result = <Tag>[];

    for (final name in suggestedNames) {
      // Try to find existing tag (case-insensitive)
      final existing = await isar.tags
          .filter()
          .nameEqualTo(name, caseSensitive: false)
          .findFirst();

      if (existing != null) {
        result.add(existing);
      } else {
        // Create the tag
        final tag = Tag()..name = name;
        await isar.writeTxn(() async {
          await isar.tags.put(tag);
        });
        result.add(tag);
      }
    }

    return result;
  }

  /// Suggest tags based on past transactions with similar descriptions.
  /// Looks at the most frequently used tags for transactions with matching keywords.
  static Future<List<Tag>> suggestTagsFromHistory(
    String description,
  ) async {
    if (description.isEmpty) return [];

    final isar = await IsarService().getInstance();
    final words = description.toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return [];

    // Find recent transactions with similar descriptions
    final recentTxns = await isar.transactions
        .where()
        .sortByDateDesc()
        .limit(500)
        .findAll();

    final tagFrequency = <int, int>{};
    final tagMap = <int, Tag>{};

    for (final txn in recentTxns) {
      final desc = txn.description?.toLowerCase() ?? '';
      final hasMatch = words.any((w) => w.length > 2 && desc.contains(w));
      if (!hasMatch) continue;

      txn.tags.loadSync();
      for (final tag in txn.tags) {
        tagFrequency[tag.id] = (tagFrequency[tag.id] ?? 0) + 1;
        tagMap[tag.id] = tag;
      }
    }

    if (tagFrequency.isEmpty) return [];

    final sorted = tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => tagMap[e.key]!).toList();
  }
}
