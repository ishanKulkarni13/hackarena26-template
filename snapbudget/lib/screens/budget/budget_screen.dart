import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _fmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        final now = DateTime.now();
        context
            .read<BudgetProvider>()
            .loadBudgets(auth.user!.uid, now.month, now.year);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final budgets = budgetProvider.budgets;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Monthly Budgets',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    return _buildBudgetCard(budgets[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined,
              size: 80, color: AppTheme.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Budgets Set',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMedium)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                'Set a monthly limit by category to track your spending effectively.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddBudgetDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Create First Budget',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    final percent = budget.monthlyLimit > 0
        ? (budget.currentSpend / budget.monthlyLimit)
        : 0.0;
    final isOver = percent > 1.0;
    final color = isOver
        ? AppTheme.errorRed
        : (percent > 0.8 ? AppTheme.warningOrange : AppTheme.successGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(budget.category.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textLight,
                      letterSpacing: 1)),
              GestureDetector(
                onTap: () => _showEditBudgetDialog(budget),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fmt.format(budget.currentSpend),
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  Text('of ${_fmt.format(budget.monthlyLimit)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textMedium)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${(percent * 100).toInt()}%',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: AppTheme.background,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetBottomSheet(
        onSave: (budget) {
          context.read<BudgetProvider>().setBudget(budget);
        },
      ),
    );
  }

  void _showEditBudgetDialog(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetBottomSheet(
        initialBudget: budget,
        onSave: (updatedBudget) {
          context.read<BudgetProvider>().setBudget(updatedBudget);
        },
      ),
    );
  }
}

class _BudgetBottomSheet extends StatefulWidget {
  final BudgetModel? initialBudget;
  final Function(BudgetModel) onSave;

  const _BudgetBottomSheet({this.initialBudget, required this.onSave});

  @override
  State<_BudgetBottomSheet> createState() => _BudgetBottomSheetState();
}

class _BudgetBottomSheetState extends State<_BudgetBottomSheet> {
  late final TextEditingController _amountController;
  String _selectedCategory = 'food';
  final List<String> _categories = [
    'food',
    'shopping',
    'transport',
    'entertainment',
    'utilities',
    'health',
    'education',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialBudget?.monthlyLimit.toStringAsFixed(0) ?? '',
    );
    if (widget.initialBudget != null) {
      _selectedCategory = widget.initialBudget!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.initialBudget == null
                    ? 'Set Monthly Budget'
                    : 'Edit Budget',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 20),
            Text('Select Category',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPurple
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryPurple
                                : AppTheme.divider),
                      ),
                      child: Center(
                        child: Text(cat.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMedium)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Monthly Limit',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: AppTheme.primaryPurple),
                  hintText: 'Enter amount',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount > 0) {
                    final auth = context.read<AuthProvider>();
                    final now = DateTime.now();
                    final budget = BudgetModel(
                      budgetId: widget.initialBudget?.budgetId ?? '',
                      userId: auth.user!.uid,
                      category: _selectedCategory,
                      monthlyLimit: amount,
                      currentSpend: widget.initialBudget?.currentSpend ?? 0.0,
                      month: now.month,
                      year: now.year,
                    );
                    widget.onSave(budget);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Save Budget',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
