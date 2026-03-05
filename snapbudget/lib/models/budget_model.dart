class BudgetModel {
  final String budgetId;
  final String userId;
  final String category;
  final double monthlyLimit;
  final double currentSpend;
  final int month;
  final int year;

  BudgetModel({
    required this.budgetId,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    this.currentSpend = 0.0,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'currentSpend': currentSpend,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String docId) {
    return BudgetModel(
      budgetId: docId,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'other',
      monthlyLimit: (map['monthlyLimit'] ?? 0).toDouble(),
      currentSpend: (map['currentSpend'] ?? 0).toDouble(),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
    );
  }
}
