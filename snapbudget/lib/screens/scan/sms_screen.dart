// lib/screens/scan/sms_screen.dart
//
// Displays SMS-detected transactions in three buckets:
//   Pending → user reviews → Add Transaction OR Dismiss
//   Accepted → linked to a Transaction doc
//   Ignored  → user dismissed
//
// "Add Transaction" opens ReceiptConfirmSheet (reuses the same review UX as
// receipt scan) then marks the SMS as accepted.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/receipt_parse_result.dart';
import '../../models/sms_transaction_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_listener_service.dart';
import '../../theme/app_theme.dart';
import 'receipt_confirm_sheet.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final FirestoreService _firestore = FirestoreService();

  bool _hasPermission = false;
  bool _checkingPermission = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Permission flow ──────────────────────────────────────────────────────

  Future<void> _checkPermissions() async {
    final read = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _hasPermission = read.isGranted;
        _checkingPermission = false;
      });
    }
    if (_hasPermission) _startServicesIfNeeded();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.sms.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _startServicesIfNeeded();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _startServicesIfNeeded() async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    if (userId.isEmpty) return;
    await SmsListenerService.instance.startListening(userId);
  }

  Future<void> _scanInbox() async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    if (userId.isEmpty) return;
    setState(() => _isScanning = true);
    await SmsListenerService.instance.scanInbox(userId, daysBack: 7);
    if (mounted) setState(() => _isScanning = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) return _buildPermissionGate();

    final userId = context.watch<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(userId),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildList(userId, SmsStatus.pending),
                _buildList(userId, SmsStatus.accepted),
                _buildList(userId, SmsStatus.ignored),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String userId) {
    return AppBar(
      backgroundColor: AppTheme.cardWhite,
      elevation: 0,
      title: Text(
        'SMS Detection',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
      actions: [
        if (_isScanning)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primaryPurple),
            ),
          )
        else
          IconButton(
            onPressed: _scanInbox,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryPurple),
            tooltip: 'Scan last 7 days',
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.cardWhite,
      child: TabBar(
        controller: _tabs,
        labelColor: AppTheme.primaryPurple,
        unselectedLabelColor: AppTheme.textLight,
        indicatorColor: AppTheme.primaryPurple,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Accepted'),
          Tab(text: 'Ignored'),
        ],
      ),
    );
  }

  Widget _buildList(String userId, SmsStatus forStatus) {
    if (userId.isEmpty) {
      return _empty('Sign in to view SMS transactions');
    }

    return StreamBuilder<List<SmsTransactionModel>>(
      stream: _firestore.getSmsTransactions(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _empty('Error loading messages');
        }

        final all = snap.data ?? [];
        final items = all.where((s) => s.status == forStatus).toList();

        if (items.isEmpty) return _emptyForStatus(forStatus);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildCard(items[i], userId),
        );
      },
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────

  Widget _buildCard(SmsTransactionModel sms, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: sms.status == SmsStatus.pending
            ? Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Bank icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sms_rounded,
                      color: AppTheme.primaryPurple, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sms.merchant.isNotEmpty ? sms.merchant : sms.senderBank,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sms.senderBank,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${sms.isDebit ? '-' : '+'}₹${sms.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: sms.isDebit ? AppTheme.errorRed : AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),

          // ── Meta row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(
                  DateFormat('d MMM, h:mm a').format(sms.receivedAt),
                  Icons.access_time_rounded,
                  AppTheme.textLight,
                ),
                _chip(
                  sms.category,
                  Icons.label_outline_rounded,
                  AppTheme.primaryPurple,
                ),
                _confidenceChip(sms.confidence),
                if (sms.vpa != null)
                  _chip(sms.vpa!, Icons.account_balance_wallet_rounded,
                      AppTheme.accentBlue),
              ],
            ),
          ),

          // ── Raw SMS body (collapsed) ──────────────────────────────────
          _ExpandableRawSms(body: sms.messageText),

          // ── Action buttons (pending only) ─────────────────────────────
          if (sms.status == SmsStatus.pending) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  // Dismiss
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _dismiss(sms),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMedium,
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text('Ignore',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add Transaction
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _addTransaction(sms, userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text('Add Transaction',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Accepted state ────────────────────────────────────────────
          if (sms.status == SmsStatus.accepted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.successGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Added to transactions',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.successGreen),
                  ),
                ],
              ),
            ),

          // ── Ignored state ─────────────────────────────────────────────
          if (sms.status == SmsStatus.ignored)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded,
                      color: AppTheme.textLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ignored',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
                  const Spacer(),
                  // Allow restoring
                  GestureDetector(
                    onTap: () => _restore(sms),
                    child: Text(
                      'Restore',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _dismiss(SmsTransactionModel sms) async {
    await _firestore.updateSmsStatus(sms.smsId, status: SmsStatus.ignored);
  }

  Future<void> _restore(SmsTransactionModel sms) async {
    await _firestore.updateSmsStatus(sms.smsId, status: SmsStatus.pending);
  }

  Future<void> _addTransaction(SmsTransactionModel sms, String userId) async {
    // Map SMS data to a ReceiptParseResult so we can reuse ReceiptConfirmSheet
    final parseResult = ReceiptParseResult(
      merchantName: sms.merchant,
      title: _titleFromSms(sms),
      amount: sms.amount,
      date: sms.receivedAt,
      category: TransactionCategory.values.firstWhere(
        (c) => c.name == sms.category,
        orElse: () => TransactionCategory.other,
      ),
      parsedSuccessfully: true,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ReceiptConfirmSheet(
        result: parseResult,
        userId: userId,
        onSave: (Transaction tx) async {
          // Override source to sms
          final smsTx = tx.copyWith(source: TransactionSource.sms);
          await context.read<TransactionProvider>().addTransaction(smsTx);

          // Mark the SMS as accepted + link the transaction id
          await _firestore.updateSmsStatus(
            sms.smsId,
            status: SmsStatus.accepted,
            linkedTxId: smsTx.id,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${smsTx.title} — ₹${smsTx.amount.toStringAsFixed(0)} added!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  String _titleFromSms(SmsTransactionModel sms) {
    if (sms.merchant.isNotEmpty) return sms.merchant;
    return sms.isDebit ? 'Expense' : 'Income';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _confidenceChip(double confidence) {
    final String label;
    final Color color;
    if (confidence >= 0.7) {
      label = 'High confidence';
      color = AppTheme.successGreen;
    } else if (confidence >= 0.5) {
      label = 'Medium confidence';
      color = AppTheme.warningOrange;
    } else {
      label = 'Low confidence';
      color = AppTheme.errorRed;
    }
    return _chip(label, Icons.verified_outlined, color);
  }

  Widget _empty(String msg) => Center(
        child: Text(msg,
            style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14)),
      );

  Widget _emptyForStatus(SmsStatus status) {
    final msgs = {
      SmsStatus.pending: 'No pending SMS transactions.\nTap ↻ to scan inbox.',
      SmsStatus.accepted: 'No accepted transactions yet.',
      SmsStatus.ignored: 'No ignored messages.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == SmsStatus.pending
                  ? Icons.sms_outlined
                  : status == SmsStatus.accepted
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              msgs[status]!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textLight, height: 1.6),
            ),
            if (status == SmsStatus.pending) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanInbox,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Scan Inbox',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Permission gate ──────────────────────────────────────────────────────

  Widget _buildPermissionGate() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'SMS Detection',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Allow SnapBudget to read your bank SMS messages to automatically detect transactions.\n\nYour data never leaves your device.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppTheme.textMedium, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Grant SMS Permission',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Not now',
                  style: GoogleFonts.inter(
                      color: AppTheme.textLight, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expandable raw SMS body ──────────────────────────────────────────────
class _ExpandableRawSms extends StatefulWidget {
  final String body;
  const _ExpandableRawSms({required this.body});

  @override
  State<_ExpandableRawSms> createState() => _ExpandableRawSmsState();
}

class _ExpandableRawSmsState extends State<_ExpandableRawSms> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.body,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textMedium, height: 1.5),
            ),
            const SizedBox(height: 2),
            Text(
              _expanded ? 'Show less ▲' : 'Show more ▼',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
