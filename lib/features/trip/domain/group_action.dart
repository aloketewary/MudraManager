/// Actions available on a group detail screen.
/// Permissions are exposed as `Set<GroupAction>` in state,
/// eliminating boolean explosion and widget-level permission logic.
enum GroupAction {
  addExpense,
  editGroup,
  archiveGroup,
  markSettlementPaid,
  exportPdf,
}
