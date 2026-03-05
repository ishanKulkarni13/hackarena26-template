class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto;
  final DateTime createdAt;
  final PrivacyMode privacyMode;
  final String currency;
  final Map<String, bool> notificationSettings;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
    required this.createdAt,
    this.privacyMode = PrivacyMode.cloudSync,
    this.currency = 'INR',
    this.notificationSettings = const {
      'transactions': true,
      'budgetAlerts': true,
      'splitSync': true,
    },
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt.toIso8601String(),
      'privacyMode': privacyMode.name,
      'currency': currency,
      'notificationSettings': notificationSettings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      userId: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profilePhoto: map['profilePhoto'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      privacyMode: PrivacyMode.values.firstWhere(
        (e) => e.name == map['privacyMode'],
        orElse: () => PrivacyMode.cloudSync,
      ),
      currency: map['currency'] ?? 'INR',
      notificationSettings:
          Map<String, bool>.from(map['notificationSettings'] ?? {}),
    );
  }
}

enum PrivacyMode { localOnly, cloudSync }
