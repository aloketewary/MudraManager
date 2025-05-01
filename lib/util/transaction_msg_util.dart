import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/util/string_util.dart';

class TransactionUtil {
  static final upiRegex = RegExp(r'[\w.-]+@[\w.-]+');
  static const balanceKeywords = [
    'avbl bal',
    'available balance',
    'a/c bal',
    'available bal',
    'avl bal',
    'curr bal',
  ];
  static const trnKeywords = ['debited', 'credited', 'payment', 'spent'];

  TransactionType getTypeOfTransaction(String? message) {
    RegExp creditPattern = RegExp(r'credited|credit|deposited');
    RegExp debitPattern = RegExp(r"debited|debit|deducted");
    RegExp miscPattern = RegExp(r'payment|spent');
    if (message == null || message.isEmpty) {
      return TransactionType.noMatch;
    }
    if (debitPattern.hasMatch(message)) {
      return TransactionType.debited;
    } else if (creditPattern.hasMatch(message)) {
      return TransactionType.credited;
    } else if (miscPattern.hasMatch(message)) {
      return TransactionType.debitMisc;
    }
    return TransactionType.noMatch;
  }

  getCard(String? message) {
    final messageList = processMessage(message);
    final cardIndex = messageList.indexOf('card');
    final card = CardDetails();

    // Search for "card" and if not found return empty obj
    if (cardIndex != -1) {
      card.no = messageList[cardIndex + 1];
      card.type = 'card';

      // If the data is false positive
      // return empty obj
      // Else return the card info
      if (int.tryParse(card.no ?? '')?.isNaN ?? true) {
        return CardDetails();
      } else {
        return card;
      }
    } else {
      return card;
    }
  }

  String extractBondedAccountNo(String? accountNo) {
    final strippedAccountNo = accountNo?.replaceAll('ac', '') ?? '';

    if (int.tryParse(strippedAccountNo)?.isNaN ?? true) {
      return '';
    } else {
      return strippedAccountNo;
    }
  }

  List<String> processMessage(String? message) {
    // convert to lower case
    message = message?.toLowerCase();
    // remove '-'
    message = message?.replaceAll(RegExp(r'-'), '');
    // remove ':'
    message = message?.replaceAll(RegExp(r':'), '');
    // remove '/'
    message = message?.replaceAll(RegExp(r'/'), '');
    // remove 'ending'
    message = message?.replaceAll(RegExp(r'ending '), '');
    // replace 'x'
    message = message?.replaceAll(RegExp(r'x|[*]'), '');
    // // remove 'is' 'with'
    // message = message.replace(/\bis\b|\bwith\b/g, '');
    // replace 'is'
    message = message?.replaceAll(RegExp(r'is '), '');
    // replace 'with'
    message = message?.replaceAll(RegExp(r'with '), '');
    // remove 'no.'
    message = message?.replaceAll(RegExp(r'no. '), '');
    // replace all ac, acct, account with ac
    message = message?.replaceAll(RegExp(r'\bac\b|\bacct\b|\baccount\b'), 'ac');
    // replace all 'rs' with 'rs. '
    message = message?.replaceAll(RegExp(r'rs(?=\w)'), 'rs. ');
    // replace all 'rs ' with 'rs. '
    message = message?.replaceAll(RegExp(r'rs '), 'rs. ');
    // replace all inr with rs.
    message = message?.replaceAll(RegExp(r'inr(?=\w)'), 'rs. ');
    //
    message = message?.replaceAll(RegExp(r'inr '), 'rs. ');
    // replace all 'rs. ' with 'rs.'
    message = message?.replaceAll(RegExp(r'rs. '), 'rs.');
    // replace all 'rs.' with 'rs. '
    message = message?.replaceAll(RegExp(r'rs.(?=\w)'), 'rs. ');
    // split message into words
    var messageList = message?.split(' ') ?? [];
    // remove '' from array
    messageList = removeItemAll(messageList, '');

    return messageList;
  }

  List<String> removeItemAll(List<String> arr, String value) {
    var i = 0;
    while (i < arr.length) {
      if (arr[i] == value) {
        arr.removeAt(i);
      } else {
        ++i;
      }
    }
    return arr;
  }

