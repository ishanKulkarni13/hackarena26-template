class WidgetDataModel {
  final String userId;
  final double monthlySpend;
  final double remainingBudget;
  final DateTime lastUpdated;

  WidgetDataModel({
    required this.userId,
    this.monthlySpend = 0.0,
    this.remainingBudget = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'monthlySpend': monthlySpend,
      'remainingBudget': remainingBudget,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory WidgetDataModel.fromMap(Map<String, dynamic> map, String docId) {
    return WidgetDataModel(
      userId: map['userId'] ?? '',
      monthlySpend: (map['monthlySpend'] ?? 0).toDouble(),
      remainingBudget: (map['remainingBudget'] ?? 0).toDouble(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }
}
