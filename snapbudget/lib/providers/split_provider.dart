import 'package:flutter/material.dart';
import 'dart:async';
import '../models/split_group_model.dart';
import '../models/group_expense_model.dart';
import '../services/firestore_service.dart';

class SplitProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<SplitGroupModel> _groups = [];
  Map<String, List<GroupExpenseModel>> _expenses = {};
  bool _isLoading = false;
  StreamSubscription? _groupSub;
  Map<String, StreamSubscription> _expenseSubs = {};

  List<SplitGroupModel> get groups => _groups;
  List<GroupExpenseModel> getExpenses(String groupId) =>
      _expenses[groupId] ?? [];
  bool get isLoading => _isLoading;

  void loadGroups(String userId) {
    _setLoading(true);
    _groupSub?.cancel();

    _groupSub = _firestoreService.getSplitGroups(userId).listen(
      (data) {
        _groups = data;
        _setLoading(false);
        // Load expenses for each group
        for (final group in data) {
          _loadGroupExpenses(group.groupId);
        }
      },
      onError: (e) {
        print('Error loading split groups: $e');
        _setLoading(false);
      },
    );
  }

  void _loadGroupExpenses(String groupId) {
    _expenseSubs[groupId]?.cancel();
    _expenseSubs[groupId] = _firestoreService.getGroupExpenses(groupId).listen(
      (data) {
        _expenses[groupId] = data;
        notifyListeners();
      },
      onError: (e) => print('Error loading expenses for group $groupId: $e'),
    );
  }

  Future<void> createGroup(SplitGroupModel group) async {
    try {
      await _firestoreService.createSplitGroup(group);
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  Future<void> addGroupExpense(GroupExpenseModel expense) async {
    try {
      await _firestoreService.addGroupExpense(expense);
    } catch (e) {
      print('Error adding group expense: $e');
      rethrow;
    }
  }

  void clear() {
    _groupSub?.cancel();
    for (final sub in _expenseSubs.values) {
      sub.cancel();
    }
    _expenseSubs.clear();
    _groups = [];
    _expenses.clear();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    for (final sub in _expenseSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
