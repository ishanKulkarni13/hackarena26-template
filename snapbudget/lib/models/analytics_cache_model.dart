class AnalyticsCacheModel {
  final String userId;
  final int month;
  final double totalSpend;
  final Map<String, double> categoryBreakdown;
  final List<String> topMerchants;
  final DateTime updatedAt;

  AnalyticsCacheModel({
    required this.userId,
    required this.month,
    this.totalSpend = 0.0,
    this.categoryBreakdown = const {},
    this.topMerchants = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'month': month,
      'totalSpend': totalSpend,
      'categoryBreakdown': categoryBreakdown,
      'topMerchants': topMerchants,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnalyticsCacheModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnalyticsCacheModel(
      userId: map['userId'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      totalSpend: (map['totalSpend'] ?? 0).toDouble(),
      categoryBreakdown:
          Map<String, double>.from(map['categoryBreakdown'] ?? {}),
      topMerchants: List<String>.from(map['topMerchants'] ?? []),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
