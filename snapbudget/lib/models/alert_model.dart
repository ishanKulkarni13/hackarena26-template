class AlertModel {
  final String alertId;
  final String userId;
  final String type; // budget_warning, unusual_spending
  final String message;
  final DateTime createdAt;
  final AlertStatus status;

  AlertModel({
    required this.alertId,
    required this.userId,
    required this.type,
    required this.message,
    DateTime? createdAt,
    this.status = AlertStatus.unread,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map, String docId) {
    return AlertModel(
      alertId: docId,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'budget_warning',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AlertStatus.unread,
      ),
    );
  }
  AlertModel copyWith({
    String? alertId,
    String? userId,
    String? type,
    String? message,
    DateTime? createdAt,
    AlertStatus? status,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum AlertStatus { read, unread }
