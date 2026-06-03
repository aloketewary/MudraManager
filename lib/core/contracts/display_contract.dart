/// Display contract: defines the boundary between core truth and UI rendering.
///
/// UI widgets ONLY receive data through [DashboardState].
/// They NEVER:
/// - Import core/logic/*
/// - Import core/engine/*
/// - Call state machines directly
/// - Compute financial states
/// - Access raw transaction lists for state derivation
///
/// UI MAY:
/// - Format values for display (currency formatting, date formatting)
/// - Map enum states to colors/icons/labels
/// - Read DashboardState fields
/// - Pass DashboardState fields to child widgets
library;
