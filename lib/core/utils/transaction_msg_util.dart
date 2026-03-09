import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class TransactionUtil {
  static final upiRegex = RegExp(r'[\w.-]+@[\w.-]+');
  static const balanceKeywords = [
    'avaialble balance',
    'avbl bal',
    'avl bal',
    'available balance',
    'a/c bal',
    'available bal',
    'avail bal',
    'curr bal',
    'current balance',
    'total bal',
    'clear bal',
    'avl limit',
    'available limit',
    'bal',
  ];
  static const trnKeywords = ['debited', 'credited', 'payment', 'spent'];

  static final creditPattern = RegExp(r'credited|credit|deposited|received');
  static final debitPattern = RegExp(
    r'debited|debit|deducted|sent|paid|withdrawn',
  );
  static final miscPattern = RegExp(r'payment|spent|transfer');

  TransactionType getTypeOfTransaction(String message) {
    final lowerMessage = message.toLowerCase();
    if (debitPattern.hasMatch(lowerMessage)) {
      return TransactionType.debited;
    } else if (creditPattern.hasMatch(lowerMessage)) {
      return TransactionType.credited;
    } else if (miscPattern.hasMatch(lowerMessage)) {
      return TransactionType.debitMisc;
    }
    return TransactionType.noMatch;
  }

  List<String> processMessage(String message) {
    String processed = message.toLowerCase();
    // Standardize account terms first - handle A?C pattern
    processed = processed.replaceAll('a?c', ' ac ');
    processed = processed.replaceAll(RegExp(r'a/c|acct|account'), ' ac ');

    // Standardize currency
    processed = processed.replaceAll(RegExp(r'inr\.?|rs\.?'), ' rs. ');

    // Clean up characters but PRESERVE word structures
    processed = processed.replaceAll(RegExp(r'[:-]'), ' ');
    processed = processed.replaceAll(RegExp(r'[*]'), '');
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    return processed.split(' ')..removeWhere((word) => word.isEmpty);
  }

  TransactionInfo getTransactionInfo(
    String? message,
    String? address,
    String? sender,
    String smsHash,
  ) {
    final info = TransactionInfo(
      address: address ?? '',
      sender: sender ?? '',
      body: message ?? '',
      smsHash: smsHash,
    );

    if (message == null || message.isEmpty) return info;

    info.transactionTime = getTransactionTime(message);
    final processedWords = processMessage(message);
    final fullProcessed = processedWords.join(' ');

    info.account = getAccountFromWords(
      processedWords,
      fullProcessed,
      address ?? '',
      sender ?? '',
    );
    info.money = getMoneySpentFromWords(processedWords);
    info.balance = getBalanceFromProcessed(fullProcessed);

    final isValid =
        [
          info.balance,
          info.money,
          info.account?.no,
        ].where((x) => x != null && x != '').isNotEmpty ||
        info.transactionTime != null;

    if (isValid) {
      info.typeOfTransaction = getTypeOfTransaction(fullProcessed);
    }

    return info;
  }

  String getMoneySpentFromWords(List<String> words) {
    int index = words.indexOf('rs.');
    if (index == -1) {
      // Try without dot
      index = words.indexOf('rs');
    }
    
    // Try "refund of 118" or "amount of 118" pattern
    if (index == -1) {
      final ofIndex = words.indexOf('of');
      if (ofIndex != -1 && ofIndex + 1 < words.length) {
        final amount = words[ofIndex + 1].replaceAll(',', '').replaceAll(RegExp(r'[^\d.]+$'), '');
        if (!_isNotNumeric(amount)) {
          return amount;
        }
      }
    }
    
    if (index == -1 || index + 1 >= words.length) return '';

    String amount = words[index + 1].replaceAll(',', '');
    // Strip trailing punctuation
    amount = amount.replaceAll(RegExp(r'[^\d.]+$'), '');

    if (_isNotNumeric(amount) && index + 2 < words.length) {
      amount = words[index + 2].replaceAll(',', '');
      amount = amount.replaceAll(RegExp(r'[^\d.]+$'), '');
    }

    return _isNotNumeric(amount) ? '' : amount;
  }

  AccountDetails getAccountFromWords(
    List<String> words,
    String fullProcessed,
    String address,
    String sender,
  ) {
    final account = AccountDetails();

    // Extract bank name from message, sender, or address
    account.bankName =
        _extractBankName(fullProcessed) ??
        _extractBankName(sender) ??
        _extractBankName(address);

    if (upiRegex.hasMatch(fullProcessed)) {
      account.type = 'UPI';
      account.no = 'N/A';
      String sendTo = upiRegex.stringMatch(fullProcessed)!;
      if (sendTo.endsWith('.')) sendTo = sendTo.substring(0, sendTo.length - 1);
      account.sendTo = sendTo;
      account.refNo = extractUPIRefNo(fullProcessed, true);
      return account;
    }

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      final isCard = word == 'card';
      final isAc = word == 'ac';

      if (isCard || isAc) {
        int nextIdx = i + 1;
        // Skip possible connector words: 'ends', 'ending', 'with', 'no', '.', ':', '#', '*'
        while (nextIdx < words.length &&
            (words[nextIdx] == 'ends' ||
                words[nextIdx] == 'ending' ||
                words[nextIdx] == 'with' ||
                words[nextIdx] == 'no' ||
                words[nextIdx] == 'nos' ||
                words[nextIdx] == '.' ||
                words[nextIdx] == '#' ||
                words[nextIdx] == '*' ||
                words[nextIdx] == 'is')) {
          nextIdx++;
        }

        if (nextIdx < words.length) {
          final accountNo = _sanitizeAccountNo(words[nextIdx]);
          if (accountNo.isNotEmpty && _isValidAccountNumber(accountNo)) {
            account.type = isCard ? 'card' : 'account';
            account.no = accountNo;
            account.refNo = extractUPIRefNo(fullProcessed, false);
            return account;
          }
        }
      }

      // Match patterns like *XX6988 or x6988
      if ((word.startsWith('*') || word.startsWith('x')) && word.length > 1) {
        final accountNo = _sanitizeAccountNo(word);
        if (accountNo.isNotEmpty &&
            accountNo.length >= 4 &&
            _isValidAccountNumber(accountNo)) {
          account.type = 'account';
          account.no = accountNo;
          account.refNo = extractUPIRefNo(fullProcessed, false);
          return account;
        }
      }
    }
    return account;
  }

  String? _extractBankName(String message) {
    final lower = message.toLowerCase();
    final banks = {
      'indusind': 'IndusInd Bank',
      'hdfcbank': 'HDFC Bank',
      'hdfc': 'HDFC Bank',
      'icicibank': 'ICICI Bank',
      'icici': 'ICICI Bank',
      'sbibank': 'SBI',
      'sbi': 'SBI',
      'axisbank': 'Axis Bank',
      'axis': 'Axis Bank',
      'kotakbank': 'Kotak Bank',
      'kotak': 'Kotak Bank',
      'pnbbank': 'PNB',
      'pnb': 'PNB',
      'paytm': 'Paytm',
      'phonepe': 'PhonePe',
      'googlepay': 'Google Pay',
      'gpay': 'Google Pay',
      'rwallet': 'RWallet',
      'milkbasket': 'Milkbasket Wallet',
      'swiggy': 'Swiggy Wallet',
      'zomato': 'Zomato Wallet',
      'amazon pay': 'Amazon Pay',
      'amazonpay': 'Amazon Pay',
      'mobikwik': 'MobiKwik',
      'freecharge': 'FreeCharge',
      'ola money': 'Ola Money',
      'olamoney': 'Ola Money',
    };

    for (var entry in banks.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  bool _isValidAccountNumber(String accountNo) {
    // Must contain at least one digit, OR be pure 'xxxx'
    if (RegExp(r'^[xX]+$').hasMatch(accountNo)) return true;
    return RegExp(r'\d').hasMatch(accountNo);
  }

  String _sanitizeAccountNo(String str) {
    if (str.isEmpty) return '';
    // Strip non-alphanumeric characters
    final String sanitized = str.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    // If it's pure obfuscation like 'xxxx', return it
    if (RegExp(r'^[xX]+$').hasMatch(sanitized)) return sanitized;

    // Extract only the last 4+ digits for account matching
    final digitMatch = RegExp(r'\d{4,}$').firstMatch(sanitized);
    if (digitMatch != null) {
      return digitMatch.group(0)!;
    }

    // If no 4+ consecutive digits, try to get any digits
    final String digitsOnly = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }

    return '';
  }

  String getBalanceFromProcessed(String processedMsg) {
    String matchedKeyword = '';

    for (var keyword in balanceKeywords) {
      if (processedMsg.contains(keyword)) {
        matchedKeyword = keyword;
        break;
      }
    }

    if (matchedKeyword.isEmpty) return '';

    final searchStart =
        processedMsg.indexOf(matchedKeyword) + matchedKeyword.length;
    final int rsIndex = processedMsg.indexOf('rs.', searchStart);

    if (rsIndex == -1) {
      final match = RegExp(
        r'\d',
      ).firstMatch(processedMsg.substring(searchStart));
      if (match == null) return '';
      return _extractNumericPart(processedMsg, searchStart + match.start);
    }

    return _extractNumericPart(processedMsg, rsIndex + 3);
  }

  String _extractNumericPart(String message, int startIndex) {
    String result = '';
    bool sawDigit = false;
    bool sawDot = false;

    for (int i = startIndex; i < message.length; i++) {
      final char = message[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        sawDigit = true;
        result += char;
      } else if (char == '.' && !sawDot && sawDigit) {
        // Only add dot if followed by digit
        if (i + 1 < message.length &&
            RegExp(r'[0-9]').hasMatch(message[i + 1])) {
          sawDot = true;
          result += char;
        } else {
          break;
        }
      } else if (char == ',' && sawDigit) {
        continue;
      } else if (sawDigit) {
        break;
      }
    }
    return result;
  }

  DateTime? getTransactionTime(String message) {
    final dateOnlyMsg = message.replaceAll(':', ' ').replaceAll('/', '-');

    // Match "Dec 5 2025 2 14PM" format
    final monthNameRegex = RegExp(
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2})\s+(\d{1,2})\s*(am|pm)?',
      caseSensitive: false,
    );
    final dateTimeRegex = RegExp(
      r'(\d{2,4})-(\d{1,2})-(\d{2,4}) (\d{1,2}) (\d{1,2})( (\d{1,2}))?',
    );
    final dateRegex = RegExp(r'(\d{2,4})-(\d{1,2})-(\d{2,4})');

    try {
      if (monthNameRegex.hasMatch(dateOnlyMsg.toLowerCase())) {
        final match = monthNameRegex.firstMatch(dateOnlyMsg.toLowerCase())!;
        final monthStr = match.group(1)!.substring(0, 1).toUpperCase() + match.group(1)!.substring(1);
        final day = match.group(2)!;
        final year = match.group(3)!;
        var hour = int.parse(match.group(4)!);
        final minute = match.group(5)!;
        final ampm = match.group(6)?.toLowerCase();
        
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        
        return DateFormat('MMM d yyyy H m').parse('$monthStr $day $year $hour $minute');
      } else if (dateTimeRegex.hasMatch(dateOnlyMsg)) {
        final match = dateTimeRegex.stringMatch(dateOnlyMsg)!;
        final parts = match.trim().split(' ')..removeWhere((e) => e.isEmpty);
        if (match.startsWith(RegExp(r'\d{4}'))) {
          String format = 'yyyy-M-d H m';
          if (parts.length > 3) format += ' s';
          return DateFormat(format).parse(match, true);
        }
        String format = 'd-M-yyyy H m';
        if (parts.length > 3) format += ' s';
        return DateFormat(format).parse(match, true);
      } else if (dateRegex.hasMatch(dateOnlyMsg)) {
        final match = dateRegex.stringMatch(dateOnlyMsg)!;
        if (match.startsWith(RegExp(r'\d{4}'))) {
          return DateFormat('yyyy-M-d').parse(match);
        }
        if (match.contains(RegExp(r'-\d{4}$'))) {
          return DateFormat('d-M-yyyy').parse(match);
        }
        return DateFormat('d-M-yy').parse(match);
      }
    } catch (_) {}
    return null;
  }

  String? extractUPIRefNo(String fullMsg, bool isUpiTxn) {
    final lower = fullMsg.toLowerCase();
    if (isUpiTxn) {
      String result = lower
          .replaceAll('(', ' ')
          .replaceAll(')', ' ')
          .replaceAll('upi ref no', 'REF')
          .replaceAll('upi ref', 'REF')
          .replaceAll('ref no', 'REF')
          .replaceAll('rrn', 'REF');

      if (result.contains('REF')) {
        result = result.split('REF').last.trim();
        result = result.split(' ').first.split('.').first.replaceAll(':', '');
        return result;
      }
    } else {
      String result = lower
          .replaceAll('.', ' ')
          .replaceAll('tn', 'REF')
          .replaceAll('rrn', 'REF')
          .replaceAll('ref no', 'REF');
      if (result.contains('REF')) {
        result = result.split('REF').last.trim();
        result = result.split(' ').first.replaceAll(':', '');
        return result;
      }
    }
    return null;
  }

  bool _isNotNumeric(String str) {
    return double.tryParse(str.replaceAll(',', '')) == null;
  }
}

