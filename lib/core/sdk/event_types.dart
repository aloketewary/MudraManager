class EventTypes {
  // SMS Events
  static const smsReceived = 'sms.received';
  static const smsParsed = 'sms.parsed';
  
  // Transaction Events
  static const transactionCreated = 'transaction.created';
  static const transactionUpdated = 'transaction.updated';
  static const transactionDeleted = 'transaction.deleted';
  
  // Budget Events
  static const budgetExceeded = 'budget.exceeded';
  static const budgetWarning = 'budget.warning';
  
  // Goal Events
  static const goalReached = 'goal.reached';
  static const goalProgress = 'goal.progress';
}
