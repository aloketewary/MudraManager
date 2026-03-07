# Changelog

## [3.2.0] - 2024-12-19

### Added
- Enhanced Credit Card Reminder Plugin with account selection UI
- Comprehensive backup and sync system with offline-first approach
- Business and regional category plugins with subcategory support
- SMS parser optimization for IndusInd Bank
- Category keywords enhancement with Indian brands and services
- Plugin system optimization with caching and autoDispose

### Fixed
- Fixed slow list animations in profile screen
- Resolved Flutter deprecation warnings for RadioListTile and Radio widgets
- Fixed IndusInd Bank SMS parsing with "A/C *XX6988" format
- Fixed LowBalancePlugin constructor error
- Fixed incomplete contentPadding in credit card configuration dialog
- Removed unused imports

### Changed
- Migrated from Material Icons to Lucide icons for consistent design
- Simplified backup system from complex cloud sync to offline-first approach
- Disabled automatic keyword learning from SMS to prevent unwanted keywords
- Applied autoDispose to providers for better memory management

### Performance
- Optimized plugin loading with caching and early exits
- Reduced animation duration to 300ms for better performance
- Improved list rendering with addPostFrameCallback

## [3.1.0] - Previous Release
- Initial plugin system implementation
- SMS transaction tracking
- Budget management features
- Dashboard and insights