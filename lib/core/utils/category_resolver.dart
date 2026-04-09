import 'package:mudra_manager/core/db/models/category.dart';

/// Resolves unknown category names to icon, color, type, and keywords.
/// Used during Excel import to auto-create missing categories.
class CategoryResolver {
  CategoryResolver._();

  /// Known category templates: name pattern → (icon, color, type, keywords)
  static final _templates = <String, _Template>{
    // Expense
    'food': const _Template('utensils', 0xFFEF4444, CategoryType.expense, ['food', 'restaurant', 'dining', 'lunch', 'dinner', 'breakfast', 'snack', 'cafe']),
    'grocery': const _Template('shopping_cart', 0xFF22C55E, CategoryType.expense, ['grocery', 'supermarket', 'vegetables', 'fruits', 'kirana', 'bigbasket', 'blinkit', 'zepto', 'instamart']),
    'transport': const _Template('car', 0xFF3B82F6, CategoryType.expense, ['uber', 'ola', 'taxi', 'cab', 'metro', 'bus', 'petrol', 'fuel', 'auto', 'train', 'parking', 'toll']),
    'shopping': const _Template('shopping_bag', 0xFFF59E0B, CategoryType.expense, ['amazon', 'flipkart', 'myntra', 'shopping', 'mall', 'store', 'clothes', 'shoes', 'electronics']),
    'entertainment': const _Template('film', 0xFF8B5CF6, CategoryType.expense, ['netflix', 'prime', 'hotstar', 'spotify', 'movie', 'cinema', 'games', 'concert', 'streaming']),
    'utilities': const _Template('zap', 0xFF06B6D4, CategoryType.expense, ['electricity', 'water', 'gas', 'internet', 'broadband', 'recharge', 'wifi', 'bill', 'maintenance']),
    'healthcare': const _Template('heart_pulse', 0xFFEC4899, CategoryType.expense, ['hospital', 'doctor', 'pharmacy', 'medicine', 'clinic', 'dental', 'checkup', 'lab']),
    'education': const _Template('graduation_cap', 0xFF6366F1, CategoryType.expense, ['school', 'college', 'course', 'tuition', 'books', 'fees', 'exam', 'coaching']),
    'travel': const _Template('plane', 0xFF14B8A6, CategoryType.expense, ['flight', 'hotel', 'booking', 'vacation', 'trip', 'tour', 'visa', 'airbnb']),
    'rent': const _Template('home', 0xFF78716C, CategoryType.expense, ['rent', 'lease', 'housing', 'apartment', 'flat', 'pg', 'hostel']),
    'insurance': const _Template('shield', 0xFF0EA5E9, CategoryType.expense, ['insurance', 'premium', 'policy', 'lic', 'health', 'life', 'motor', 'term']),
    'personal': const _Template('user', 0xFFD946EF, CategoryType.expense, ['salon', 'spa', 'haircut', 'gym', 'fitness', 'beauty', 'grooming']),
    'gift': const _Template('gift', 0xFFF43F5E, CategoryType.expense, ['gift', 'present', 'donation', 'charity', 'temple', 'festival', 'birthday', 'wedding']),
    'subscription': const _Template('credit_card', 0xFF7C3AED, CategoryType.expense, ['subscription', 'membership', 'plan', 'monthly', 'annual', 'renewal']),
    'emi': const _Template('banknote', 0xFFDC2626, CategoryType.expense, ['emi', 'loan', 'installment', 'repayment', 'mortgage', 'credit']),
    'investment': const _Template('trending_up', 0xFF059669, CategoryType.expense, ['mutual fund', 'stock', 'sip', 'zerodha', 'groww', 'shares', 'equity', 'fd', 'rd']),
    'business': const _Template('briefcase', 0xFF475569, CategoryType.expense, ['office', 'supplies', 'equipment', 'software', 'marketing', 'advertising']),
    'pet': const _Template('paw_print', 0xFFCA8A04, CategoryType.expense, ['pet', 'vet', 'dog', 'cat', 'animal', 'pet food']),
    'kids': const _Template('baby', 0xFFFB923C, CategoryType.expense, ['kids', 'baby', 'child', 'school fees', 'toys', 'diapers', 'daycare']),
    // Income
    'salary': const _Template('wallet', 0xFF10B981, CategoryType.income, ['salary', 'wages', 'income', 'bonus', 'incentive', 'commission', 'freelance']),
    'freelance': const _Template('laptop', 0xFF3B82F6, CategoryType.income, ['freelance', 'consulting', 'contract', 'gig', 'project']),
    'interest': const _Template('percent', 0xFF8B5CF6, CategoryType.income, ['interest', 'dividend', 'returns', 'fd interest', 'savings interest']),
    'refund': const _Template('rotate_ccw', 0xFF06B6D4, CategoryType.income, ['refund', 'cashback', 'return', 'reimbursement', 'reversal']),
    'rental': const _Template('home', 0xFFF59E0B, CategoryType.income, ['rental income', 'rent received', 'tenant', 'property income']),
  };

  /// Default fallback for completely unknown categories
  static const _fallbackIcon = 'circle';
  static const _fallbackColor = 0xFF94A3B8; // slate-400

  /// Resolve a category name to a template.
  /// Tries exact match first, then keyword match.
  static _Template? _resolve(String name) {
    final lower = name.toLowerCase().trim();

    // Exact key match
    for (final entry in _templates.entries) {
      if (lower == entry.key || lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Keyword match
    for (final entry in _templates.entries) {
      for (final kw in entry.value.keywords) {
        if (lower.contains(kw) || kw.contains(lower)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Create a Category object for an unknown name.
  static Category createCategory(String name) {
    final template = _resolve(name);
    return Category.create(
      name: name,
      categoryType: template?.type ?? CategoryType.expense,
      keywords: template?.keywords,
    )
      ..iconName = template?.icon ?? _fallbackIcon
      ..colorValue = template?.color ?? _fallbackColor;
  }

  /// Check if a name can be resolved to a known template.
  static bool isKnown(String name) => _resolve(name) != null;

  /// Get the inferred CategoryType for a name.
  static CategoryType inferType(String name) =>
      _resolve(name)?.type ?? CategoryType.expense;
}

class _Template {
  final String icon;
  final int color;
  final CategoryType type;
  final List<String> keywords;

  const _Template(this.icon, this.color, this.type, this.keywords);
}
