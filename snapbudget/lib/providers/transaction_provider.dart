import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class TransactionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Computed totals
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpense;

  void loadTransactions(String userId) {
    _setLoading(true);
    _subscription?.cancel();

    _subscription = _firestoreService.getTransactions(userId).listen(
      (txs) {
        _transactions = txs;
        _setLoading(false);
      },
      onError: (e) {
        debugPrint('Error loading transactions: $e');
        _setLoading(false);
      },
    );
  }

  Future<void> refreshTransactions(String userId) async {
    loadTransactions(userId);
    // Wait for the first data emission or timeout after 5 seconds
    try {
      await _firestoreService
          .getTransactions(userId)
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore timeout or other errors for the refresh spinner
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    try {
      await _firestoreService.addTransaction(tx);
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  void clear() {
    _subscription?.cancel();
    _transactions = [];
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
