// lib/screens/scan/receipt_confirm_sheet.dart
//
// Editable bottom sheet that shows AI-parsed receipt data for user review.
//
// ARCHITECTURE NOTE — "onSave" callback pattern:
// This widget does NOT call any Provider or Firebase method directly.
// The caller (scan_screen.dart) provides an [onSave] callback.
// Currently scan_screen.dart logs the transaction; once the Firebase friend
// wires up the provider, they simply change the callback to
// `provider.addTransaction(tx)` — zero changes needed in this file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/receipt_parse_result.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';

class ReceiptConfirmSheet extends StatefulWidget {
  final ReceiptParseResult result;

  /// Called when the user taps "Add Transaction".
  /// The caller decides what to do with the transaction (log, provider, Firebase).
  final void Function(Transaction tx) onSave;

  const ReceiptConfirmSheet({
    super.key,
    required this.result,
    required this.onSave,
  });

  @override
  State<ReceiptConfirmSheet> createState() => _ReceiptConfirmSheetState();
}

class _ReceiptConfirmSheetState extends State<ReceiptConfirmSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late DateTime _selectedDate;
  late TransactionCategory _selectedCategory;
  late TextEditingController _customLabelCtrl;
  late PaymentMethod _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _titleCtrl = TextEditingController(text: r.title);
    _merchantCtrl = TextEditingController(text: r.merchantName);
    _amountCtrl = TextEditingController(
      text: r.amount > 0 ? r.amount.toStringAsFixed(0) : '',
    );
    _selectedDate = r.date;
    _selectedCategory = r.category;
    _customLabelCtrl = TextEditingController(text: r.customLabel ?? '');
    _selectedPaymentMethod = PaymentMethod.cash;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primaryPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final customLabel = _selectedCategory == TransactionCategory.other &&
            _customLabelCtrl.text.trim().isNotEmpty
        ? _customLabelCtrl.text.trim()
        : null;

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _merchantCtrl.text.trim(),
      amount: amount,
      type: TransactionType.expense,
      category: _selectedCategory,
      date: _selectedDate,
      merchant: _merchantCtrl.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      customLabel: customLabel,
    );

    Navigator.of(context).pop();
    widget.onSave(tx);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Receipt Detected',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close_rounded,
                              color: AppTheme.textLight),
                        ),
                      ],
                    ),

                    // Parse failure warning banner
                    if (!widget.result.parsedSuccessfully) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.warningOrange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.warningOrange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Couldn't read the receipt clearly. Please fill in the details below.",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Title
                    _fieldLabel('Title'),
                    _buildTextField(
                      controller: _titleCtrl,
                      hint: 'e.g. Lunch, Uber Ride',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Merchant
                    _fieldLabel('Merchant'),
                    _buildTextField(
                      controller: _merchantCtrl,
                      hint: 'e.g. Swiggy, BigBazaar',
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    _fieldLabel('Amount (₹)'),
                    _buildTextField(
                      controller: _amountCtrl,
                      hint: '0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date
                    _fieldLabel('Date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppTheme.textMedium),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category
                    _fieldLabel('Category'),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 14),

                    // Custom label field (visible only when "other" is selected)
                    if (_selectedCategory == TransactionCategory.other) ...[
                      _fieldLabel('Custom Category Label'),
                      _buildTextField(
                        controller: _customLabelCtrl,
                        hint: 'e.g. Ice Cream, Pet Care',
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Payment Method
                    _fieldLabel('Payment Method'),
                    _buildPaymentMethodDropdown(),
                    const SizedBox(height: 24),

                    // Add Transaction button
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXL),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: Center(
                          child: Text(
                            'Add Transaction',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMedium,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide:
              const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide:
              const BorderSide(color: AppTheme.errorRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<TransactionCategory>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide:
              const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textMedium),
      items: TransactionCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text('${cat.emoji}  ${cat.label}'),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedCategory = v);
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    const methods = {
      PaymentMethod.upi: '📲  UPI',
      PaymentMethod.card: '💳  Card',
      PaymentMethod.cash: '💵  Cash',
      PaymentMethod.netBanking: '🏦  Net Banking',
      PaymentMethod.wallet: '👛  Wallet',
    };

    return DropdownButtonFormField<PaymentMethod>(
      value: _selectedPaymentMethod,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide:
              const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textMedium),
      items: methods.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedPaymentMethod = v);
      },
    );
  }
}
