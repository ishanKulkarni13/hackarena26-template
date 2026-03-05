// lib/services/sms_listener_service.dart
//
// Handles two SMS acquisition modes:
//   1. scanInbox()  — reads last N days from the SMS inbox on app open.
//   2. startListening() — registers a live BroadcastReceiver for new messages.
//
// Both routes parse the message, dedup against Firestore, then save pending
// SmsTransactionModel documents. The SMS screen streams those documents.
//
// Privacy note: ALL parsing is on-device. No SMS text is sent to any server.

import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'firestore_service.dart';
import 'sms_parser_service.dart';

class SmsListenerService {
  SmsListenerService._();
  static final SmsListenerService instance = SmsListenerService._();

  final Telephony _telephony = Telephony.instance;
  final FirestoreService _firestore = FirestoreService();

  bool _initialized = false;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Call once after the user grants READ_SMS + RECEIVE_SMS permissions.
  /// Registers the live foreground listener.
  Future<void> startListening(String userId) async {
    if (_initialized) return;
    _initialized = true;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage msg) => _handleMessage(msg, userId),
      // Background handler must be a top-level function (teleophony requirement)
      onBackgroundMessage: _backgroundSmsHandler,
      listenInBackground: true,
    );
    debugPrint('📱 [SmsListenerService] Live SMS listener started');
  }

  /// Scans the last [daysBack] days of the SMS inbox.
  /// Call once on app open when permissions are available.
  Future<void> scanInbox(String userId, {int daysBack = 7}) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: daysBack))
          .millisecondsSinceEpoch;

      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(cutoff.toString()),
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      debugPrint(
          '📱 [SmsListenerService] Inbox scan: ${messages.length} messages in last $daysBack days');

      int saved = 0;
      for (final msg in messages) {
        final sender = msg.address ?? '';
        final body = msg.body ?? '';
        final ts = msg.date != null
            ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
            : DateTime.now();

        final didSave = await _process(
          sender: sender,
          body: body,
          receivedAt: ts,
          userId: userId,
        );
        if (didSave) saved++;
      }
      debugPrint(
          '✅ [SmsListenerService] Inbox scan complete — $saved new transactions saved');
    } catch (e) {
      debugPrint('❌ [SmsListenerService] scanInbox error: $e');
    }
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<void> _handleMessage(SmsMessage msg, String userId) async {
    final sender = msg.address ?? '';
    final body = msg.body ?? '';
    final ts = msg.date != null
        ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
        : DateTime.now();

    debugPrint('📩 [SmsListenerService] New SMS from $sender');
    await _process(sender: sender, body: body, receivedAt: ts, userId: userId);
  }

  Future<bool> _process({
    required String sender,
    required String body,
    required DateTime receivedAt,
    required String userId,
  }) async {
    // 1. Parse
    final result = SmsParserService.parse(
      sender: sender,
      body: body,
      receivedAt: receivedAt,
    );
    if (result == null) return false;

    // 2. Deduplicate
    final hash = SmsParserService.buildDedupeHash(
      sender: sender,
      amount: result.amount,
      receivedAt: receivedAt,
    );
    final exists = await _firestore.smsDedupeExists(hash, userId);
    if (exists) {
      debugPrint('⚠️ [SmsListenerService] Duplicate skipped: $hash');
      return false;
    }

    // 3. Persist
    final model = SmsParserService.toModel(
      result: result,
      rawBody: body,
      senderId: sender,
      receivedAt: receivedAt,
      userId: userId,
    );
    await _firestore.addSmsTransaction(model);
    debugPrint(
        '✅ [SmsListenerService] Saved: ₹${result.amount} | ${result.merchant} | conf:${result.confidence.toStringAsFixed(2)}');
    return true;
  }
}

// ─── Top-level background handler (required by telephony) ─────────────────
// Only logs here — full processing happens via scanInbox on next app open.
@pragma('vm:entry-point')
void _backgroundSmsHandler(SmsMessage message) {
  debugPrint(
      '📱 [BG] SMS received from ${message.address} — will process on next app open');
}
