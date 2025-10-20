import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profileUrl;
  final DateTime joinedAt;
  final String status; // active, suspended, inactive
  final Map<String, dynamic>? preferences;
  final DateTime? lastLoginAt;
  final int? consecutiveMisses;
  final DateTime? lastContributionDate;
  final List<String>? groupIds;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileUrl,
    required this.joinedAt,
    this.status = 'active',
    this.preferences,
    this.lastLoginAt,
    this.consecutiveMisses = 0,
    this.lastContributionDate,
    this.groupIds,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileUrl': profileUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
      'preferences': preferences,
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'consecutiveMisses': consecutiveMisses,
      'lastContributionDate': lastContributionDate != null
          ? Timestamp.fromDate(lastContributionDate!)
          : null,
      'groupIds': groupIds,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? AppConstants.memberRole,
      profileUrl: map['profileUrl'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'active',
      preferences: map['preferences'],
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : null,
      consecutiveMisses: map['consecutiveMisses'] ?? 0,
      lastContributionDate: map['lastContributionDate'] != null
          ? (map['lastContributionDate'] as Timestamp).toDate()
          : null,
      groupIds: (map['groupIds'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  // Create UserModel from Firestore document snapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // Copy with method for updating specific fields
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profileUrl,
    DateTime? joinedAt,
    String? status,
    Map<String, dynamic>? preferences,
    DateTime? lastLoginAt,
    int? consecutiveMisses,
    DateTime? lastContributionDate,
    List<String>? groupIds,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileUrl: profileUrl ?? this.profileUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
      lastContributionDate: lastContributionDate ?? this.lastContributionDate,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == AppConstants.adminRole;

  // Check if user is member
  bool get isMember => role == AppConstants.memberRole;

  // Check if user is active
  bool get isActive => status == 'active';

  // Check if user is suspended
  bool get isSuspended => status == 'suspended';

  // Get user display name (first name)
  String get displayName {
    final names = name.split(' ');
    return names.isNotEmpty ? names[0] : name;
  }

  // Get user initials
  String get initials {
    final names = name.split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[1][0]}'.toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
