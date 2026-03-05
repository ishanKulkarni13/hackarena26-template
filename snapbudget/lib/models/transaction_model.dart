import 'receipt_parse_result.dart';

class Transaction {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? merchant;
  final PaymentMethod paymentMethod;
  final String? notes;
  final bool isRecurring;
  final TransactionSource source;
  final String? receiptImageURL;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.merchant,
    required this.paymentMethod,
    this.notes,
    this.isRecurring = false,
    this.source = TransactionSource.manual,
    this.receiptImageURL,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'date': date.toIso8601String(),
      'merchant': merchant,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'isRecurring': isRecurring,
      'source': source.name,
      'receiptImageURL': receiptImageURL,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String docId) {
    return Transaction(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      merchant: map['merchant'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      notes: map['notes'],
      isRecurring: map['isRecurring'] ?? false,
      source: TransactionSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => TransactionSource.manual,
      ),
      receiptImageURL: map['receiptImageURL'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Creates a copy of this Transaction with selective field overrides.
  /// Used by ReceiptConfirmSheet to apply user edits before saving.
  Transaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? merchant,
    PaymentMethod? paymentMethod,
    String? notes,
    bool? isRecurring,
    TransactionSource? source,
    String? receiptImageURL,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      source: source ?? this.source,
      receiptImageURL: receiptImageURL ?? this.receiptImageURL,
    );
  }

  /// Maps a [ReceiptParseResult] from the Gemini service into a Transaction.
  /// The [userId] comes from AuthProvider (Firebase UID).
  /// The Gemini custom label is stored in [notes] when category == other.
  factory Transaction.fromReceiptResult(
    ReceiptParseResult result, {
    required String userId,
  }) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: result.title.isNotEmpty ? result.title : 'Receipt',
      description: result.merchantName,
      amount: result.amount,
      type: TransactionType.expense,
      category: result.category,
      date: result.date,
      merchant: result.merchantName,
      paymentMethod: PaymentMethod.cash, // User can change in confirm sheet
      notes: result.customLabel, // Custom AI category label stored in notes
      source: TransactionSource.receipt,
    );
  }
}

enum TransactionType { expense, income, transfer }

enum TransactionSource { receipt, sms, voice, manual }

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  utilities,
  housing,
  education,
  travel,
  salary,
  freelance,
  investment,
  other,
}

enum PaymentMethod { upi, card, cash, netBanking, wallet }

extension TransactionCategoryExt on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.housing:
        return 'Housing';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case TransactionCategory.food:
        return '🍔';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.entertainment:
        return '🎮';
      case TransactionCategory.health:
        return '💊';
      case TransactionCategory.utilities:
        return '⚡';
      case TransactionCategory.housing:
        return '🏠';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.travel:
        return '✈️';
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.other:
        return '📦';
    }
  }
}
