/// Google Play product identifiers.
abstract class EntitlementProducts {
  // Subscription (single)
  static const String subscription = 'mudra_pro';

  // Base plans (used internally)
  static const String monthlyPlan = 'monthly';
  static const String yearlyPlan = 'yearly';

  // One-time
  static const String lifetime = 'mudra_pro_lifetime';

  static const Set<String> allProductIds = {
    subscription,
    lifetime,
  };

  /// Quick check: is this a subscription product?
  static bool isSubscription(String id) => id == subscription;
}