  TransactionInfo getTransactionInfo(
    String? message,
    String? address,
    String? sender,
    String smsHash,
  ) {
    var trn = TransactionInfo(
      address: address ?? '',
      sender: sender ?? '',
      body: message ?? '',
      smsHash: smsHash,
    );
    if (message == null) {
      return trn;
    }
    trn.transactionTime = getTransactionTime(message);
    final processedMessage = processMessage(message);
    trn.account = getAccount(processedMessage);
    trn.balance = getBalance(processedMessage.join(' '));
    trn.money = getMoneySpent(processedMessage);
    final isValid =
        [trn.balance, trn.money, trn.account].where((x) => x != '').length >= 2;

    if (isValid) {
      trn.typeOfTransaction = getTypeOfTransaction(processedMessage.join(' '));
    }

    return trn;
  }

  String getMoneySpent(List<String> message) {
    message = processMessage(message.join(' '));

    var index = message.indexOf('rs.');

    // If "rs." does not exist
    // Return ""
    if (index == -1) {
      return '';
    } else {
      var money = message[index + 1];

      money = money.replaceAll(RegExp(r','), '');

      // If data is false positive
      // Look ahead one index and check for valid money
      // Else return the found money
      if (money.isNan()) {
        money = message[index + 2];
        money = money.replaceAll(RegExp(r','), '');

        // If this is also false positive, return ""
        // Else return the found money
        if (money.isNan()) {
          return '';
        } else {
          return money;
        }
      } else {
        return money;
      }
    }
  }

  AccountDetails getAccount(List<String> message) {
    message = processMessage(message.join(' '));

    var accountIndex = -1;
    var account = AccountDetails();
    var index = 0;
    var fullMsg = message.join(' ');
    if (upiRegex.hasMatch(fullMsg)) {
      account.type = 'UPI';
      account.no = 'N/A';
      account.sendTo = upiRegex.stringMatch(fullMsg);
      account.refNo = extractUPIRefNo(fullMsg, true);
      return account;
    }
    for (var word in message) {
      if (word == 'ac') {
        if (index + 1 < message.length) {
          final accountNo = trimLeadingAndTrailingChars(message[index + 1]);
          if (int.tryParse(accountNo)?.isNaN ?? false) {
            // continue searching for a valid account number
            continue;
          } else {
            accountIndex = index;
            account.type = 'account';
            account.no = accountNo;
            account.refNo = extractUPIRefNo(fullMsg, false);
            return account;
          }
        } else {
          // continue searching for a valid account number
          continue;
        }
      } else if (word.contains('ac')) {
        final extractedAccountNo = extractBondedAccountNo(word);

        if (extractedAccountNo == '') {
          continue;
        } else {
          accountIndex = index;
          account.type = 'account';
          account.no = extractedAccountNo;
          account.refNo = extractUPIRefNo(fullMsg, false);
          return account;
        }
      }
      index += 1;
    }
    return account;
  }

  String getBalance(String? message) {
    var balance = '';
    if (message?.isEmpty ?? true) {
      return balance;
    }
    message = processMessage(message).join(' ');
    var indexOfKeyword = -1;

    for (var word in balanceKeywords) {
      indexOfKeyword = message.indexOf(word);

      if (indexOfKeyword != -1) {
        indexOfKeyword += word.length;
        break;
      } else {
        continue;
      }
    }
    // send blank balance
    if (indexOfKeyword == -1) {
      return balance;
    }
    // found the index of keyword, moving on to finding 'rs.' occuring after index_of_keyword
    var index = indexOfKeyword;
    var indexOfRs = -1;
    var nextThreeChars = message.substring(index, index + 4);

    index += 3;

    while (index < message.length) {
      // discard first char
      nextThreeChars = nextThreeChars.substring(1);
      // add the current char at the end

      if (nextThreeChars == 'rs.') {
        indexOfRs = index + 2;
        break;
      }
      nextThreeChars += message[index];
      ++index;
    }

    // no occurence of 'rs.'
    if (indexOfRs == -1) {
      return '';
    }

    balance = extractBalance(indexOfRs, message, message.length);

    return balance;
  }

