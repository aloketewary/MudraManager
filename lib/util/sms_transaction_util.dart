void parseAndSaveTransaction(String sms) {
  final isExpense = sms.contains("spent") || sms.contains("debited");
  final isIncome = sms.contains("credited") || sms.contains("received");

  double amount = extractAmountFromSms(sms);
  String description = extractMerchantFromSms(sms);

  if (amount == 0) return; // invalid sms

  if (isExpense) {
    // Save Expense transaction
    print("Expense Detected: ₹$amount at $description");
  } else if (isIncome) {
    // Save Income transaction
    print("Income Detected: ₹$amount from $description");
  }
}

double extractAmountFromSms(String sms) {
  final regex = RegExp(r'₹\s?(\d+(\.\d+)?)');
  final match = regex.firstMatch(sms);
  if (match != null) {
    return double.parse(match.group(1)!);
  }
  return 0.0;
}

String extractMerchantFromSms(String sms) {
  // Very basic for now, we can improve later
  if (sms.contains("at")) {
    var parts = sms.split("at");
    if (parts.length > 1) {
      return parts[1].split(" ")[0];
    }
  }
  return "Unknown Merchant";
}
