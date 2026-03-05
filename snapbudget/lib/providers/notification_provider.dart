import 'package:flutter/material.dart';
import 'dart:async';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  int get unreadCount =>
      _alerts.where((a) => a.status == AlertStatus.unread).length;

  void loadAlerts(String userId) {
    _setLoading(true);
    _subscription?.cancel();

    _subscription = _firestoreService.getAlerts(userId).listen(
      (data) {
        _alerts = data;
        _setLoading(false);
      },
      onError: (e) {
        print('Error loading alerts: $e');
        _setLoading(false);
      },
    );
  }

  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.alertId == alertId);
    if (index != -1) {
      final updated = _alerts[index].copyWith(status: AlertStatus.read);
      try {
        await _firestoreService.addAlert(updated);
      } catch (e) {
        print('Error marking alert as read: $e');
      }
    }
  }

  Future<void> markAllAsRead(String userId) async {
    for (final alert in _alerts) {
      if (alert.status == AlertStatus.unread) {
        await markAsRead(alert.alertId);
      }
    }
  }

  void clear() {
    _subscription?.cancel();
    _alerts = [];
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
