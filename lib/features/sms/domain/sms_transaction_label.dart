import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';

/// Resolves the short title shown for an SMS-imported transaction.
///
/// The raw SMS body remains available on [SmsActivity]. Transaction cards
/// should show the merchant when it is reliable, then a category/type label.
class SmsTransactionLabel {
  const SmsTransactionLabel._();

  static String? resolve(
    SmsActivity activity, {
    Category? category,
  }) {
    final merchant = validMerchant(activity.merchant);
    if (merchant != null) return merchant;

    final categoryName = category?.name.trim();
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }

    final activityCategory = activity.category?.trim();
    if (activityCategory != null && activityCategory.isNotEmpty) {
      return activityCategory;
    }

    final transactionType = activity.transactionType?.trim();
    if (transactionType != null && transactionType.isNotEmpty) {
      return transactionType;
    }

    return null;
  }

  /// Reject parser output that is only a recipient/account number.
  static String? validMerchant(String? merchant) {
    final normalized = merchant?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (RegExp(r'^[\d\s.,+()\-/]+$').hasMatch(normalized)) return null;
    return normalized;
  }
}
