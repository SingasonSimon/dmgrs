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

  // Validation methods
  static String? validateGroupName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Group name is required';
    }
    if (name.trim().length < 3) {
      return 'Group name must be at least 3 characters';
    }
    if (name.trim().length > 50) {
      return 'Group name must be less than 50 characters';
    }
    return null;
  }

  static String? validateDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  // Business logic methods
  bool get hasMembers => memberIds.isNotEmpty;
  int get memberCount => memberIds.length;
  bool isMember(String userId) => memberIds.contains(userId);
  bool isAdmin(String userId) => adminId == userId;
  bool canManage(String userId) => isAdmin(userId) || isMember(userId);

  // Advanced helper methods
  bool get canAcceptNewMembers =>
      isActive && memberCount < 100; // Example limit
  bool get needsAdminAttention => !isActive || memberCount == 0;
  String get statusText => isActive ? 'Active' : 'Inactive';
  DateTime get lastActivity => updatedAt ?? createdAt;

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
