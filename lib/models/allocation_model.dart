import 'package:cloud_firestore/cloud_firestore.dart';

class AllocationModel {
  final String allocationId;
  final String userId;
  final double amount;
  final DateTime date;
  final String cycleId;
  final String? groupId;
  final bool disbursed;
  final DateTime? disbursementDate;
  final String? disbursementMethod;
  final String? mpesaRef;
  final String? notes;
  final Map<String, dynamic>? metadata;

  AllocationModel({
    required this.allocationId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.cycleId,
    this.groupId,
    this.disbursed = false,
    this.disbursementDate,
    this.disbursementMethod,
    this.mpesaRef,
    this.notes,
    this.metadata,
  });

  // Convert AllocationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'allocationId': allocationId,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'cycleId': cycleId,
      'groupId': groupId,
      'disbursed': disbursed,
      'disbursementDate': disbursementDate != null
          ? Timestamp.fromDate(disbursementDate!)
          : null,
      'disbursementMethod': disbursementMethod,
      'mpesaRef': mpesaRef,
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Create AllocationModel from Firestore document
  factory AllocationModel.fromMap(Map<String, dynamic> map) {
    return AllocationModel(
      allocationId: map['allocationId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      cycleId: map['cycleId'] ?? '',
      groupId: map['groupId'],
      disbursed: map['disbursed'] ?? false,
      disbursementDate: map['disbursementDate'] != null
          ? (map['disbursementDate'] as Timestamp).toDate()
          : null,
      disbursementMethod: map['disbursementMethod'],
      mpesaRef: map['mpesaRef'],
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  // Create AllocationModel from Firestore document snapshot
  factory AllocationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AllocationModel.fromMap(data);
  }

  // Copy with method for updating specific fields
  AllocationModel copyWith({
    String? allocationId,
    String? userId,
    double? amount,
    DateTime? date,
    String? cycleId,
    String? groupId,
    bool? disbursed,
    DateTime? disbursementDate,
    String? disbursementMethod,
    String? mpesaRef,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return AllocationModel(
      allocationId: allocationId ?? this.allocationId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      cycleId: cycleId ?? this.cycleId,
      groupId: groupId ?? this.groupId,
      disbursed: disbursed ?? this.disbursed,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      disbursementMethod: disbursementMethod ?? this.disbursementMethod,
      mpesaRef: mpesaRef ?? this.mpesaRef,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if allocation is disbursed
  bool get isDisbursed => disbursed;

  // Check if allocation is pending disbursement
  bool get isPendingDisbursement => !disbursed;

  // Get allocation month/year
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  String toString() {
    return 'AllocationModel(allocationId: $allocationId, userId: $userId, amount: $amount, disbursed: $disbursed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllocationModel && other.allocationId == allocationId;
  }

  @override
  int get hashCode => allocationId.hashCode;
}

class CycleModel {
  final String cycleId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> members;
  final int currentIndex;
  final bool isActive;
  final DateTime? completedDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  CycleModel({
    required this.cycleId,
    required this.startDate,
    required this.endDate,
    required this.members,
    this.currentIndex = 0,
    this.isActive = true,
    this.completedDate,
    this.notes,
    this.metadata,
  });

  // Convert CycleModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'cycleId': cycleId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'members': members,
      'currentIndex': currentIndex,
      'isActive': isActive,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Create CycleModel from Firestore document
  factory CycleModel.fromMap(Map<String, dynamic> map) {
    return CycleModel(
      cycleId: map['cycleId'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      members: List<String>.from(map['members'] ?? []),
      currentIndex: map['currentIndex'] ?? 0,
      isActive: map['isActive'] ?? true,
      completedDate: map['completedDate'] != null
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  // Create CycleModel from Firestore document snapshot
  factory CycleModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleModel.fromMap(data);
  }

  // Copy with method for updating specific fields
  CycleModel copyWith({
    String? cycleId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? members,
    int? currentIndex,
    bool? isActive,
    DateTime? completedDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return CycleModel(
      cycleId: cycleId ?? this.cycleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      members: members ?? this.members,
      currentIndex: currentIndex ?? this.currentIndex,
      isActive: isActive ?? this.isActive,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if cycle is completed
  bool get isCompleted => !isActive || completedDate != null;

  // Check if cycle is active
  bool get isActiveCycle => isActive && completedDate == null;

  // Get next member to receive allocation
  String? get nextMember {
    if (currentIndex >= members.length) return null;
    return members[currentIndex];
  }

  // Get progress percentage
  double get progressPercentage {
    if (members.isEmpty) return 0;
    return (currentIndex / members.length) * 100;
  }

  // Get remaining members
  List<String> get remainingMembers {
    if (currentIndex >= members.length) return [];
    return members.sublist(currentIndex);
  }

  // Get completed members
  List<String> get completedMembers {
    if (currentIndex == 0) return [];
    return members.sublist(0, currentIndex);
  }

  // Check if all members have received allocation
  bool get allMembersAllocated => currentIndex >= members.length;

  // Get cycle duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  // Get days remaining in cycle
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  @override
  String toString() {
    return 'CycleModel(cycleId: $cycleId, startDate: $startDate, endDate: $endDate, currentIndex: $currentIndex, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CycleModel && other.cycleId == cycleId;
  }

  @override
  int get hashCode => cycleId.hashCode;
}
