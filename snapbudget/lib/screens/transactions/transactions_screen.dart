import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_details_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionCategory? _selectedCategory;
  TransactionType? _selectedType;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<TransactionProvider>().loadTransactions(auth.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions',
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  Row(
                    children: [
                      _iconBtn(Icons.search_rounded),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.tune_rounded),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: _summaryCard('Income', '₹80,000',
                          AppTheme.successGreen, Icons.arrow_upward_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _summaryCard('Expenses', '₹6,106',
                          AppTheme.errorRed, Icons.arrow_downward_rounded)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transactions List
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.transactions.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filtering logic
                  var filtered = provider.transactions.where((tx) {
                    final matchesSearch = tx.title
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()) ||
                        tx.description
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                    final matchesCategory = _selectedCategory == null ||
                        tx.category == _selectedCategory;
                    final matchesType =
                        _selectedType == null || tx.type == _selectedType;
                    final matchesDate = _selectedDateRange == null ||
                        (tx.date.isAfter(_selectedDateRange!.start) &&
                            tx.date.isBefore(_selectedDateRange!.end
                                .add(const Duration(days: 1))));

                    return matchesSearch &&
                        matchesCategory &&
                        matchesType &&
                        matchesDate;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 64,
                              color: AppTheme.textLight.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions match your filters',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _buildTransactionItem(tx, currencyFormat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow),
      child: Icon(icon, size: 18, color: AppTheme.textDark),
    );
  }

  Widget _summaryCard(String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
            Text(amount,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx, NumberFormat fmt) {
    final isExp = tx.type == TransactionType.expense;
    return GestureDetector(
      onTap: () => showTransactionDetailsSheet(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: isExp
                      ? AppTheme.errorRed.withOpacity(0.08)
                      : AppTheme.successGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(13)),
              child: Center(
                  child: Text(tx.category.emoji,
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(tx.category.label,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textLight)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${isExp ? '-' : '+'}${fmt.format(tx.amount)}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isExp ? AppTheme.errorRed : AppTheme.successGreen)),
              const SizedBox(height: 2),
              Text(DateFormat('MMM d').format(tx.date),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.textLight)),
            ]),
          ],
        ),
      ),
    );
  }
}