  String trimLeadingAndTrailingChars(String str) {
    final firstLast = [str[0], str[str.length - 1]];
    final first = firstLast[0];
    final last = firstLast[1];
    if (last.isNan()) {
      str = str.substring(0);
    }
    if (first.isNan()) {
      str = str.substring(1);
    }
    return str;
  }

  String extractBalance(int index, String? message, int length) {
    var balance = '';
    var sawNumber = false;
    var invalidCharCount = 0;
    var char = '';

    while (index < length) {
      char = message?[index] ?? '';

      if ('0'.toInt() <= char.toInt(defaultValue: -1) &&
          char.toInt(defaultValue: -1) <= '9'.toInt()) {
        sawNumber = true;
        // is_start = false;
        balance += char;
      } else {
        if (sawNumber == false) {
        } else {
          if (char == '.') {
            if (invalidCharCount == 1) {
              break;
            } else {
              balance += char;
              invalidCharCount += 1;
            }
          } else if (char != ",") {
            break;
          }
        }
      }

      ++index;
    }

    return balance;
  }

  DateTime? getTransactionTime(String? message) {
    DateTime? dateTime;
    if (message != null && message.isNotEmpty) {
      var dateTimeRegex = RegExp(
        r'(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2})?((:)?(\d{1,2}))',
      );
      var dateRegex = RegExp(r'(\d{2})-(\d{2})-(\d{2})');
      var dateFullYearRegex = RegExp(r'(\d{2})-(\d{2})-(\d{4})');
      if (dateTimeRegex.hasMatch(message)) {
        var dateTimeStr = dateTimeRegex.stringMatch(message);
        // message.replaceAll(regExp, '');
        try {
          dateTime = DateFormat('dd-MM-yyyy hh:mm:ss').parse(dateTimeStr!);
        } catch (error) {
          dateTime = DateFormat('dd-MM-yyyy hh:mm').parse(dateTimeStr!);
        }
      } else if (dateRegex.hasMatch(message)) {
        var dateTimeStr = dateRegex.stringMatch(message);
        // message.replaceAll(regExp, '');
        dateTime = DateFormat('dd-MM-yy').parse(dateTimeStr!);
      } else if (dateFullYearRegex.hasMatch(message)) {
        var dateTimeStr = dateFullYearRegex.stringMatch(message);
        // message.replaceAll(regExp, '');
        dateTime = DateFormat('dd-MM-yyyy').parse(dateTimeStr!);
      }
    }
    return dateTime;
  }

  String? extractUPIRefNo(String fullMsg, bool isUpiTxn) {
    fullMsg = fullMsg.toLowerCase();
    if (isUpiTxn) {
      fullMsg = fullMsg.replaceAll('(', ' ');
      fullMsg = fullMsg.replaceAll(')', '#');
      var finalMsg = fullMsg.replaceAll('upi ref no', '#');
      return finalMsg.subStringAfter('#').trim().subStringBefore("#").trim();
    } else {
      fullMsg = fullMsg.replaceAll('.', ' ');
      var finalMsg = fullMsg.replaceAll('tn', '#');
      return finalMsg
          .subStringAfter('#')
          .trimLeft()
          .subStringBefore(" ")
          .trim();
    }
  }
}

enum TransactionType { debited, credited, debitMisc, noMatch }

class CardDetails {
  String? type;
  String? no;

  CardDetails({this.type, this.no});
}

class AccountDetails {
  String? type;
  String? no;
  String? refNo;
  String? sendTo;

  AccountDetails({this.type, this.no, this.refNo, this.sendTo});

  @override
  String toString() {
    return 'AccountDetails[type: $type, no: $no, refNo: $refNo, sendTo: $sendTo]';
  }
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
  String toString() {
    return 'TransactionInfo [account: $account, balance: $balance, money: $money, typeOfTransaction: $typeOfTransaction, transactionTime: $transactionTime]';
  }
}

bool checkForTransactionalMessage(String? body) {
  final smsBody = body ?? '';
  return (smsBody.contains('debit') ||
      smsBody.contains('spent') ||
      smsBody.contains('credit')) &&
      !smsBody.contains('request') &&
      !smsBody.contains('pending');
}

String generateSmsHash(String address, int? date, String body) {
  final input = '$address|$date|$body';
  return sha256.convert(utf8.encode(input)).toString();
}