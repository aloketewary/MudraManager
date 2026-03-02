import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';

class CategorySeeder {
  static Future<void> seedDefaultKeywords(Isar isar) async {
    final categories = await isar.categorys.where().findAll();
    
    final keywordMap = {
      'Food & Dining': ['swiggy', 'zomato', 'restaurant', 'food', 'dining', 'cafe', 'pizza', 'burger'],
      'Groceries': ['bigbasket', 'blinkit', 'zepto', 'grocery', 'supermarket', 'dmart'],
      'Transportation': ['uber', 'ola', 'rapido', 'taxi', 'cab', 'metro', 'bus', 'petrol', 'fuel'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'shopping', 'mall', 'store'],
      'Entertainment': ['netflix', 'prime', 'hotstar', 'spotify', 'bookmyshow', 'movie', 'cinema'],
      'Utilities': ['electricity', 'water', 'gas', 'internet', 'broadband', 'mobile', 'recharge'],
      'Healthcare': ['hospital', 'doctor', 'pharmacy', 'medicine', 'clinic', 'apollo', 'medplus'],
      'Education': ['school', 'college', 'university', 'course', 'tuition', 'books'],
      'Travel': ['flight', 'hotel', 'booking', 'makemytrip', 'goibibo', 'airbnb'],
      'Salary': ['salary', 'wages', 'income', 'payment received'],
      'Investment': ['mutual fund', 'stock', 'sip', 'dividend', 'interest'],
    };
    
    await isar.writeTxn(() async {
      for (final category in categories) {
        if (category.keywords == null || category.keywords!.isEmpty) {
          for (final entry in keywordMap.entries) {
            if (category.name.toLowerCase().contains(entry.key.toLowerCase())) {
              category.keywords = entry.value;
              await isar.categorys.put(category);
              break;
            }
          }
        }
      }
    });
  }
}
