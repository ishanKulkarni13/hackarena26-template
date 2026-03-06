// lib/services/gemini_receipt_service.dart
//
// Sends a receipt image to the Gemini 1.5 Flash API and returns a
// ReceiptParseResult. This class has NO dependency on Provider, Firebase,
// or any Flutter widget — it is pure business logic.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_parse_result.dart';
import '../models/transaction_model.dart';

class GeminiReceiptService {
  static const _model = 'gemini-2.5-flash';

  // Ordered list of category strings that mirrors TransactionCategory enum.
  // This is what we pass to Gemini so it picks from the exact same set.
  static const _categoryNames = [
    'food',
    'transport',
    'shopping',
    'entertainment',
    'health',
    'utilities',
    'housing',
    'education',
    'travel',
    'salary',
    'freelance',
    'investment',
    'other',
  ];

  // Maps the string returned by Gemini back to a TransactionCategory enum value.
  static TransactionCategory _parseCategory(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'food':
        return TransactionCategory.food;
      case 'transport':
        return TransactionCategory.transport;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'entertainment':
        return TransactionCategory.entertainment;
      case 'health':
        return TransactionCategory.health;
      case 'utilities':
        return TransactionCategory.utilities;
      case 'housing':
        return TransactionCategory.housing;
      case 'education':
        return TransactionCategory.education;
      case 'travel':
        return TransactionCategory.travel;
      case 'salary':
        return TransactionCategory.salary;
      case 'freelance':
        return TransactionCategory.freelance;
      case 'investment':
        return TransactionCategory.investment;
      default:
        return TransactionCategory.other;
    }
  }

  /// Sends [imageFile] to Gemini and returns a [ReceiptParseResult].
  ///
  /// On any error returns [ReceiptParseResult.failed()] so the UI shows
  /// a blank editable form. Check the debug console (flutter run output)
  /// for step-by-step logs prefixed with [GeminiReceiptService].
  Future<ReceiptParseResult> analyseReceipt(XFile imageFile) async {
    debugPrint('🧾 [GeminiReceiptService] analyseReceipt() called');
    debugPrint('   Image path: ${imageFile.path}');

    try {
      // ── Step 1: API key ──────────────────────────────────────────────────
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('❌ [GeminiReceiptService] GEMINI_API_KEY is missing from .env');
        return ReceiptParseResult.failed();
      }
      debugPrint('✅ [GeminiReceiptService] API key loaded (${apiKey.substring(0, 8)}...)');

      // ── Step 2: Read image bytes ─────────────────────────────────────────
      final imageFileObj = File(imageFile.path);
      if (!imageFileObj.existsSync()) {
        debugPrint('❌ [GeminiReceiptService] Image file not found: ${imageFile.path}');
        return ReceiptParseResult.failed();
      }
      final imageBytes = await imageFileObj.readAsBytes();
      final mimeType = imageFile.mimeType ?? 'image/jpeg';
      debugPrint('✅ [GeminiReceiptService] Image: ${imageBytes.length} bytes, mime: $mimeType');

      // ── Step 3: Send to Gemini ───────────────────────────────────────────
      final model = GenerativeModel(model: _model, apiKey: apiKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final prompt = '''
You are a receipt parser. Look at this receipt image and extract the following fields.
Return ONLY valid JSON — no markdown, no code fences, no explanation.

Fields:
- merchant_name: string — the store, restaurant, or service name
- total_amount: number — the final total paid (in Indian Rupees, number only, no symbol)
- date: string — format YYYY-MM-DD; use today ($today) if not found
- title: string — short human-friendly label like "Lunch", "Uber Ride", "Groceries", "Ice Cream"
- category: string — MUST be exactly one of: ${_categoryNames.join(', ')}
  If none match well, use "other" and set custom_category.
- custom_category: string or null — short label if category is "other" (e.g. "Ice Cream", "Pet Care")

Respond with JSON only:
{
  "merchant_name": "",
  "total_amount": 0,
  "date": "",
  "title": "",
  "category": "",
  "custom_category": null
}
''';

      debugPrint('📡 [GeminiReceiptService] Sending request to Gemini API...');
      final response = await model.generateContent([
        Content.multi([
          DataPart(mimeType, imageBytes),
          TextPart(prompt),
        ]),
      ]);

      // ── Step 4: Parse response ───────────────────────────────────────────
      final rawText = response.text ?? '';
      debugPrint('📥 [GeminiReceiptService] Raw Gemini response:\n$rawText');

      if (rawText.isEmpty) {
        debugPrint('❌ [GeminiReceiptService] Empty response text from Gemini');
        return ReceiptParseResult.failed();
      }

      // Strip any markdown fences Gemini might add despite instructions
      final jsonStr = _extractJson(rawText);
      debugPrint('🔍 [GeminiReceiptService] Extracted JSON:\n$jsonStr');

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      debugPrint('✅ [GeminiReceiptService] JSON decoded successfully: $data');

      final categoryStr = (data['category'] as String? ?? 'other');
      final category = _parseCategory(categoryStr);
      debugPrint('   Category: "$categoryStr" → ${category.name}');

      // Only keep custom_category when category resolves to 'other'
      String? customLabel;
      if (category == TransactionCategory.other) {
        customLabel = data['custom_category'] as String?;
        if (customLabel != null) {
          debugPrint('   Custom label: $customLabel');
        }
      }

      final amountRaw = data['total_amount'];
      final double amount = amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw.toString()) ?? 0.0;
      debugPrint('   Amount: ₹$amount');

      DateTime date;
      try {
        date = DateTime.parse(data['date'] as String? ?? '');
      } catch (_) {
        debugPrint('   Date parse failed — using today');
        date = DateTime.now();
      }

      debugPrint(
        '✅ [GeminiReceiptService] Parse complete: "${data['title']}" | ₹$amount | ${category.name}',
      );

      return ReceiptParseResult(
        merchantName: (data['merchant_name'] as String? ?? '').trim(),
        title: (data['title'] as String? ?? '').trim(),
        amount: amount,
        date: date,
        category: category,
        customLabel: customLabel,
        parsedSuccessfully: true,
      );
    } catch (e, stack) {
      // Print the ACTUAL exception so we know exactly what went wrong
      debugPrint('❌ [GeminiReceiptService] EXCEPTION caught: $e');
      debugPrint('   Stack trace:\n$stack');
      return ReceiptParseResult.failed();
    }
  }

  /// Sends a spoken-text description to Gemini and returns a [ReceiptParseResult].
  /// Used by the Voice mode in ScanScreen.
  Future<ReceiptParseResult> parseVoiceText(String spokenText) async {
    debugPrint('🎤 [GeminiReceiptService] parseVoiceText() called');
    debugPrint('   Text: $spokenText');

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('❌ [GeminiReceiptService] GEMINI_API_KEY is missing from .env');
        return ReceiptParseResult.failed();
      }

      final model = GenerativeModel(model: _model, apiKey: apiKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final prompt = '''
The user said: "$spokenText"

Extract expense details and return ONLY valid JSON — no markdown, no code fences, no explanation.

Fields:
- merchant_name: string — store/service name if mentioned, else ""
- total_amount: number — amount in Indian Rupees (number only). Use 0 if unclear.
- date: string — format YYYY-MM-DD; use today ($today) if not mentioned
- title: string — short label like "Lunch", "Uber Ride", "Groceries"
- category: string — MUST be exactly one of: ${_categoryNames.join(', ')}
- custom_category: string or null — if category is "other"

Respond with JSON only:
{
  "merchant_name": "",
  "total_amount": 0,
  "date": "",
  "title": "",
  "category": "",
  "custom_category": null
}
''';

      debugPrint('📡 [GeminiReceiptService] Sending voice text to Gemini...');
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      final rawText = response.text ?? '';
      debugPrint('📥 [GeminiReceiptService] Voice parse response:\n$rawText');

      if (rawText.isEmpty) return ReceiptParseResult.failed();

      final jsonStr = _extractJson(rawText);
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      final categoryStr = (data['category'] as String? ?? 'other');
      final category = _parseCategory(categoryStr);

      String? customLabel;
      if (category == TransactionCategory.other) {
        customLabel = data['custom_category'] as String?;
      }

      final amountRaw = data['total_amount'];
      final double amount = amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw.toString()) ?? 0.0;

      DateTime date;
      try {
        date = DateTime.parse(data['date'] as String? ?? '');
      } catch (_) {
        date = DateTime.now();
      }

      debugPrint(
        '✅ [GeminiReceiptService] Voice parse complete: "${data['title']}" | ₹$amount | ${category.name}',
      );

      return ReceiptParseResult(
        merchantName: (data['merchant_name'] as String? ?? '').trim(),
        title: (data['title'] as String? ?? '').trim(),
        amount: amount,
        date: date,
        category: category,
        customLabel: customLabel,
        parsedSuccessfully: true,
      );
    } catch (e, stack) {
      debugPrint('❌ [GeminiReceiptService] Voice parse EXCEPTION: $e');
      debugPrint('   Stack trace:\n$stack');
      return ReceiptParseResult.failed();
    }
  }

  /// Strips markdown code fences from Gemini output.
  /// Finds the first '{' and last '}' to isolate valid JSON.
  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return raw;
    return raw.substring(start, end + 1);
  }

  /// Generates a short, actionable financial insight based on recent transactions.
  /// Returns a plain-text string (1–2 sentences, no markdown).
  Future<String> generateInsight({
    required List<Transaction> transactions,
    required double totalExpense,
    required double totalIncome,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) return 'Add your GEMINI_API_KEY to get AI insights.';

      if (transactions.isEmpty) {
        return 'Start adding transactions to get personalised AI insights!';
      }

      // Build a compact spend-by-category summary
      final Map<String, double> byCategory = {};
      for (final tx in transactions) {
        if (tx.type == TransactionType.expense) {
          byCategory[tx.category.name] =
              (byCategory[tx.category.name] ?? 0) + tx.amount;
        }
      }
      final topCategories = (byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => '${e.key} ₹${e.value.toStringAsFixed(0)}')
          .join(', ');

      // Recent 5 transaction titles
      final recent = transactions
          .take(5)
          .map((tx) =>
              '${tx.title} (₹${tx.amount.toStringAsFixed(0)}, ${tx.type.name})')
          .join('; ');

      final prompt = '''
You are a personal finance advisor for an Indian user. Based on the spending data below, give exactly ONE short, specific, actionable insight in plain English. Max 20 words. No markdown, no bullet points, no asterisks. Be direct and practical.

Total income: ₹${totalIncome.toStringAsFixed(0)}
Total expenses: ₹${totalExpense.toStringAsFixed(0)}
Top spending categories: $topCategories
Recent transactions: $recent

Reply with ONLY the insight text, nothing else.''';

      final model = GenerativeModel(model: _model, apiKey: apiKey);
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 12));

      final text = (response.text ?? '').trim();
      if (text.isEmpty) return 'Keep tracking your expenses for better insights!';
      // Strip any accidental asterisks or markdown
      return text.replaceAll(RegExp(r'[*_`#]'), '').trim();
    } catch (e, st) {
      debugPrint('❌ [GeminiReceiptService] generateInsight error: $e\n$st');
      return 'Could not load insight right now. Tap refresh to try again.';
    }
  }
}
