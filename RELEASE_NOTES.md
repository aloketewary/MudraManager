# Mudra Manager - Release Notes

## Version 2.0.0 - Major UI/UX Overhaul

### 🎨 Design & UI Improvements

#### Goals Module
- **Modernized Goal Screen**: Redesigned with Hero animation and horizontal card layout matching dashboard style
- **New Goal Details Screen**: Added comprehensive progress tracking with gradient header, circular progress indicators, and remaining days calculation
- **Enhanced Goal Cards**: Horizontal layout with icon on left, metrics in center, and progress percentage with chevron on right
- **Description Support**: Added optional description field for goals

#### Trip & Split Expenses
- **Settlement Visualization**: New SettlementCard component with debt/credit indicators, avatars, and visual arrow display
- **Mark as Paid**: Settlements can now be marked as paid with settled date tracking (persisted via SharedPreferences)
- **Settled State**: Paid settlements show with dashed border, reduced opacity, and "Settled on [date]" badge
- **Trip Summary**: Added per-person spending breakdown with progress bars, percentages, and average calculation
- **Expense Filters**: Filter trip expenses by participant and category with intuitive chip-based UI
- **Modernized Trip List**: Horizontal card layout with separated items matching dashboard style
- **Enhanced Reports**: Visual spending breakdown by person and category with progress indicators

#### Recurring Transactions
- **Synced UI**: Updated to match add transaction screen with card-based layout
- **Subcategory Support**: Full parent/child category selection with bottom sheet picker
- **Visual Indicators**: Stacked icons for subcategories, chevron for expandable categories

### 🐛 Bug Fixes
- Fixed type mismatch in PopupMenuItem for trip expense filters
- Fixed Settlement SharedPreferences parsing for ISO date format with colons
- Corrected icon mappings for onboarding categories (account_balance_wallet, bolt, checkroom, devices, directions_bus, local_gas_station, movie, receipt)
- Fixed auto backup service errors by removing invalid parameters

### 🧹 Code Quality
- Removed 20 unused files (3,303 lines of code)
- Cleaned up debug print statements
- Consistent Material 3 design patterns throughout
- Optimized component reusability

### 📦 Technical Details
- Material 3 enabled with dynamic theming
- Local-first architecture with Isar database
- SharedPreferences for settlement state persistence
- Proper subcategory handling across all transaction screens

---

## Previous Versions

### Version 1.0.0 - Initial Release
- SMS transaction tracking
- Budget management
- Transaction history
- Category management
- Account management
- Trip & split expenses
- Recurring transactions
- Export to Excel/PDF
- Biometric authentication
- Multi-language support
