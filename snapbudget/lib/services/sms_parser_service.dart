// lib/services/sms_parser_service.dart
//
// Pure-Dart, zero-dependency SMS parser.
// No Flutter, no Firebase, no network — 100% offline regex NLP.
//
// Usage:
//   final result = SmsParserService.parse(sender: 'HDFCBK', body: '...', receivedAt: DateTime.now());
//   if (result != null) { /* financial SMS detected */ }

import 'dart:convert';
import '../models/sms_transaction_model.dart';
import '../models/transaction_model.dart';

class SmsParseResult {
  final double amount;
  final bool isDebit;
  final String merchant;
  final String? vpa;
  final String? referenceId;
  final String? accountLast4;
  final TransactionCategory category;
  final double confidence;
  final String senderBank;

  const SmsParseResult({
    required this.amount,
    required this.isDebit,
    required this.merchant,
    this.vpa,
    this.referenceId,
    this.accountLast4,
    required this.category,
    required this.confidence,
    required this.senderBank,
  });
}

class SmsParserService {
  SmsParserService._();

  // ─── Known bank sender IDs ────────────────────────────────────────────────
  static const _bankNames = {
    'HDFCBK': 'HDFC Bank',
    'HDFCBN': 'HDFC Bank',
    'ICICIB': 'ICICI Bank',
    'ICICIBK': 'ICICI Bank',
    'SBISMS': 'SBI',
    'SBIINB': 'SBI',
    'AXISBK': 'Axis Bank',
    'AXISBN': 'Axis Bank',
    'KOTAKB': 'Kotak Bank',
    'KOTBK': 'Kotak Bank',
    'YESBNK': 'Yes Bank',
    'INDBNK': 'Indian Bank',
    'PNBSMS': 'PNB',
    'BOISMS': 'Bank of India',
    'CBSSBI': 'SBI',
    'PAYTMB': 'Paytm Bank',
    'PAYTM': 'Paytm',
    'GPAYBN': 'Google Pay',
    'PHONEPE': 'PhonePe',
    'AMZPAY': 'Amazon Pay',
    'IDFCBK': 'IDFC Bank',
    'RBLBNK': 'RBL Bank',
    'CANBNK': 'Canara Bank',
    'UNIONB': 'Union Bank',
    'CENTBK': 'Central Bank',
  };

  // ─── Pre-filter keywords ──────────────────────────────────────────────────

  static const _financialKeywords = [
    'debited', 'credited', 'debit', 'credit',
    'paid', 'payment', 'received', 'transferred',
    'withdrawn', 'purchase', 'spent', 'txn',
    'transaction', 'upi', 'neft', 'imps', 'rtgs',
    '₹', 'rs.', 'inr', 'rupees',
  ];

  static const _discardKeywords = [
    'otp', 'one time password', 'verification code',
    'do not share', 'failed', 'declined', 'reversed',
    'expired', 'invalid', 'unsuccessful',
    'congratulations', 'offer', 'win ', 'won ',
    'click here', 'avail', 'cashback offer',
  ];

