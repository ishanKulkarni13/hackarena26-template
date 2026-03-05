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

  /// Transactions sorted by when they were *added to the app* (createdAt desc).
  /// Used for the home-screen "Recent Transactions" list so that newly scanned
  /// receipts (which may carry an old purchase date) always appear at the top.
  List<Transaction> get recentlyAddedTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

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
    // Optimistic update: show the transaction in the UI immediately without
    // waiting for the Firestore real-time stream to emit.
    _transactions = [tx, ..._transactions];
    notifyListeners();
    try {
      await _firestoreService.addTransaction(tx);
      // The Firestore stream will soon emit the authoritative list and
      // overwrite _transactions, placing the new item in its correct position.
    } catch (e) {
      // Roll back the optimistic insert on failure.
      _transactions = _transactions.where((t) => t.id != tx.id).toList();
      notifyListeners();
      debugPrint('Error adding transaction: $e');
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
