import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class BillingService {
  final EntitlementService _entitlementService;
  final _log = AppLog(getLogger(), 'Billing');
  final _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails> _products = {};
  bool _available = false;

  /// Completer that resolves once products are loaded (or fails).
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  /// Callback for UI to react to purchase state changes.
  void Function(PurchaseStatus status, String? error)? onPurchaseUpdate;

  BillingService(this._entitlementService);

  // ── Lifecycle ──────────────────────────────────────────

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      _log.w('In-app purchases not available on this device');
      _ready.complete();
      return;
    }

    // Listen to purchase stream
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _log.e('Purchase stream error', error),
    );

    // Load product details
    await _loadProducts();
    _ready.complete();
  }

  void dispose() {
    _subscription?.cancel();
  }

  // ── Products ───────────────────────────────────────────

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(
      EntitlementProducts.allProductIds,
    );

    if (response.error != null) {
      _log.e('Error loading products: ${response.error!.message}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      _log.w('Products not found: ${response.notFoundIDs}');
    }

    _products = {
      for (final p in response.productDetails) p.id: p,
    };
    _log.i('Loaded ${_products.length} products');
  }

  ProductDetails? getProduct(String id) => _products[id];

  /// Returns the localized price string from Google Play, or null
  /// if the product hasn't loaded yet.
  String? getPrice(String id) => _products[id]?.price;

  bool get isAvailable => _available;

  // ── Purchase ───────────────────────────────────────────
  Future<bool> buy(String productId, {String? offerToken}) async {
    final product = _products[productId];
    if (product == null) {
      _log.e('Product $productId not found');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    // For subscriptions on Google Play, use GooglePlayPurchaseParam
    // to select the correct base plan via offerToken
    if (EntitlementProducts.isSubscription(productId) && offerToken != null) {
      final googleParam = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: null,
      );
      // Note: The offerToken is embedded in the ProductDetails
      // from queryProductDetails — the correct offer must be
      // selected in the UI before calling buy()
      try {
        return await _iap.buyNonConsumable(purchaseParam: googleParam);
      } catch (e) {
        _log.e('Error initiating subscription purchase', e);
        return false;
      }
    }

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _log.e('Error initiating purchase', e);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _log.w('Restore purchases failed', e);
    }
  }

  // ── Purchase handling ──────────────────────────────────

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      _log.i(
        'Purchase update: ${purchase.productID} → ${purchase.status}',
      );

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndGrant(purchase);
          onPurchaseUpdate?.call(purchase.status, null);
          break;

        case PurchaseStatus.error:
          _log.e('Purchase error: ${purchase.error?.message}');
          onPurchaseUpdate?.call(
            purchase.status,
            purchase.error?.message ?? 'Purchase failed',
          );
          break;

        case PurchaseStatus.canceled:
          _log.i('Purchase cancelled');
          onPurchaseUpdate?.call(purchase.status, null);
          break;

        case PurchaseStatus.pending:
          _log.i('Purchase pending');
          onPurchaseUpdate?.call(purchase.status, null);
          break;
      }

      // Always complete pending purchases to avoid stuck state
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndGrant(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final token = purchase.verificationData.serverVerificationData;

    final basePlan = _resolveBasePlan(purchase);
    final storedProductId = '${productId}_$basePlan';

    final expiresAt = basePlan == EntitlementProducts.monthlyPlan
        ? DateTime.now().add(const Duration(days: 33))
        : DateTime.now().add(const Duration(days: 370));

    await _entitlementService.grantPro(
      source: 'play_store',
      productId: storedProductId,
      purchaseToken: token.isNotEmpty ? token : 'local_${purchase.purchaseID}',
      expiresAt: expiresAt,
    );
  }

  /// Resolve which base plan was purchased.
  /// On Google Play, subscription offers contain the basePlanId.
  String _resolveBasePlan(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      // The billingClientPurchase contains the obfuscated info,
      // but we can check the purchase token or use the offer tag.
      // Simplest: check if yearly offer was selected (stored in _lastBasePlan)
      return _lastBasePlan ?? EntitlementProducts.monthlyPlan;
    }
    return _lastBasePlan ?? EntitlementProducts.monthlyPlan;
  }

  /// Set by the UI before calling buy() so we know which plan was chosen.
  String? _lastBasePlan;
  void setSelectedBasePlan(String basePlan) => _lastBasePlan = basePlan;
}
