# Import/Export

> **Purpose:** "Get my data in or out of the app in standard formats."

---

## Key Files

| File | Role |
|---|---|
| `import_export_screen.dart` | Main import/export options hub |
| `import_preview_screen.dart` | Preview imported data before committing |
| `export_excel_pdf.dart` | Export generation logic |

---

## Design Decisions

### 1. Preview Before Import

Imported data is never auto-committed. Users see a preview of what will be added, can deselect items, and explicitly confirm.

### 2. Export Formats

- **Excel (.xlsx)** — Full transaction data with columns for all fields
- **PDF** — Formatted report with summary charts and transaction list

### 3. Date Range Selection

Users choose what to export: all time, this month, last 3 months, or custom range.

### 4. Backup ≠ Export

Export creates human-readable files. Backup (in profile/settings) creates a machine-readable Isar snapshot for full app restoration. Different use cases, different flows.

