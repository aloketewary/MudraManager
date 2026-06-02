# Statistics

> **Purpose:** "Show me my spending patterns with charts and comparisons."

---

## Key Files

| File | Role |
|---|---|
| `statistics_screen.dart` | Main statistics view with charts |
| `monthly_comparison_screen.dart` | Month-over-month comparison |
| `export_options_screen.dart` | Export to Excel/PDF |
| `utility_screen.dart` | Utility bill tracking |
| `category_pie_chart.dart` | Category distribution pie chart |
| `expense_trend_widget.dart` | Line chart for spending trends |
| `hero_chart_card.dart` | Primary chart card (dominant visual) |
| `insight_grid_card.dart` | Quick stat grid (avg/max/total) |
| `metric_carousel_card.dart` | Swipeable metric highlights |
| `detail_action_card.dart` | Actionable insight card |
| `period_selector.dart` | Time period picker (week/month/year) |

---

## Design Decisions

### 1. Chart as Hero

The primary chart occupies 40% of the screen. It's the first thing users see — visual, not numeric.

### 2. Period Selector

Users switch between week/month/quarter/year views. The chart and all metrics update accordingly.

### 3. Monthly Comparison

Side-by-side comparison of two months:
- Total spent
- Top categories
- Biggest changes
- "You spent ₹2,000 less on food this month"

### 4. Insight Grid

Quick-scan metrics: average daily spend, highest single expense, total income, savings rate. All in a compact grid below the chart.

### 5. Export to Excel/PDF

Full transaction history exportable as:
- Excel (.xlsx) — for spreadsheet users
- PDF — for sharing/printing with summary charts

---

## Interactions

- Period selector → updates all visualizations
- Tap pie slice → filtered transaction list for that category
- "Compare" → `monthly_comparison_screen.dart`
- "Export" → `export_options_screen.dart`