  // ─── Amount regex ─────────────────────────────────────────────────────────
  // Matches: ₹1,234.56 / Rs.1234 / INR 5,00,000 / Rs 500.00
  static final _amountRe = RegExp(
    r'(?:₹|rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  // ─── Transaction type regex ───────────────────────────────────────────────
  static final _debitRe = RegExp(
    r'\b(?:debited|debit|paid|payment|purchase|spent|withdrawn|sent|transferred to)\b',
    caseSensitive: false,
  );
  static final _creditRe = RegExp(
    r'\b(?:credited|credit|received|refund|reversal|cashback)\b',
    caseSensitive: false,
  );

  // ─── Merchant / VPA ───────────────────────────────────────────────────────
  static final _atMerchantRe = RegExp(
    r'(?:at|to|from|by)\s+([A-Za-z0-9 &\-_./]{2,30}?)(?:\s+on|\s+ref|\s+upi|\s+for|\.|\,|$)',
    caseSensitive: false,
  );
  static final _vpaRe = RegExp(
    r'([a-z0-9.\-_+]+@[a-z]{3,})',
    caseSensitive: false,
  );

  // ─── Reference ID ─────────────────────────────────────────────────────────
  static final _refRe = RegExp(
    r'(?:ref(?:erence)?\.?\s*(?:no\.?|id\.?)?|upi\s*ref|txn\.?\s*(?:id)?|transaction\s*id)\s*:?\s*([A-Z0-9]{8,20})',
    caseSensitive: false,
  );

  // ─── Account number ───────────────────────────────────────────────────────
  static final _accountRe = RegExp(
    r'(?:a/?c|account|card|ac)[\s\w]*?(?:xx|[xX*]{2})([0-9]{4})',
    caseSensitive: false,
  );

  // ─── Main entry ──────────────────────────────────────────────────────────

  /// Returns `null` if the SMS is not financial or below confidence threshold.
  static SmsParseResult? parse({
    required String sender,
    required String body,
    required DateTime receivedAt,
  }) {
    // 1. Fast pre-filter
    if (!_isFinancialSms(body)) return null;

    final lower = body.toLowerCase();

    // 2. Amount
    final amountMatch = _amountRe.firstMatch(lower);
    if (amountMatch == null) return null;
    final rawAmount = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    // 3. Transaction direction
    final isDebit = _debitRe.hasMatch(lower) && !_creditRe.hasMatch(lower)
        ? true
        : _creditRe.hasMatch(lower)
            ? false
            : true; // default to debit

    // 4. Merchant / VPA
    final vpaMatch = _vpaRe.firstMatch(body);
    final vpa = vpaMatch?.group(1);

    String merchant = '';
    if (vpa != null) {
      // Derive a friendly name from the VPA (e.g. uber@okicici → Uber)
      merchant = _merchantFromVpa(vpa);
    }
    if (merchant.isEmpty) {
      final atMatch = _atMerchantRe.firstMatch(body);
      if (atMatch != null) merchant = atMatch.group(1)!.trim();
    }
    if (merchant.isEmpty) merchant = _bankNameFromSender(sender);

    // 5. Reference ID
    final refMatch = _refRe.firstMatch(body);
    final referenceId = refMatch?.group(1);

    // 6. Account last 4
    final accMatch = _accountRe.firstMatch(lower);
    final accountLast4 = accMatch?.group(1);

    // 7. Category inference
    final category = _inferCategory(merchant, lower);

    // 8. Bank name
    final senderBank = _bankNameFromSender(sender);

    // 9. Confidence score
    double confidence = 0.0;
    if (amount > 0) confidence += 0.4;
    if (_debitRe.hasMatch(lower) || _creditRe.hasMatch(lower)) confidence += 0.2;
    if (merchant.isNotEmpty && merchant != senderBank) confidence += 0.2;
    if (referenceId != null) confidence += 0.1;
    if (accountLast4 != null) confidence += 0.1;

    if (confidence < 0.4) return null;

    return SmsParseResult(
      amount: amount,
      isDebit: isDebit,
      merchant: merchant,
      vpa: vpa,
      referenceId: referenceId,
      accountLast4: accountLast4,
      category: category,
      confidence: confidence.clamp(0.0, 1.0),
      senderBank: senderBank,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static bool _isFinancialSms(String body) {
    // Must be a reasonable length
    if (body.length < 25 || body.length > 600) return false;

    final lower = body.toLowerCase();

    // Discard if any discard keyword found
    for (final kw in _discardKeywords) {
      if (lower.contains(kw)) return false;
    }

    // Must contain at least one financial keyword
    for (final kw in _financialKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  static String _bankNameFromSender(String sender) {
    final upper = sender.toUpperCase();
    for (final entry in _bankNames.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    // Alphanumeric senders (not personal numbers) are likely banks
    if (RegExp(r'^[A-Z]{2,}').hasMatch(upper)) return sender;
    return 'Bank';
  }

  static String _merchantFromVpa(String vpa) {
    // e.g. uberindiaX@okicici → Uber India
    final handle = vpa.split('@').first;
    // Strip trailing digits and special chars
    final cleaned = handle.replaceAll(RegExp(r'[0-9_.\-+]+$'), '').trim();
    if (cleaned.isEmpty) return '';
    // Title-case
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }

  static TransactionCategory _inferCategory(String merchant, String body) {
    final m = merchant.toLowerCase();
    final b = body.toLowerCase();
    final combined = '$m $b';

    if (_containsAny(combined, [
      'swiggy', 'zomato', 'food', 'restaurant', 'cafe', 'lunch', 'dinner',
      'breakfast', 'eat', 'dining', 'bake', 'pizza', 'biryani', 'burger',
      'nashta', 'chai',
    ])) return TransactionCategory.food;

    if (_containsAny(combined, [
      'uber', 'ola', 'rapido', 'auto', 'taxi', 'metro', 'bus', 'irctc',
      'petrol', 'fuel', 'transport', 'cab', 'ride',
    ])) return TransactionCategory.transport;

    if (_containsAny(combined, [
      'amazon', 'flipkart', 'myntra', 'meesho', 'nykaa', 'ajio', 'shop',
      'mall', 'store', 'market', 'purchase', 'order',
    ])) return TransactionCategory.shopping;

    if (_containsAny(combined, [
      'netflix', 'spotify', 'prime', 'hotstar', 'movie', 'cinema', 'pvr',
      'inox', 'game', 'gaming', 'entertainment', 'bookmyshow',
    ])) return TransactionCategory.entertainment;

    if (_containsAny(combined, [
      'hospital', 'clinic', 'medical', 'pharmacy', 'medicine', 'doctor',
      'health', 'apollo', 'netmeds', '1mg', 'lab',
    ])) return TransactionCategory.health;

    if (_containsAny(combined, [
      'electricity', 'jio', 'airtel', 'vi ', 'bsnl', 'broadband', 'wifi',
      'internet', 'dth', 'recharge', 'utility', 'gas', 'water bill',
    ])) return TransactionCategory.utilities;

    if (_containsAny(combined, [
      'rent', 'housing', 'flat', 'apartment', 'maintenance', 'society',
    ])) return TransactionCategory.housing;

    if (_containsAny(combined, [
      'school', 'college', 'university', 'fee', 'tuition', 'course',
      'education', 'book', 'udemy', 'coursera',
    ])) return TransactionCategory.education;

    if (_containsAny(combined, [
      'hotel', 'flight', 'air', 'makemytrip', 'oyo', 'goibibo', 'travel',
      'holiday', 'booking.com', 'trip',
    ])) return TransactionCategory.travel;

    if (_containsAny(combined, [
      'salary', 'payroll', 'credited by employer',
    ])) return TransactionCategory.salary;

    if (_containsAny(combined, [
      'mutual fund', 'sip', 'zerodha', 'groww', 'shares', 'stock', 'demat',
      'investment', 'fd ', 'fixed deposit',
    ])) return TransactionCategory.investment;

    return TransactionCategory.other;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  /// Builds a stable dedupe hash: sender + rounded-minute-epoch + amount.
  static String buildDedupeHash({
    required String sender,
    required double amount,
    required DateTime receivedAt,
  }) {
    // Round down to the nearest minute so duplicates within 1 min are caught.
    final minuteEpoch =
        (receivedAt.millisecondsSinceEpoch ~/ 60000) * 60000;
    final raw = '$sender|$amount|$minuteEpoch';
    // Simple base64 of UTF8 bytes as a lightweight, dependency-free hash
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  /// Converts an [SmsParseResult] into an [SmsTransactionModel] ready to save.
  static SmsTransactionModel toModel({
    required SmsParseResult result,
    required String rawBody,
    required String senderId,
    required DateTime receivedAt,
    required String userId,
  }) {
    final dedupeHash = buildDedupeHash(
      sender: senderId,
      amount: result.amount,
      receivedAt: receivedAt,
    );
    return SmsTransactionModel(
      smsId: '${userId}_$dedupeHash',
      userId: userId,
      senderBank: result.senderBank,
      messageText: rawBody,
      receivedAt: receivedAt,
      amount: result.amount,
      merchant: result.merchant,
      vpa: result.vpa,
      referenceId: result.referenceId,
      accountLast4: result.accountLast4,
      isDebit: result.isDebit,
      category: result.category.name,
      confidence: result.confidence,
      status: SmsStatus.pending,
      dedupeHash: dedupeHash,
    );
  }
}
