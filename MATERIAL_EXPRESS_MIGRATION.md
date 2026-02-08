# Material Express Migration Guide

## Phase 1: Foundation Setup ✅ COMPLETED

### Dependencies Added:
- ✅ `animations: ^2.0.11` - Material motion system
- ✅ `dynamic_color: ^1.7.0` - System color extraction
- ✅ `responsive_framework: ^1.5.1` - Adaptive layouts
- ✅ `auto_size_text: ^3.0.0` - Text scaling

### Core Components Created:
- ✅ `lib/components/app_card.dart` - Reusable Material 3 card
- ✅ `lib/components/adaptive_text.dart` - Auto-sizing text
- ✅ `lib/components/app_list_tile.dart` - Consistent list tiles
- ✅ `lib/components/page_transitions.dart` - Material motion transitions
- ✅ `lib/components/responsive_helper.dart` - Responsive utilities

### Theme System Updated:
- ✅ Dynamic color support integrated
- ✅ Responsive breakpoints configured
- ✅ Theme methods support custom ColorScheme

## Phase 2: Screen Migration (Batch Processing)

### Batch 1: Dashboard & Home Screens
**Status:** PENDING
**Files:**
- [ ] lib/screens/home_screen.dart
- [ ] lib/screens/dashboard/dashboard_home.dart
- [ ] lib/screens/dashboard/cash_flow_screen.dart
- [ ] lib/screens/dashboard/net_worth_mini_card.dart
- [ ] lib/screens/dashboard/swipeable_account_card.dart
- [ ] lib/screens/dashboard/dashboard_account_card.dart

**Tasks:**
- Add ResponsiveWrapper
- Replace Text with AdaptiveText where needed
- Add page transitions
- Ensure overflow protection

### Batch 2: Transaction Screens
**Status:** PENDING
**Files:**
- [ ] lib/screens/transaction/transaction_list_screen.dart
- [ ] lib/screens/transaction/transaction_card.dart
- [ ] lib/screens/transaction/add_edit_transaction_screen.dart
- [ ] lib/screens/transaction/transfer_screen.dart
- [ ] lib/screens/transaction/account_card_mini.dart

**Tasks:**
- Use AppCard component
- Add AdaptiveText
- Add SharedAxis transitions
- Responsive layouts

### Batch 3: Statistics & Charts
**Status:** PENDING
**Files:**
- [ ] lib/screens/statistics/statistics_screen.dart
- [ ] lib/screens/statistics/widgets/hero_chart_card.dart
- [ ] lib/screens/statistics/widgets/metric_carousel_card.dart
- [ ] lib/screens/statistics/widgets/insight_grid_card.dart
- [ ] lib/screens/statistics/widgets/detail_action_card.dart

**Tasks:**
- Responsive chart sizing
- AdaptiveText for labels
- Overflow protection
- Smooth animations

### Batch 4: Budget & Goals
**Status:** PENDING
**Files:**
- [ ] lib/screens/budget/budget_dashboard.dart
- [ ] lib/screens/budget/budget_summary_card.dart
- [ ] lib/screens/budget/budget_category_mini_card.dart
- [ ] lib/screens/budget/add_budget_screen.dart
- [ ] lib/screens/goal/goal_screen.dart
- [ ] lib/screens/goal/goal_card.dart
- [ ] lib/screens/goal/add_edit_goal_screen.dart

**Tasks:**
- Use AppCard
- AdaptiveText for amounts
- Responsive grid layouts
- FadeThrough transitions

### Batch 5: Profile & Settings
**Status:** PENDING
**Files:**
- [ ] lib/screens/profile/profile_screen.dart
- [ ] lib/screens/profile/setting_screen.dart
- [ ] lib/screens/profile/app_settings_page.dart
- [ ] lib/screens/profile/manage_account_screen.dart
- [ ] lib/screens/profile/manage_categories_screen.dart
- [ ] lib/screens/profile/backup_restore_screen.dart

**Tasks:**
- Use AppListTile
- Responsive padding
- Modal transitions
- Overflow protection

### Batch 6: Trips & Bills
**Status:** PENDING
**Files:**
- [ ] lib/screens/trip/trips_screen.dart
- [ ] lib/screens/trip/trip_detail_screen.dart
- [ ] lib/screens/trip/create_trip_screen.dart
- [ ] lib/screens/trip/active_trip_mini_card.dart
- [ ] lib/screens/bills/bills_screen.dart

**Tasks:**
- Responsive card layouts
- AdaptiveText
- OpenContainer transitions
- Grid responsiveness

### Batch 7: Recurring & SMS
**Status:** PENDING
**Files:**
- [ ] lib/screens/recurring/recurring_transactions_screen.dart
- [ ] lib/screens/recurring/add_recurring_transaction_screen.dart
- [ ] lib/screens/sms/review_pending_transactions_Screen.dart
- [ ] lib/screens/sms/sms_selection_screen.dart

**Tasks:**
- AppCard usage
- Responsive layouts
- AdaptiveText
- Transitions

### Batch 8: Utility & Notifications
**Status:** PENDING
**Files:**
- [ ] lib/screens/utility/utility_screen.dart
- [ ] lib/screens/utility/monthly_comparison_screen.dart
- [ ] lib/screens/notifications/notification_page_screen.dart

**Tasks:**
- Responsive layouts
- AdaptiveText
- Overflow protection
- Smooth animations

## Phase 3: Router Enhancement

### Tasks:
- [ ] Add page transition animations to GoRouter
- [ ] Implement SharedAxis for main navigation
- [ ] Add FadeThrough for tab switches
- [ ] OpenContainer for card-to-detail transitions

## Phase 4: Dialog & Bottom Sheet Modernization

### Tasks:
- [ ] Update all showDialog calls with Material 3 spec
- [ ] Add drag handles to bottom sheets
- [ ] Implement adaptive heights
- [ ] Add motion transitions

## Phase 5: Overflow Hardening

### Testing Checklist:
- [ ] Test with max font size (Settings > Display > Font Size > Largest)
- [ ] Test with max display scaling
- [ ] Test on small phones (320dp width)
- [ ] Test on tablets (600dp+ width)
- [ ] Test landscape mode
- [ ] Test foldables (if available)

### Common Fixes:
- Wrap Text in Flexible/Expanded
- Use AdaptiveText instead of Text
- Add SingleChildScrollView where needed
- Use LayoutBuilder for dynamic sizing
- Replace fixed sizes with responsive values

## Phase 6: Accessibility Validation

### Tasks:
- [ ] Semantic labels for all interactive elements
- [ ] Proper contrast ratios
- [ ] Touch target sizes (48x48 minimum)
- [ ] Screen reader testing
- [ ] Keyboard navigation

## Next Steps:

1. Run `flutter pub get` to install new dependencies
2. Test dynamic color on Android 12+ device
3. Begin Batch 1 migration
4. Test each batch before proceeding
5. Document any issues or regressions

## Migration Principles:

✅ **DO:**
- Use AppCard for all card widgets
- Use AdaptiveText for dynamic text
- Add responsive padding/sizing
- Implement page transitions
- Test overflow scenarios
- Maintain flat Material 3 design

❌ **DON'T:**
- Add gradients or shadows
- Use fixed pixel sizes
- Skip overflow testing
- Remove existing functionality
- Break existing features

## Performance Targets:

- Page transitions: < 300ms
- No jank during animations
- Smooth scrolling on all devices
- Fast theme switching
- Efficient dynamic color updates
