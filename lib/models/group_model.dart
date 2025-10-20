import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String description;
  final String adminId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? settings;

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.adminId,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.settings,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'settings': settings,
    };
  }

  // Create from Firestore document
  factory GroupModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      groupId: data['groupId'] ?? doc.id,
      groupName: data['groupName'] ?? '',
      description: data['description'] ?? '',
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      settings: data['settings'],
    );
  }

  // Create from Map
  factory GroupModel.fromMap(Map<String, dynamic> data) {
    return GroupModel(
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      description: data['description'] ?? '',
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      settings: data['settings'],
    );
  }

  // Copy with method
  GroupModel copyWith({
    String? groupId,
    String? groupName,
    String? description,
    String? adminId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return GroupModel(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  // Helper methods
  bool get hasMembers => memberIds.isNotEmpty;
  int get memberCount => memberIds.length;
  bool isMember(String userId) => memberIds.contains(userId);
  bool isAdmin(String userId) => adminId == userId;
  bool canManage(String userId) => isAdmin(userId) || isMember(userId);

  @override
  String toString() {
    return 'GroupModel(groupId: $groupId, groupName: $groupName, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;
}
