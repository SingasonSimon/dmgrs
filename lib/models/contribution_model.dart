import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class ContributionModel {
  final String contributionId;
  final String userId;
  final double amount;
  final DateTime date;
  final String status;
  final String? mpesaRef;
  final double? penaltyAmount;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  ContributionModel({
    required this.contributionId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
    this.mpesaRef,
    this.penaltyAmount,
    this.dueDate,
    this.paidDate,
    this.notes,
    this.metadata,
  });

  // Convert ContributionModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'contributionId': contributionId,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'mpesaRef': mpesaRef,
      'penaltyAmount': penaltyAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Create ContributionModel from Firestore document
  factory ContributionModel.fromMap(Map<String, dynamic> map) {
    return ContributionModel(
      contributionId: map['contributionId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? AppConstants.paymentPending,
      mpesaRef: map['mpesaRef'],
      penaltyAmount: map['penaltyAmount']?.toDouble(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  // Create ContributionModel from Firestore document snapshot
  factory ContributionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContributionModel.fromMap(data);
  }

  // Copy with method for updating specific fields
  ContributionModel copyWith({
    String? contributionId,
    String? userId,
    double? amount,
    DateTime? date,
    String? status,
    String? mpesaRef,
    double? penaltyAmount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ContributionModel(
      contributionId: contributionId ?? this.contributionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      mpesaRef: mpesaRef ?? this.mpesaRef,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if contribution is completed
  bool get isCompleted => status == AppConstants.paymentCompleted;

  // Check if contribution is pending
  bool get isPending => status == AppConstants.paymentPending;

  // Check if contribution is failed
  bool get isFailed => status == AppConstants.paymentFailed;

  // Check if contribution is overdue
  bool get isOverdue => status == AppConstants.paymentOverdue;

  // Check if contribution has penalty
  bool get hasPenalty => penaltyAmount != null && penaltyAmount! > 0;

  // Get total amount (contribution + penalty)
  double get totalAmount => amount + (penaltyAmount ?? 0);

  // Check if payment is late
  bool get isLate {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isCompleted;
  }

  // Get days overdue
  int get daysOverdue {
    if (dueDate == null || !isLate) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  // Get contribution month/year
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  String toString() {
    return 'ContributionModel(contributionId: $contributionId, userId: $userId, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContributionModel && other.contributionId == contributionId;
  }

  @override
  int get hashCode => contributionId.hashCode;
}
