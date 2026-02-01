// EXAMPLE: How to use AccountSelectorBottomSheet and CategorySelectorBottomSheet
// 
// Replace your existing account/category selection code with these simple calls:

import 'package:mudra_manager/screens/reusable/account_selector_bottom_sheet.dart';
import 'package:mudra_manager/screens/reusable/category_selector_bottom_sheet.dart';

// ============================================
// EXAMPLE 1: Select Account
// ============================================
// Replace your existing account selection ListView/GridView with a simple button:

// OLD CODE (Remove the entire ListView.builder for accounts):
// Consumer(
//   builder: (context, ref, _) {
//     final accountsAsync = ref.watch(accountsProvider);
//     return accountsAsync.when(
//       data: (accounts) => SizedBox(
//         height: 120,
//         child: ListView.builder(...) // 100+ lines of code
//       ),
//     );
//   },
// )

// NEW CODE (Replace with this):
ListTile(
  leading: Icon(Icons.account_balance_wallet),
  title: Text(_selectedAccount?.name ?? 'Select Account'),
  subtitle: _selectedAccount != null 
      ? Text('Balance: ${_selectedAccount!.balance}')
      : null,
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () async {
    final account = await AccountSelectorBottomSheet.show(
      context,
      selectedAccount: _selectedAccount,
    );
    if (account != null) {
      setState(() => _selectedAccount = account);
    }
  },
)

// ============================================
// EXAMPLE 2: Select Category
// ============================================
// Replace your existing category selection ListView/GridView with a simple button:

// OLD CODE (Remove the entire ListView.builder for categories):
// Consumer(
//   builder: (context, ref, _) {
//     final categoriesAsync = ref.watch(categoryListProvider);
//     return categoriesAsync.when(
//       data: (categories) => SizedBox(
//         height: 120,
//         child: ListView.builder(...) // 100+ lines of code
//       ),
//     );
//   },
// )

// NEW CODE (Replace with this):
ListTile(
  leading: Icon(Icons.category),
  title: Text(_selectedCategory?.name ?? 'Select Category'),
  subtitle: _selectedCategory != null
      ? Row(
          children: [
            Icon(
              IconHelper.getIconData(_selectedCategory!.iconName),
              size: 16,
              color: Color(_selectedCategory!.colorValue ?? 0xFF000000),
            ),
            SizedBox(width: 4),
            Text(_selectedCategory!.name),
          ],
        )
      : null,
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () async {
    final category = await CategorySelectorBottomSheet.show(
      context,
      selectedCategory: _selectedCategory,
      isExpense: _isExpense, // Pass your expense/income flag
    );
    if (category != null) {
      setState(() => _selectedCategory = category);
    }
  },
)

// ============================================
// BENEFITS:
// ============================================
// ✅ Reduces code from ~200 lines to ~20 lines per screen
// ✅ Consistent UI across all screens
// ✅ Easier to maintain - update once, applies everywhere
// ✅ Better UX with draggable bottom sheet
// ✅ Handles loading/error states automatically
// ✅ No need to manage providers in each screen
