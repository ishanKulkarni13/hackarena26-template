import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';

class AddTransactionSheet extends StatefulWidget {
  final String userId;
  final void Function(Transaction tx) onSave;

  const AddTransactionSheet({
    super.key,
    required this.userId,
    required this.onSave,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _selectedDate;
  late TransactionCategory _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _merchantCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _selectedDate = DateTime.now();
    _selectedCategory = TransactionCategory.other;
    _selectedPaymentMethod = PaymentMethod.upi;
    _selectedType = TransactionType.expense;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      description: _merchantCtrl.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      merchant: _merchantCtrl.text.trim().isNotEmpty
          ? _merchantCtrl.text.trim()
          : null,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      source: TransactionSource.manual,
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
                24,
                20,
                24,
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
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Manual Entry',
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

                    const SizedBox(height: 24),

                    // Type Selector (Expense / Income)
                    _buildTypeToggle(),

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
                        if (double.tryParse(v.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date & Category Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Date'),
                              _buildDatePicker(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Category'),
                              _buildCategoryDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Payment Method
                    _fieldLabel('Payment Method'),
                    _buildPaymentMethodDropdown(),
                    const SizedBox(height: 14),

                    // Merchant (Optional)
                    _fieldLabel('Merchant (Optional)'),
                    _buildTextField(
                      controller: _merchantCtrl,
                      hint: 'e.g. Swiggy, Amazon',
                    ),
                    const SizedBox(height: 14),

                    // Notes (Optional)
                    _fieldLabel('Notes'),
                    _buildTextField(
                      controller: _notesCtrl,
                      hint: 'Anything else...',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Add Button
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

  Widget _buildTypeToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedType = TransactionType.expense),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense
                      ? AppTheme.errorRed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedType == TransactionType.expense
                          ? Colors.white
                          : AppTheme.textMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedType = TransactionType.income),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income
                      ? AppTheme.successGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedType == TransactionType.income
                          ? Colors.white
                          : AppTheme.textMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppTheme.textMedium),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('MMM d, yy').format(_selectedDate),
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TransactionCategory>(
          value: _selectedCategory,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: TransactionCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text('${cat.emoji} ${cat.label}'),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategory = v);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethod>(
          value: _selectedPaymentMethod,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: PaymentMethod.values.map((m) {
            final label = m.name.toUpperCase();
            return DropdownMenuItem(value: m, child: Text(label));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedPaymentMethod = v);
          },
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
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
            borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide:
                const BorderSide(color: AppTheme.primaryPurple, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.errorRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5)),
      ),
    );
  }
}
