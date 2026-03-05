class SplitGroupModel {
  final String groupId;
  final String groupName;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;
  final String groupType; // trip, roommates, friends

  SplitGroupModel({
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    required this.members,
    DateTime? createdAt,
    this.groupType = 'friends',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'createdBy': createdBy,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'groupType': groupType,
    };
  }

  factory SplitGroupModel.fromMap(Map<String, dynamic> map, String docId) {
    return SplitGroupModel(
      groupId: docId,
      groupName: map['groupName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      groupType: map['groupType'] ?? 'friends',
    );
  }
}
