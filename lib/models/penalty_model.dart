import 'package:cloud_firestore/cloud_firestore.dart';

class PenaltyModel {
  final String penaltyId;
  final String userId;
  final String contributionId;
  final double amount;
  final String reason;
  final String status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? waivedAt;
  final String? waivedReason;

  PenaltyModel({
    required this.penaltyId,
    required this.userId,
    required this.contributionId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.waivedAt,
    this.waivedReason,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'penaltyId': penaltyId,
      'userId': userId,
      'contributionId': contributionId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'waivedAt': waivedAt != null ? Timestamp.fromDate(waivedAt!) : null,
      'waivedReason': waivedReason,
    };
  }

  // Create from Map (from Firestore)
  factory PenaltyModel.fromMap(Map<String, dynamic> map) {
    return PenaltyModel(
      penaltyId: map['penaltyId'] ?? '',
      userId: map['userId'] ?? '',
      contributionId: map['contributionId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      waivedAt: (map['waivedAt'] as Timestamp?)?.toDate(),
      waivedReason: map['waivedReason'],
    );
  }

  // Copy with method
  PenaltyModel copyWith({
    String? penaltyId,
    String? userId,
    String? contributionId,
    double? amount,
    String? reason,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? waivedAt,
    String? waivedReason,
  }) {
    return PenaltyModel(
      penaltyId: penaltyId ?? this.penaltyId,
      userId: userId ?? this.userId,
      contributionId: contributionId ?? this.contributionId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      waivedAt: waivedAt ?? this.waivedAt,
      waivedReason: waivedReason ?? this.waivedReason,
    );
  }

  // Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'waived':
        return 'Waived';
      default:
        return status;
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'paid':
        return 'green';
      case 'waived':
        return 'blue';
      default:
        return 'gray';
    }
  }

  // Check if penalty is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status == 'pending';
  }

  // Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  @override
  String toString() {
    return 'PenaltyModel(penaltyId: $penaltyId, userId: $userId, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PenaltyModel && other.penaltyId == penaltyId;
  }

  @override
  int get hashCode => penaltyId.hashCode;
}
