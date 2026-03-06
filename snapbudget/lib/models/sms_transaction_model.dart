/// Status lifecycle for an SMS-detected transaction.
enum SmsStatus { pending, accepted, ignored }

class SmsTransactionModel {
  final String smsId;
  final String userId;

  // Raw data
  final String senderBank;
  final String messageText;
  final DateTime receivedAt;

  // Parsed fields
  final double amount;
  final String merchant;
  final String? vpa;           // UPI VPA if present (e.g. uber@okicici)
  final String? referenceId;   // UPI Ref / Txn ID
  final String? accountLast4;  // Last 4 digits of account/card
  final bool isDebit;          // true = expense, false = income
  final String category;
  final String paymentMethod;  // PaymentMethod enum name (upi, card, cash, etc.)

  // Confidence score 0.0–1.0
  final double confidence;

  // Review status
  final SmsStatus status;

  // Set once "accepted" and linked to a Transaction doc
  final String? linkedTxId;

  // Duplicate-guard hash: (sender + amount + minute-epoch)
  final String dedupeHash;

  SmsTransactionModel({
    required this.smsId,
    required this.userId,
    required this.senderBank,
    required this.messageText,
    DateTime? receivedAt,
    required this.amount,
    required this.merchant,
    this.vpa,
    this.referenceId,
    this.accountLast4,
    required this.isDebit,
    required this.category,
    this.paymentMethod = 'upi',
    required this.confidence,
    this.status = SmsStatus.pending,
    this.linkedTxId,
    required this.dedupeHash,
  }) : receivedAt = receivedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'senderBank': senderBank,
        'messageText': messageText,
        'receivedAt': receivedAt.toIso8601String(),
        'amount': amount,
        'merchant': merchant,
        'vpa': vpa,
        'referenceId': referenceId,
        'accountLast4': accountLast4,
        'isDebit': isDebit,
        'category': category,
        'paymentMethod': paymentMethod,
        'confidence': confidence,
        'status': status.name,
        'linkedTxId': linkedTxId,
        'dedupeHash': dedupeHash,
      };

  factory SmsTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SmsTransactionModel(
      smsId: docId,
      userId: map['userId'] ?? '',
      senderBank: map['senderBank'] ?? '',
      messageText: map['messageText'] ?? '',
      receivedAt: map['receivedAt'] != null
          ? DateTime.parse(map['receivedAt'])
          : DateTime.now(),
      amount: (map['amount'] ?? 0).toDouble(),
      merchant: map['merchant'] ?? '',
      vpa: map['vpa'],
      referenceId: map['referenceId'],
      accountLast4: map['accountLast4'],
      isDebit: map['isDebit'] ?? true,
      category: map['category'] ?? 'other',
      paymentMethod: map['paymentMethod'] ?? 'upi',
      confidence: (map['confidence'] ?? 0).toDouble(),
      status: SmsStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SmsStatus.pending,
      ),
      linkedTxId: map['linkedTxId'],
      dedupeHash: map['dedupeHash'] ?? '',
    );
  }

  SmsTransactionModel copyWith({
    SmsStatus? status,
    String? linkedTxId,
  }) =>
      SmsTransactionModel(
        smsId: smsId,
        userId: userId,
        senderBank: senderBank,
        messageText: messageText,
        receivedAt: receivedAt,
        amount: amount,
        merchant: merchant,
        vpa: vpa,
        referenceId: referenceId,
        accountLast4: accountLast4,
        isDebit: isDebit,
        category: category,
        paymentMethod: paymentMethod,
        confidence: confidence,
        status: status ?? this.status,
        linkedTxId: linkedTxId ?? this.linkedTxId,
        dedupeHash: dedupeHash,
      );
}
