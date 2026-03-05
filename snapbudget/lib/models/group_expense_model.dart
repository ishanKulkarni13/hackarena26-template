class GroupExpenseModel {
  final String expenseId;
  final String groupId;
  final String paidBy;
  final double amount;
  final String description;
  final List<String> splitMembers; // User IDs of people involved
  final DateTime createdAt;
  final ExpenseStatus status;

  GroupExpenseModel({
    required this.expenseId,
    required this.groupId,
    required this.paidBy,
    required this.amount,
    required this.description,
    required this.splitMembers,
    DateTime? createdAt,
    this.status = ExpenseStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'paidBy': paidBy,
      'amount': amount,
      'description': description,
      'splitMembers': splitMembers,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory GroupExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return GroupExpenseModel(
      expenseId: docId,
      groupId: map['groupId'] ?? '',
      paidBy: map['paidBy'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      splitMembers: List<String>.from(map['splitMembers'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExpenseStatus.pending,
      ),
    );
  }
}

enum ExpenseStatus { pending, settled }
