import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class TransactionUtil {
  static final upiRegex = RegExp(r'[\w.-]+@[\w.-]+');
  static const balanceKeywords = [
    'avbl bal',
    'available balance',
    'a/c bal',
    'available bal',
    'avl bal',
    'avail bal',
    'curr bal',
    'total bal',
    'bal',
  ];
  static const trnKeywords = ['debited', 'credited', 'payment', 'spent'];

  static final creditPattern = RegExp(r'credited|credit|deposited');
  static final debitPattern = RegExp(r'debited|debit|deducted');
  static final miscPattern = RegExp(r'payment|spent');

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
    // Standardize account terms first
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
    var info = TransactionInfo(
      address: address ?? '',
      sender: sender ?? '',
      body: message ?? '',
      smsHash: smsHash,
    );

    if (message == null || message.isEmpty) return info;

    info.transactionTime = getTransactionTime(message);
    final processedWords = processMessage(message);
    final fullProcessed = processedWords.join(' ');

    info.account = getAccountFromWords(processedWords, fullProcessed);
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
    if (index == -1 || index + 1 >= words.length) return '';

    String amount = words[index + 1].replaceAll(',', '');
    // Strip trailing punctuation
    amount = amount.replaceAll(RegExp(r'[^\d]+$'), '');

    if (_isNotNumeric(amount) && index + 2 < words.length) {
      amount = words[index + 2].replaceAll(',', '');
      amount = amount.replaceAll(RegExp(r'[^\d]+$'), '');
    }

    return _isNotNumeric(amount) ? '' : amount;
  }

  AccountDetails getAccountFromWords(List<String> words, String fullProcessed) {
    var account = AccountDetails();

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

      bool isCard = word == 'card';
      bool isAc = word == 'ac';

      if (isCard || isAc) {
        int nextIdx = i + 1;
        // Skip possible connector words: 'ends', 'ending', 'with', 'no', '.', ':', '#'
        while (nextIdx < words.length &&
            (words[nextIdx] == 'ends' ||
                words[nextIdx] == 'ending' ||
                words[nextIdx] == 'with' ||
                words[nextIdx] == 'no' ||
                words[nextIdx] == 'nos' ||
                words[nextIdx] == '.' ||
                words[nextIdx] == '#' ||
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

      if (word.startsWith('x') ||
          (word.length >= 2 && word.substring(0, 2) == 'ac')) {
        final accountNo = _sanitizeAccountNo(word);
        if (accountNo.isNotEmpty && _isValidAccountNumber(accountNo)) {
          account.type = 'account';
          account.no = accountNo;
          account.refNo = extractUPIRefNo(fullProcessed, false);
          return account;
        }
      }
    }
    return account;
  }

  bool _isValidAccountNumber(String accountNo) {
    // Must contain at least one digit, OR be pure 'xxxx'
    if (RegExp(r'^[xX]+$').hasMatch(accountNo)) return true;
    return RegExp(r'\d').hasMatch(accountNo);
  }

  String _sanitizeAccountNo(String str) {
    if (str.isEmpty) return '';
    // Strip non-alphanumeric characters
    String sanitized = str.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    // If it's pure obfuscation like 'xxxx', return it
    if (RegExp(r'^[xX]+$').hasMatch(sanitized)) return sanitized;
    // Strip leading 'x', 'ac', etc. but keep digits
    String digitsOnly = sanitized.replaceFirst(RegExp(r'^[xa-z]+'), '');
    if (digitsOnly.isNotEmpty) return digitsOnly;
    return sanitized;
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
    int rsIndex = processedMsg.indexOf('rs.', searchStart);

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
        sawDot = true;
        result += char;
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

    final dateTimeRegex = RegExp(
      r'(\d{2,4})-(\d{1,2})-(\d{2,4}) (\d{1,2}) (\d{1,2})( (\d{1,2}))?',
    );
    final dateRegex = RegExp(r'(\d{2,4})-(\d{1,2})-(\d{2,4})');

    try {
      if (dateTimeRegex.hasMatch(dateOnlyMsg)) {
        final match = dateTimeRegex.stringMatch(dateOnlyMsg)!;
        final parts = match.trim().split(' ')..removeWhere((e) => e.isEmpty);
        if (match.startsWith(RegExp(r'\d{4}'))) {
          // YYYY-M-D H m s
          String format = 'yyyy-M-d H m';
          if (parts.length > 3) format += ' s';
          return DateFormat(format).parse(match, true);
        }
        // D-M-YYYY H m s
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
          .replaceAll('ref no', 'REF');

      if (result.contains('REF')) {
        result = result.split('REF').last.trim();
        result = result.split(' ').first.split('.').first;
        return result;
      }
    } else {
      String result = lower
          .replaceAll('.', ' ')
          .replaceAll('tn', 'REF')
          .replaceAll('ref no', 'REF');
      if (result.contains('REF')) {
        result = result.split('REF').last.trim();
        result = result.split(' ').first;
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
  AccountDetails({this.type, this.no, this.refNo, this.sendTo});

  @override
  String toString() =>
      'AccountDetails[type: $type, no: $no, refNo: $refNo, sendTo: $sendTo]';
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
  });

  @override
  String toString() =>
      'TransactionInfo [account: $account, balance: $balance, money: $money, typeOfTransaction: $typeOfTransaction, transactionTime: $transactionTime]';
}

bool checkForTransactionalMessage(String? body) {
  if (body == null || body.isEmpty) return false;
  final lower = body.toLowerCase();
  final hasTrn =
      lower.contains('debit') ||
      lower.contains('spent') ||
      lower.contains('credit');
  final isNotIrrelevant =
      !lower.contains('request') && !lower.contains('pending');
  return hasTrn && isNotIrrelevant;
}

String generateSmsHash(String address, int? date, String body) {
  final input = '$address|$date|$body';
  return sha256.convert(utf8.encode(input)).toString();
}
