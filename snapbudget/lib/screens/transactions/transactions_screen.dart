import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_details_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Income', 'Expense', 'UPI'];

  final List<Transaction> _transactions = [
    Transaction(
        id: '1',
        title: 'Swiggy Order',
        description: 'Food',
        amount: 348,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.upi),
    Transaction(
        id: '2',
        title: 'Salary Credit',
        description: 'Monthly',
        amount: 65000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime.now().subtract(const Duration(days: 1)),
        paymentMethod: PaymentMethod.netBanking),
    Transaction(
        id: '3',
        title: 'Uber Ride',
        description: 'Transport',
        amount: 520,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        date: DateTime.now().subtract(const Duration(days: 2)),
        paymentMethod: PaymentMethod.upi),
    Transaction(
        id: '4',
        title: 'Netflix',
        description: 'Entertainment',
        amount: 649,
        type: TransactionType.expense,
        category: TransactionCategory.entertainment,
        date: DateTime.now().subtract(const Duration(days: 3)),
        paymentMethod: PaymentMethod.card),
    Transaction(
        id: '5',
        title: 'Amazon Purchase',
        description: 'Shopping',
        amount: 2499,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: DateTime.now().subtract(const Duration(days: 4)),
        paymentMethod: PaymentMethod.card),
    Transaction(
        id: '6',
        title: 'Freelance Payment',
        description: 'Project',
        amount: 15000,
        type: TransactionType.income,
        category: TransactionCategory.freelance,
        date: DateTime.now().subtract(const Duration(days: 5)),
        paymentMethod: PaymentMethod.upi),
    Transaction(
        id: '7',
        title: 'Electric Bill',
        description: 'BESCOM',
        amount: 1200,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        date: DateTime.now().subtract(const Duration(days: 6)),
        paymentMethod: PaymentMethod.upi),
    Transaction(
        id: '8',
        title: 'BigBasket',
        description: 'Groceries',
        amount: 890,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now().subtract(const Duration(days: 7)),
        paymentMethod: PaymentMethod.upi),
  ];

  List<Transaction> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case 2:
        return _transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
      case 3:
        return _transactions
            .where((t) => t.paymentMethod == PaymentMethod.upi)
            .toList();
      default:
        return _transactions;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
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

            // Filters
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedFilter == i
                          ? AppTheme.primaryPurple
                          : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _selectedFilter == i
                              ? AppTheme.primaryPurple
                              : AppTheme.divider),
                    ),
                    child: Center(
                      child: Text(_filters[i],
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedFilter == i
                                  ? Colors.white
                                  : AppTheme.textMedium)),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtered.length,
                itemBuilder: (context, i) => _txItem(_filtered[i], fmt),
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

  Widget _txItem(Transaction tx, NumberFormat fmt) {
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
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      color: isExp ? AppTheme.errorRed : AppTheme.successGreen)),
              const SizedBox(height: 2),
              Text(DateFormat('MMM d').format(tx.date),
                  style:
                      GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight)),
            ]),
          ],
        ),
      ),
    );
  }
}
