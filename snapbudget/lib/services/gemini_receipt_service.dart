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

  /// Sends a [transcribedText] string from speech recognition to Gemini
  /// and returns a [ReceiptParseResult], identical contract to [analyseReceipt].
  ///
  /// The caller does NOT need to care how the text was captured — the
  /// VoiceView captures it via speech_to_text, then just calls this.
  Future<ReceiptParseResult> analyseVoiceText(String transcribedText) async {
    debugPrint('🎤 [GeminiReceiptService] analyseVoiceText() called');
    debugPrint('   Transcribed: "$transcribedText"');

    if (transcribedText.trim().isEmpty) {
      debugPrint('❌ [GeminiReceiptService] Empty transcription — returning failed');
      return ReceiptParseResult.failed();
    }

    try {
      // ── Step 1: API key ─────────────────────────────────────────────────
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('❌ [GeminiReceiptService] GEMINI_API_KEY is missing from .env');
        return ReceiptParseResult.failed();
      }
      debugPrint('✅ [GeminiReceiptService] API key loaded (${apiKey.substring(0, 8)}...)');

      // ── Step 2: Build prompt ────────────────────────────────────────────
      final model = GenerativeModel(model: _model, apiKey: apiKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final prompt = '''
You are a personal finance assistant. The user has spoken a voice note describing a transaction.
Extract the transaction details from the text below and return ONLY valid JSON — no markdown, no code fences, no explanation.

Voice note: "$transcribedText"

Fields to extract:
- merchant_name: string — the store, restaurant, or service name (empty string if not mentioned)
- total_amount: number — the amount spent (0 if not mentioned)
- date: string — format YYYY-MM-DD; use today ($today) if not mentioned
- title: string — short human-friendly label like "Lunch", "Uber Ride", "Groceries"
- category: string — MUST be exactly one of: ${_categoryNames.join(', ')}
  If none match well, use "other" and set custom_category.
- custom_category: string or null — short label if category is "other"

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
      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      // ── Step 3: Parse response ──────────────────────────────────────────
      final rawText = response.text ?? '';
      debugPrint('📥 [GeminiReceiptService] Raw voice response:\n$rawText');

      if (rawText.isEmpty) {
        debugPrint('❌ [GeminiReceiptService] Empty response from Gemini');
        return ReceiptParseResult.failed();
      }

      final jsonStr = _extractJson(rawText);
      debugPrint('🔍 [GeminiReceiptService] Extracted JSON:\n$jsonStr');

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      debugPrint('✅ [GeminiReceiptService] JSON decoded: $data');

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
      debugPrint('❌ [GeminiReceiptService] EXCEPTION in analyseVoiceText: $e');
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
}
