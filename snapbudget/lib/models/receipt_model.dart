class ReceiptModel {
  final String receiptId;
  final String userId;
  final String imageURL;
  final String? storeName;
  final double totalAmount;
  final List<String> items;
  final DateTime date;
  final double ocrConfidence;
  final DateTime createdAt;

  ReceiptModel({
    required this.receiptId,
    required this.userId,
    required this.imageURL,
    this.storeName,
    required this.totalAmount,
    this.items = const [],
    required this.date,
    required this.ocrConfidence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageURL': imageURL,
      'storeName': storeName,
      'totalAmount': totalAmount,
      'items': items,
      'date': date.toIso8601String(),
      'ocrConfidence': ocrConfidence,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReceiptModel(
      receiptId: docId,
      userId: map['userId'] ?? '',
      imageURL: map['imageURL'] ?? '',
      storeName: map['storeName'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      items: List<String>.from(map['items'] ?? []),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      ocrConfidence: (map['ocrConfidence'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
