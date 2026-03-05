import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart' as tm;
import '../models/receipt_model.dart';
import '../models/sms_transaction_model.dart';
import '../models/split_group_model.dart';
import '../models/group_expense_model.dart';
import '../models/budget_model.dart';
import '../models/alert_model.dart';
import '../models/analytics_cache_model.dart';
import '../models/widget_data_model.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- USERS ---
  Future<void> createUser(UserModel user) =>
      _db.collection('users').doc(user.userId).set(user.toMap());

  Stream<UserModel?> getUser(String userId) =>
      _db.collection('users').doc(userId).snapshots().map((snap) =>
          snap.exists ? UserModel.fromMap(snap.data()!, snap.id) : null);

  // --- TRANSACTIONS ---
  Future<void> addTransaction(tm.Transaction tx) =>
      _db.collection('transactions').doc(tx.id).set(tx.toMap());

  Stream<List<tm.Transaction>> getTransactions(String userId) => _db
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => tm.Transaction.fromMap(doc.data(), doc.id))
          .toList());

  // --- RECEIPTS ---
  Future<void> addReceipt(ReceiptModel receipt) =>
      _db.collection('receipts').doc(receipt.receiptId).set(receipt.toMap());

  Stream<List<ReceiptModel>> getReceipts(String userId) => _db
      .collection('receipts')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ReceiptModel.fromMap(doc.data(), doc.id))
          .toList());

  // --- SMS TRANSACTIONS ---
  Future<void> addSmsTransaction(SmsTransactionModel smsTx) =>
      _db.collection('sms_transactions').doc(smsTx.smsId).set(smsTx.toMap());

  // --- SPLIT GROUPS ---
  Future<void> createSplitGroup(SplitGroupModel group) =>
      _db.collection('split_groups').doc(group.groupId).set(group.toMap());

  Stream<List<SplitGroupModel>> getSplitGroups(String userId) => _db
      .collection('split_groups')
      .where('members', arrayContains: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => SplitGroupModel.fromMap(doc.data(), doc.id))
          .toList());

  // --- GROUP EXPENSES ---
  Future<void> addGroupExpense(GroupExpenseModel expense) => _db
      .collection('group_expenses')
      .doc(expense.expenseId)
      .set(expense.toMap());

  Stream<List<GroupExpenseModel>> getGroupExpenses(String groupId) => _db
      .collection('group_expenses')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => GroupExpenseModel.fromMap(doc.data(), doc.id))
          .toList());

  Future<void> updateGroupExpense(GroupExpenseModel expense) => _db
      .collection('group_expenses')
      .doc(expense.expenseId)
      .set(expense.toMap(), SetOptions(merge: true));

  // --- BUDGETS ---
  Future<void> setBudget(BudgetModel budget) =>
      _db.collection('budgets').doc(budget.budgetId).set(budget.toMap());

  Stream<List<BudgetModel>> getBudgets(String userId, int month, int year) =>
      _db
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
              .toList());

  // --- ALERTS ---
  Future<void> addAlert(AlertModel alert) =>
      _db.collection('alerts').doc(alert.alertId).set(alert.toMap());

  Stream<List<AlertModel>> getAlerts(String userId) => _db
      .collection('alerts')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
          .toList());

  // --- ANALYTICS CACHE ---
  Future<void> updateAnalyticsCache(AnalyticsCacheModel cache) => _db
      .collection('analytics_cache')
      .doc('${cache.userId}_${cache.month}')
      .set(cache.toMap());

  // --- WIDGET DATA ---
  Future<void> updateWidgetData(WidgetDataModel data) =>
      _db.collection('widgets').doc(data.userId).set(data.toMap());
}
