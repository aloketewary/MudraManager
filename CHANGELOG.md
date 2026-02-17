# Changelog

All notable changes to Mudra Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - TBD

### Added
- Period-based date selection with Day/Week/Month/Year/Custom presets
- Reusable `PeriodCalendarSelector` widget with Material Design 3 styling
- Dedicated budget details screen with hero header and gradient background
- Restore from backup functionality in account setup screen
- Subcategory support in expense trend charts (solid/dashed lines, grouped bars)
- 4 default income categories (Salary, Business, Investment, Other Income)
- 11 default expense parent categories with 8 subcategories
- `periodBasedTransactionsProvider` for isolated cash flow updates
- `sectionedTransactionsByDateRangeProvider` for proper date grouping
- Custom year/month picker with refresh icon
- Empty state handling for expense trends

### Changed
- **PERFORMANCE**: Statistics screen load time reduced from 2-5s to 50-200ms
- **PERFORMANCE**: Optimized `statsProvider` from 200+ queries to 2 queries
- **PERFORMANCE**: Single-pass aggregation for all chart data
- Budget dashboard now shows list cards instead of expandable cards
- Budget cards navigate to dedicated details screen on tap
- Cash flow period selector moved below account cards
- Calendar navigation buttons grouped with modern styling
- Haptic feedback reduced to lighter intensity
- Top category in insights card now sorted by highest spending
- Provider parameter format changed from `Map<String, DateTime>` to `String` format
- Category parent selection filtered to only show top-level categories

### Fixed
- ListView overflow error ("Vertical viewport was given unbounded height")
- Duplicate headers in date range transaction grouping
- TableCalendar assertion error when navigating to future months
- GlobalKey duplicate error in statistics screen
- Budget category card unbounded height constraint error
- Date comparison logic using DateTime equality
- N+1 query problem across all database operations
- Custom date selection triggering premature queries
- Subcategories being selectable as parent categories

### Removed
- SingleChildScrollView wrapper causing ListView overflow
- `pieKey` GlobalKey from statistics modal RepaintBoundary
- Recent transactions card from statistics screen
- FilterChips widget from dashboard (replaced with PeriodCalendarSelector)

### Technical
- Created `DATABASE_OPTIMIZATION_REPORT.md` documenting all performance improvements
- Implemented single query + in-memory aggregation pattern
- Improved Riverpod family provider caching strategy
- Better state management to reduce unnecessary rebuilds
- Enhanced code documentation and inline comments

## [1.0.0] - Initial Release

### Added
- Dashboard with financial overview
- SMS transaction tracking and parsing
- Budget management system
- Transaction history with search and filters
- Statistics and charts
- Multiple account support
- Category management
- Backup and restore functionality
- Biometric authentication
- Multi-language support
- Export to Excel/PDF
- Local-first architecture with Isar database
- Material Design 3 theming

---

[2.0.0]: https://github.com/yourusername/mudra_manager/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yourusername/mudra_manager/releases/tag/v1.0.0
