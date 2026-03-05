// lib/models/receipt_parse_result.dart
//
// Pure data class — output of GeminiReceiptService.
// Zero dependency on Flutter widgets or state management.
// This is the clean boundary between the AI service layer and the app.

import 'transaction_model.dart';

class ReceiptParseResult {
  /// Name of the merchant / store (e.g. "Swiggy", "Baskin Robbins")
  final String merchantName;

  /// Short human-friendly title for the transaction (e.g. "Dinner", "Uber Ride")
  final String title;

  /// Total amount paid (in rupees)
  final double amount;

  /// Date the transaction occurred (defaults to today if not found on receipt)
  final DateTime date;

  /// Best-matching category from the TransactionCategory enum
  final TransactionCategory category;

  /// Non-null only when category == TransactionCategory.other and Gemini
  /// identified a more specific label (e.g. "Ice Cream", "Pet Care").
  final String? customLabel;

  /// false = Gemini parsing failed or returned invalid JSON.
  /// The UI should show a warning banner and let the user fill in fields manually.
  final bool parsedSuccessfully;

  const ReceiptParseResult({
    required this.merchantName,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.customLabel,
    required this.parsedSuccessfully,
  });

  /// Blank fallback returned when parsing fails — all fields have safe defaults.
  factory ReceiptParseResult.failed() {
    return ReceiptParseResult(
      merchantName: '',
      title: '',
      amount: 0,
      date: DateTime.now(),
      category: TransactionCategory.other,
      parsedSuccessfully: false,
    );
  }
}