enum TransactionType { debited, credited, debitMisc, noMatch }

class AccountDetails {
  String? type;
  String? no;
  String? refNo;
  String? sendTo;
  String? bankName;
  AccountDetails({this.type, this.no, this.refNo, this.sendTo, this.bankName});

  @override
  String toString() =>
      'AccountDetails[type: $type, no: $no, refNo: $refNo, sendTo: $sendTo, bankName: $bankName]';
}

class TransactionInfo {
  AccountDetails? account;
  String? balance;
  String? money;
  TransactionType? typeOfTransaction;
  DateTime? transactionTime;
  String address;
  String sender;
  String body;
  String smsHash;
  bool isInternalTransfer; // Flag for transfers between own accounts

  TransactionInfo({
    this.account,
    this.balance,
    this.money,
    this.typeOfTransaction,
    this.transactionTime,
    required this.address,
    required this.sender,
    required this.body,
    this.smsHash = '',
    this.isInternalTransfer = false,
  });

  @override
  String toString() =>
      'TransactionInfo [account: $account, balance: $balance, money: $money, typeOfTransaction: $typeOfTransaction, transactionTime: $transactionTime, isInternalTransfer: $isInternalTransfer]';
}

bool checkForTransactionalMessage(String? body) {
  if (body == null || body.isEmpty) return false;
  final lower = body.toLowerCase();

  // Exclude percentage alerts (50% Alert, 90% Alert, 100% Alert)
  if (RegExp(r'\d+%\s*alert', caseSensitive: false).hasMatch(lower)) {
    return false;
  }

  // Exclude government/tax notifications
  final isGovtNotification =
      lower.contains('itr') ||
      lower.contains('income tax') ||
      lower.contains('pan:') ||
      lower.contains('cpc');

  if (isGovtNotification) return false;

  // Exclude loyalty points and rewards
  final isLoyaltyPoints =
      lower.contains('points') && (lower.contains('wallet') || lower.contains('reward')) ||
      lower.contains('cashback points') ||
      lower.contains('reward points') ||
      lower.contains('loyalty points');

  if (isLoyaltyPoints) return false;

  // Must have transaction keywords
  final hasTrn =
      lower.contains('debit') ||
      lower.contains('spent') ||
      lower.contains('credit') ||
      lower.contains('sent') ||
      lower.contains('paid') ||
      lower.contains('transfer') ||
      lower.contains('received') ||
      lower.contains('contribution') && RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower) ||
      lower.contains('successful') && RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower);

  if (!hasTrn) return false;

  // Exclude promotional/marketing messages with links
  final isPromo =
      lower.contains('explore now') ||
      lower.contains('plans starting') ||
      lower.contains('get ') && lower.contains('gb') ||
      lower.contains('offer') && lower.contains('http') ||
      lower.contains('upgrade') && lower.contains('http') ||
      lower.contains('subscribe') ||
      lower.contains('click here') ||
      lower.contains('please click') ||
      lower.contains('visit') && lower.contains('http') ||
      lower.contains('download app') ||
      lower.contains('to know more') ||
      lower.contains('facility') && lower.contains('enabled') ||
      lower.contains('loan') && lower.contains('enabled') ||
      lower.contains('shop for') && lower.contains('get') ||
      lower.contains('get best deals');

  // Exclude data usage alerts (in English and regional languages)
  final isDataAlert =
      lower.contains('data limit') ||
      lower.contains('data usage') ||
      lower.contains('high speed data') ||
      lower.contains('data balance') ||
      lower.contains('data pack') ||
      lower.contains('data running low') ||
      lower.contains('data carry-forward') ||
      lower.contains('consumed') && lower.contains('data') ||
      lower.contains('track usage') ||
      lower.contains('validity') && !lower.contains('successful') ||
      lower.contains('recharge') && !lower.contains('successful') && !RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower) ||
      lower.contains('talktime') && !lower.contains('successful') ||
      lower.contains('mb left') ||
      lower.contains('gb left') ||
      lower.contains('expires on') ||
      lower.contains('unlimited pack') && !RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower) ||
      lower.contains('welcome back') && lower.contains('pack');

  // Exclude future/pending transactions
  final isFuture =
      lower.contains('will be debited') ||
      lower.contains('will be credited') ||
      lower.contains('to be debited') ||
      lower.contains('to be credited') ||
      lower.contains('request') ||
      lower.contains('pending') ||
      lower.contains('authorization') ||
      lower.contains('hold') ||
      lower.contains('mandate') && lower.contains('created') ||
      lower.contains('autopay') && lower.contains('created');

  // Exclude bill reminders and due payments
  final isBillReminder =
      lower.contains('due') ||
      lower.contains('pay by') ||
      lower.contains('payment due') ||
      lower.contains('bill due') ||
      lower.contains('minimum due') ||
      lower.contains('total due') ||
      lower.contains('outstanding') ||
      lower.contains('overdue') ||
      lower.contains('reminder');

  // Exclude payment receipts/confirmations (only if no amount or purely informational)
  final isReceipt =
      lower.contains('payment receipt') && !RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower) ||
      lower.contains('download the') && lower.contains('receipt') && !RegExp(r'rs\.?\s*\d|inr\s*\d').hasMatch(lower);

  // Exclude OTP and verification messages
  final isOTP =
      lower.contains('otp') ||
      lower.contains('verification code') ||
      lower.contains('verify') ||
      lower.contains('consented') ||
      lower.contains('consent') && lower.contains('share');

  return !isPromo && !isDataAlert && !isFuture && !isBillReminder && !isReceipt && !isOTP;
}

