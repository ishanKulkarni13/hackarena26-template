import 'receipt_parse_result.dart';

class Transaction {
  final String id;
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
  // Holds a free-text category label when Gemini returns a category not in
  // the enum (e.g. "Ice Cream", "Pet Care"). Display this instead of
  // category.label whenever it is non-null.
  final String? customLabel;

  Transaction({
    required this.id,
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
    this.customLabel,
  });

  /// Creates a copy of this Transaction with selective field overrides.
  Transaction copyWith({
    String? id,
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
    String? customLabel,
  }) {
    return Transaction(
      id: id ?? this.id,
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
      customLabel: customLabel ?? this.customLabel,
    );
  }

  /// Maps a [ReceiptParseResult] from the Gemini service into a Transaction.
  /// This is the primary integration point between the AI layer and the model.
  /// TODO: When Firebase is integrated, this is where you'd also set a Firestore
  /// document ID or sync status.
  factory Transaction.fromReceiptResult(ReceiptParseResult result) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result.title,
      description: result.merchantName,
      amount: result.amount,
      type: TransactionType.expense,
      category: result.category,
      date: result.date,
      merchant: result.merchantName,
      paymentMethod: PaymentMethod.cash, // Default; user can change in confirm sheet
      customLabel: result.customLabel,
    );
  }
}

enum TransactionType { expense, income, transfer }

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
