import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class LoanModel {
  final String loanId;
  final String userId;
  final double requestedAmount;
  final double? approvedAmount;
  final String purpose;
  final String status;
  final double interestRate;
  final DateTime requestDate;
  final DateTime? approvalDate;
  final DateTime? disbursementDate;
  final DateTime? dueDate;
  final List<RepaymentSchedule> repaymentSchedule;
  final String? approvedBy;
  final String? rejectionReason;
  final String? notes;
  final Map<String, dynamic>? metadata;

  LoanModel({
    required this.loanId,
    required this.userId,
    required this.requestedAmount,
    this.approvedAmount,
    required this.purpose,
    required this.status,
    required this.interestRate,
    required this.requestDate,
    this.approvalDate,
    this.disbursementDate,
    this.dueDate,
    this.repaymentSchedule = const [],
    this.approvedBy,
    this.rejectionReason,
    this.notes,
    this.metadata,
  });

  // Convert LoanModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'userId': userId,
      'requestedAmount': requestedAmount,
      'approvedAmount': approvedAmount,
      'purpose': purpose,
      'status': status,
      'interestRate': interestRate,
      'requestDate': Timestamp.fromDate(requestDate),
      'approvalDate': approvalDate != null
          ? Timestamp.fromDate(approvalDate!)
          : null,
      'disbursementDate': disbursementDate != null
          ? Timestamp.fromDate(disbursementDate!)
          : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'repaymentSchedule': repaymentSchedule
          .map((schedule) => schedule.toMap())
          .toList(),
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Create LoanModel from Firestore document
  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      loanId: map['loanId'] ?? '',
      userId: map['userId'] ?? '',
      requestedAmount: (map['requestedAmount'] ?? 0.0).toDouble(),
      approvedAmount: map['approvedAmount']?.toDouble(),
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? AppConstants.loanPending,
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      approvalDate: map['approvalDate'] != null
          ? (map['approvalDate'] as Timestamp).toDate()
          : null,
      disbursementDate: map['disbursementDate'] != null
          ? (map['disbursementDate'] as Timestamp).toDate()
          : null,
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      repaymentSchedule:
          (map['repaymentSchedule'] as List<dynamic>?)
              ?.map((schedule) => RepaymentSchedule.fromMap(schedule))
              .toList() ??
          [],
      approvedBy: map['approvedBy'],
      rejectionReason: map['rejectionReason'],
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  // Create LoanModel from Firestore document snapshot
  factory LoanModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel.fromMap(data);
  }

  // Copy with method for updating specific fields
  LoanModel copyWith({
    String? loanId,
    String? userId,
    double? requestedAmount,
    double? approvedAmount,
    String? purpose,
    String? status,
    double? interestRate,
    DateTime? requestDate,
    DateTime? approvalDate,
    DateTime? disbursementDate,
    DateTime? dueDate,
    List<RepaymentSchedule>? repaymentSchedule,
    String? approvedBy,
    String? rejectionReason,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return LoanModel(
      loanId: loanId ?? this.loanId,
      userId: userId ?? this.userId,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      interestRate: interestRate ?? this.interestRate,
      requestDate: requestDate ?? this.requestDate,
      approvalDate: approvalDate ?? this.approvalDate,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      dueDate: dueDate ?? this.dueDate,
      repaymentSchedule: repaymentSchedule ?? this.repaymentSchedule,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if loan is pending
  bool get isPending => status == AppConstants.loanPending;

  // Check if loan is approved
  bool get isApproved => status == AppConstants.loanApproved;

  // Check if loan is rejected
  bool get isRejected => status == AppConstants.loanRejected;

  // Check if loan is active
  bool get isActive => status == AppConstants.loanActive;

  // Check if loan is completed
  bool get isCompleted => status == AppConstants.loanCompleted;

  // Get final approved amount
  double get finalAmount => approvedAmount ?? requestedAmount;

  // Calculate total interest
  double get totalInterest {
    if (dueDate == null) return 0;
    final days = dueDate!.difference(requestDate).inDays;
    return finalAmount * (interestRate / 100) * (days / 365);
  }

  // Calculate total amount to be repaid
  double get totalAmountToRepay => finalAmount + totalInterest;

  // Get remaining balance
  double get remainingBalance {
    final totalPaid = repaymentSchedule
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
    return totalAmountToRepay - totalPaid;
  }

  // Check if loan is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isCompleted;
  }

  // Get days overdue
  int get daysOverdue {
    if (dueDate == null || !isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  // Get next payment due
  RepaymentSchedule? get nextPaymentDue {
    return repaymentSchedule.where((payment) => !payment.isPaid).isNotEmpty
        ? repaymentSchedule.where((payment) => !payment.isPaid).first
        : null;
  }

  @override
  String toString() {
    return 'LoanModel(loanId: $loanId, userId: $userId, requestedAmount: $requestedAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanModel && other.loanId == loanId;
  }

  @override
  int get hashCode => loanId.hashCode;
}

class RepaymentSchedule {
  final String paymentId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;
  final String? notes;

  RepaymentSchedule({
    required this.paymentId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
    this.notes,
  });

  // Convert RepaymentSchedule to Map
  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'isPaid': isPaid,
      'notes': notes,
    };
  }

  // Create RepaymentSchedule from Map
  factory RepaymentSchedule.fromMap(Map<String, dynamic> map) {
    return RepaymentSchedule(
      paymentId: map['paymentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      isPaid: map['isPaid'] ?? false,
      notes: map['notes'],
    );
  }

  // Copy with method
  RepaymentSchedule copyWith({
    String? paymentId,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
    String? notes,
  }) {
    return RepaymentSchedule(
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }

  // Check if payment is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && !isPaid;
  }

  // Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  @override
  String toString() {
    return 'RepaymentSchedule(paymentId: $paymentId, amount: $amount, dueDate: $dueDate, isPaid: $isPaid)';
  }
}
