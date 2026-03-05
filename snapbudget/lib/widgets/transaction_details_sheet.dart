import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

Future<void> showTransactionDetailsSheet(
  BuildContext context,
  Transaction transaction,
) {
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final isExpense = transaction.type == TransactionType.expense;
  final amountText =
      '${isExpense ? '-' : '+'}${currencyFormat.format(transaction.amount)}';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom + 20;

      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isExpense
                          ? AppTheme.errorRed.withOpacity(0.08)
                          : AppTheme.successGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        transaction.category.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  amountText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isExpense ? AppTheme.errorRed : AppTheme.successGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Type', _typeLabel(transaction.type)),
              _detailRow('Category', transaction.category.label),
              _detailRow(
                'Date',
                DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
              ),
              _detailRow('Payment', _paymentLabel(transaction.paymentMethod)),
              _detailRow('Merchant', _safeText(transaction.merchant)),
              _detailRow(
                'Recurring',
                transaction.isRecurring ? 'Yes' : 'No',
              ),
              _detailRow('Transaction ID', transaction.id),
              _detailRow('Notes', _safeText(transaction.notes)),
            ],
          ),
        ),
      );
    },
  );
}

String _typeLabel(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return 'Expense';
    case TransactionType.income:
      return 'Income';
    case TransactionType.transfer:
      return 'Transfer';
  }
}

String _paymentLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.upi:
      return 'UPI';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.netBanking:
      return 'Net Banking';
    case PaymentMethod.wallet:
      return 'Wallet';
  }
}

String _safeText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Not available';
  }
  return value;
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

