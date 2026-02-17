# Pro Version Implementation Guide

## Overview
This guide covers implementing a Pro/Premium version for Mudra Manager using in-app purchases (IAP) for both Android and iOS.

---

## 1. Setup Dependencies

### pubspec.yaml
```yaml
dependencies:
  in_app_purchase: ^3.1.13
  shared_preferences: ^2.2.2  # Already present
```

Run: `flutter pub get`

---

## 2. Create Pro Features Service

### lib/service/pro_features_service.dart
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ProFeaturesService {
  static const String _proStatusKey = 'is_pro_user';
  static const String proProductId = 'mudra_manager_pro'; // Android
  static const String proProductIdIOS = 'com.mudramanager.pro'; // iOS
  
  final InAppPurchase _iap = InAppPurchase.instance;
  
  // Check if user is Pro
  Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proStatusKey) ?? false;
  }
  
  // Set Pro status
  Future<void> setProStatus(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proStatusKey, isPro);
  }
  
  // Purchase Pro
  Future<bool> purchasePro() async {
    final available = await _iap.isAvailable();
    if (!available) return false;
    
    final productId = Platform.isAndroid ? proProductId : proProductIdIOS;
    final response = await _iap.queryProductDetails({productId});
    
    if (response.productDetails.isEmpty) return false;
    
    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
  
  // Restore purchases
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
```

---

## 3. Create Pro Provider

### lib/providers/pro_provider.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/service/pro_features_service.dart';

final proServiceProvider = Provider((ref) => ProFeaturesService());

final isProUserProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(proServiceProvider);
  return await service.isProUser();
});
```

---

## 4. Define Pro Features

### Free vs Pro Features

**Free Features:**
- ✅ Unlimited transactions
- ✅ Basic categories
- ✅ 3 accounts
- ✅ Monthly budgets
- ✅ SMS import (50/month)
- ✅ Basic statistics
- ✅ Local backup

**Pro Features:**
- 🔒 Unlimited accounts
- 🔒 Custom categories with subcategories
- 🔒 Unlimited SMS import
- 🔒 Advanced statistics & trends
- 🔒 Cloud backup (Google Drive/Dropbox)
- 🔒 Receipt scanning (OCR)
- 🔒 Multi-currency support
- 🔒 Recurring transactions
- 🔒 Bill reminders
- 🔒 Export to Excel/PDF
- 🔒 Trip expense tracking
- 🔒 Investment tracking
- 🔒 Ad-free experience
- 🔒 Priority support

---

## 5. Create Pro Gate Widget

### lib/components/pro_gate.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/providers/pro_provider.dart';

class ProGate extends ConsumerWidget {
  final Widget child;
  final String featureName;
  
  const ProGate({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProUserProvider);
    
    return isProAsync.when(
      data: (isPro) {
        if (isPro) return child;
        return _ProLockedWidget(featureName: featureName);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, __) => child,
    );
  }
}

class _ProLockedWidget extends StatelessWidget {
  final String featureName;
  
  const _ProLockedWidget({required this.featureName});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      child: InkWell(
        onTap: () => context.push('/pro-upgrade'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 48, color: color.primary),
              SizedBox(height: 16),
              Text(
                '$featureName',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Upgrade to Pro to unlock this feature',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/pro-upgrade'),
                icon: Icon(Icons.star),
                label: Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Create Pro Upgrade Screen

### lib/screens/profile/pro_upgrade_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/pro_provider.dart';

class ProUpgradeScreen extends ConsumerWidget {
  const ProUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade to Pro'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero Section
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.primary, color.tertiary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.star, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Mudra Manager Pro',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Unlock all premium features',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Features List
            _buildFeature(Icons.account_balance_wallet, 'Unlimited Accounts'),
            _buildFeature(Icons.category, 'Custom Categories'),
            _buildFeature(Icons.sms, 'Unlimited SMS Import'),
            _buildFeature(Icons.cloud_upload, 'Cloud Backup'),
            _buildFeature(Icons.receipt, 'Receipt Scanning'),
            _buildFeature(Icons.currency_exchange, 'Multi-Currency'),
            _buildFeature(Icons.repeat, 'Recurring Transactions'),
            _buildFeature(Icons.notifications, 'Bill Reminders'),
            _buildFeature(Icons.file_download, 'Export Reports'),
            _buildFeature(Icons.beach_access, 'Trip Tracking'),
            _buildFeature(Icons.trending_up, 'Investment Tracking'),
            _buildFeature(Icons.block, 'Ad-Free Experience'),
            
            SizedBox(height: 32),
            
            // Pricing
            Card(
              color: color.primaryContainer,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '₹299',
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'One-time payment',
                      style: textTheme.bodyLarge?.copyWith(
                        color: color.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _purchasePro(context, ref),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                      ),
                      child: Text('Upgrade Now'),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _restorePurchases(context, ref),
                      child: Text('Restore Purchases'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(width: 16),
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
  
  Future<void> _purchasePro(BuildContext context, WidgetRef ref) async {
    final service = ref.read(proServiceProvider);
    final success = await service.purchasePro();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome to Pro! 🎉')),
      );
      Navigator.pop(context);
    }
  }
  
  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final service = ref.read(proServiceProvider);
    await service.restorePurchases();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchases restored')),
      );
    }
  }
}
```

---

## 7. Usage Examples

### Example 1: Lock Feature Behind Pro
```dart
// In any screen
ProGate(
  featureName: 'Cloud Backup',
  child: BackupRestoreScreen(),
)
```

### Example 2: Show Pro Badge
```dart
Consumer(
  builder: (context, ref, _) {
    final isPro = ref.watch(isProUserProvider).value ?? false;
    
    return ListTile(
      title: Text('Export to Excel'),
      trailing: isPro 
        ? Icon(Icons.check_circle, color: Colors.green)
        : Chip(label: Text('PRO')),
      onTap: isPro 
        ? () => exportToExcel()
        : () => context.push('/pro-upgrade'),
    );
  },
)
```

### Example 3: Limit Free Features
```dart
Future<void> addAccount() async {
  final isPro = await ref.read(isProUserProvider.future);
  final accounts = await ref.read(accountsProvider.future);
  
  if (!isPro && accounts.length >= 3) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Upgrade to Pro'),
        content: Text('Free users can create up to 3 accounts. Upgrade to Pro for unlimited accounts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/pro-upgrade');
            },
            child: Text('Upgrade'),
          ),
        ],
      ),
    );
    return;
  }
  
  // Proceed with adding account
}
```

---

## 8. Platform Setup

### Android Setup

#### android/app/build.gradle
```gradle
dependencies {
    implementation 'com.android.billingclient:billing:6.0.1'
}
```

#### Google Play Console
1. Go to Play Console → Your App → Monetize → Products → In-app products
2. Create product:
   - Product ID: `mudra_manager_pro`
   - Name: Mudra Manager Pro
   - Description: Unlock all premium features
   - Price: ₹299
   - Type: Non-consumable

### iOS Setup

#### ios/Runner/Info.plist
```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

