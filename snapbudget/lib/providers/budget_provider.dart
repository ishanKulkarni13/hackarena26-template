import 'package:flutter/material.dart';
import 'dart:async';
import '../models/budget_model.dart';
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
