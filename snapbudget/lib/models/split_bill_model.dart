class SplitBill {
  final String id;
  final String title;
  final double totalAmount;
  final List<SplitMember> members;
  final DateTime date;
  final String? description;
  final SplitStatus status;
  final Map<String, double>? expenseBreakdown; // e.g., {'Hotel': 5000, 'Food': 4500, 'Activities': 3000}

  SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.members,
    required this.date,
    this.description,
    required this.status,
    this.expenseBreakdown,
  });

  double get amountPerPerson => totalAmount / members.length;

  double get totalPaid =>
      members.fold(0, (sum, m) => sum + (m.hasPaid ? m.share : 0));

  double get totalPending => totalAmount - totalPaid;
}

class SplitMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final double share;
  bool hasPaid;
  final String? upiId;

  SplitMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.share,
    this.hasPaid = false,
    this.upiId,
  });
}

enum SplitStatus { pending, partial, settled }