String generateSmsHash(String address, int? date, String body) {
  final input = '$address|$date|$body';
  return sha256.convert(utf8.encode(input)).toString();
}

/// Detects and marks internal transfers between user's own accounts
/// Call this after loading all transactions to identify transfer pairs
List<TransactionInfo> detectInternalTransfers(List<TransactionInfo> transactions) {
  final List<TransactionInfo> result = List.from(transactions);
  
  for (int i = 0; i < result.length; i++) {
    final txn = result[i];
    if (txn.isInternalTransfer || txn.money == null || txn.money!.isEmpty) continue;
    
    // Look for matching opposite transaction on same date
    for (int j = i + 1; j < result.length; j++) {
      final other = result[j];
      if (other.isInternalTransfer || other.money == null || other.money!.isEmpty) continue;
      
      // Check if amounts match
      if (txn.money != other.money) continue;
      
      // Check if one is debit and other is credit
      final isOpposite = 
          (txn.typeOfTransaction == TransactionType.debited && 
           other.typeOfTransaction == TransactionType.credited) ||
          (txn.typeOfTransaction == TransactionType.credited && 
           other.typeOfTransaction == TransactionType.debited);
      
      if (!isOpposite) continue;
      
      // Check if on same date
      if (txn.transactionTime != null && other.transactionTime != null) {
        final sameDate = 
            txn.transactionTime!.year == other.transactionTime!.year &&
            txn.transactionTime!.month == other.transactionTime!.month &&
            txn.transactionTime!.day == other.transactionTime!.day;
        
        if (sameDate) {
          result[i] = TransactionInfo(
            account: txn.account,
            balance: txn.balance,
            money: txn.money,
            typeOfTransaction: txn.typeOfTransaction,
            transactionTime: txn.transactionTime,
            address: txn.address,
            sender: txn.sender,
            body: txn.body,
            smsHash: txn.smsHash,
            isInternalTransfer: true,
          );
          result[j] = TransactionInfo(
            account: other.account,
            balance: other.balance,
            money: other.money,
            typeOfTransaction: other.typeOfTransaction,
            transactionTime: other.transactionTime,
            address: other.address,
            sender: other.sender,
            body: other.body,
            smsHash: other.smsHash,
            isInternalTransfer: true,
          );
          break;
        }
      }
    }
  }
  
  return result;
}
