import 'package:flutter/material.dart';
import 'dart:async';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class BudgetProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  void loadBudgets(String userId, int month, int year) {
    _setLoading(true);
    _subscription?.cancel();

    _subscription = _firestoreService.getBudgets(userId, month, year).listen(
      (data) {
        _budgets = data;
        _setLoading(false);
      },
      onError: (e) {
        print('Error loading budgets: $e');
        _setLoading(false);
      },
    );
  }

  Future<void> setBudget(BudgetModel budget) async {
    try {
      await _firestoreService.setBudget(budget);
    } catch (e) {
      print('Error setting budget: $e');
      rethrow;
    }
  }

  void clear() {
    _subscription?.cancel();
    _budgets = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<BudgetModel> budgetsWithSpend(List<Transaction> transactions) {
    return _budgets.map((budget) {
      final spent = transactions
        .where((tx) =>
          tx.type == TransactionType.expense &&
          tx.category.name.toLowerCase() == budget.category.toLowerCase() &&
          tx.date.month == budget.month &&
          tx.date.year == budget.year
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

      return BudgetModel(
        budgetId: budget.budgetId,
        userId: budget.userId,
        category: budget.category,
        monthlyLimit: budget.monthlyLimit,
        currentSpend: spent,
        month: budget.month,
        year: budget.year,
      );
    }).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