#### App Store Connect
1. Go to App Store Connect → Your App → Features → In-App Purchases
2. Create IAP:
   - Reference Name: Mudra Manager Pro
   - Product ID: `com.mudramanager.pro`
   - Type: Non-Consumable
   - Price: ₹299

---

## 9. Add to Router

### lib/router/app_router.dart
```dart
GoRoute(
  path: '/pro-upgrade',
  builder: (context, state) => ProUpgradeScreen(),
),
```

---

## 10. Add Pro Badge to Profile

### lib/screens/profile/profile_screen.dart
```dart
// In AppBar or profile header
Consumer(
  builder: (context, ref, _) {
    final isPro = ref.watch(isProUserProvider).value ?? false;
    
    if (isPro) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber, Colors.orange],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    return TextButton(
      onPressed: () => context.push('/pro-upgrade'),
      child: Text('Upgrade to Pro'),
    );
  },
)
```

---

## 11. Testing

### Test Purchases

**Android:**
1. Add test account in Play Console
2. Use test product IDs
3. Test with `android.test.purchased`

**iOS:**
1. Create Sandbox tester in App Store Connect
2. Sign out of App Store on device
3. Use sandbox account when prompted

### Test Code
```dart
// For testing, bypass Pro check
final isProUserProvider = FutureProvider<bool>((ref) async {
  // return true; // For testing
  final service = ref.watch(proServiceProvider);
  return await service.isProUser();
});
```

---

## 12. Implementation Checklist

### Phase 1: Setup (Week 1)
- [ ] Add dependencies
- [ ] Create ProFeaturesService
- [ ] Create ProProvider
- [ ] Create ProGate widget
- [ ] Create ProUpgradeScreen

### Phase 2: Platform Setup (Week 2)
- [ ] Setup Google Play Console products
- [ ] Setup App Store Connect IAPs
- [ ] Test purchases on both platforms
- [ ] Implement restore purchases

### Phase 3: Feature Gating (Week 3)
- [ ] Limit accounts to 3 for free users
- [ ] Limit SMS import to 50/month
- [ ] Lock cloud backup behind Pro
- [ ] Lock receipt scanning behind Pro
- [ ] Lock advanced statistics behind Pro

### Phase 4: Polish (Week 4)
- [ ] Add Pro badge throughout app
- [ ] Add upgrade prompts
- [ ] Add Pro benefits screen
- [ ] Test complete flow
- [ ] Submit for review

---

## 13. Pricing Strategy

### Recommended Pricing
- **India**: ₹299 (one-time)
- **US**: $4.99 (one-time)
- **Alternative**: ₹99/month or ₹999/year

### Promotional Strategy
- Launch discount: 50% off first month
- Limited time offer: ₹199 for early adopters
- Bundle: Pro + Cloud storage for ₹399

---

## 14. Marketing

### In-App Prompts
- Show after 10 transactions
- Show when hitting free limits
- Show Pro features with lock icon
- Offer 7-day trial (optional)

### App Store Description
```
FREE FEATURES:
✓ Unlimited transactions
✓ 3 accounts
✓ Basic categories
✓ Monthly budgets
✓ SMS import (50/month)

PRO FEATURES:
★ Unlimited accounts
★ Custom categories
★ Unlimited SMS import
★ Cloud backup
★ Receipt scanning
★ Multi-currency
★ Advanced analytics
★ And much more!
```

---

## 15. Legal Requirements

### Privacy Policy Update
Add section about in-app purchases and data handling.

### Terms of Service
Add section about Pro subscription terms, refunds, and cancellation.

---

**Implementation Time**: 3-4 weeks
**Estimated Revenue**: ₹50,000-₹2,00,000/month (with 1000-5000 Pro users)
