class SmsTransactionModel {
  final String smsId;
  final String userId;
  final String senderBank;
  final double amount;
  final String merchant;
  final String? transactionId;
  final String messageText;
  final String category;
  final DateTime detectedAt;

  SmsTransactionModel({
    required this.smsId,
    required this.userId,
    required this.senderBank,
    required this.amount,
    required this.merchant,
    this.transactionId,
    required this.messageText,
    required this.category,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderBank': senderBank,
      'amount': amount,
      'merchant': merchant,
      'transactionId': transactionId,
      'messageText': messageText,
      'category': category,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory SmsTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SmsTransactionModel(
      smsId: docId,
      userId: map['userId'] ?? '',
      senderBank: map['senderBank'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      merchant: map['merchant'] ?? '',
      transactionId: map['transactionId'],
      messageText: map['messageText'] ?? '',
      category: map['category'] ?? 'other',
      detectedAt: map['detectedAt'] != null
          ? DateTime.parse(map['detectedAt'])
          : DateTime.now(),
    );
  }
}
