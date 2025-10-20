import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/contribution_model.dart';
import '../models/loan_model.dart';
import '../models/allocation_model.dart';
import '../models/notification_model.dart';
import '../models/group_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.userId)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<UserModel?> getUser(String userId) async {
    try {
      print('FirestoreService: Getting user with ID: $userId');
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        print('FirestoreService: User document exists, creating UserModel');
        final userModel = UserModel.fromDocument(doc);
        print(
          'FirestoreService: UserModel created - ${userModel.name} (${userModel.role})',
        );
        return userModel;
      }
      print('FirestoreService: User document does not exist');
      return null;
    } catch (e) {
      print('FirestoreService: Error getting user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.userId)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('joinedAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  static Future<List<UserModel>> getActiveMembers() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.memberRole)
          .where('status', isEqualTo: 'active')
          .orderBy('joinedAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active members: $e');
    }
  }

  // Contribution Operations
  static Future<void> createContribution(ContributionModel contribution) async {
    try {
      await _firestore
          .collection(AppConstants.contributionsCollection)
          .doc(contribution.contributionId)
          .set(contribution.toMap());
    } catch (e) {
      throw Exception('Failed to create contribution: $e');
    }
  }

  static Future<ContributionModel?> getContribution(
    String contributionId,
  ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.contributionsCollection)
          .doc(contributionId)
          .get();

      if (doc.exists) {
        return ContributionModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get contribution: $e');
    }
  }

  static Future<List<ContributionModel>> getUserContributions(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.contributionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final contributions = querySnapshot.docs
          .map((doc) => ContributionModel.fromDocument(doc))
          .toList();

      // Sort by date in memory
      contributions.sort((a, b) => b.date.compareTo(a.date));

      return contributions;
    } catch (e) {
      throw Exception('Failed to get user contributions: $e');
    }
  }

  static Future<List<ContributionModel>> getAllContributions() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.contributionsCollection)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContributionModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all contributions: $e');
    }
  }

  static Future<List<ContributionModel>> getPendingContributions() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.contributionsCollection)
          .where('status', isEqualTo: AppConstants.paymentPending)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContributionModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending contributions: $e');
    }
  }

  static Future<void> updateContribution(ContributionModel contribution) async {
    try {
      await _firestore
          .collection(AppConstants.contributionsCollection)
          .doc(contribution.contributionId)
          .update(contribution.toMap());
    } catch (e) {
      throw Exception('Failed to update contribution: $e');
    }
  }

  // Loan Operations
  static Future<void> createLoan(LoanModel loan) async {
    try {
      await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loan.loanId)
          .set(loan.toMap());
    } catch (e) {
      throw Exception('Failed to create loan: $e');
    }
  }

  static Future<void> updateLoanStatus(
    String loanId,
    String status, {
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update loan status: $e');
    }
  }

  static Future<LoanModel?> getLoan(String loanId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .get();

      if (doc.exists) {
        return LoanModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get loan: $e');
    }
  }

  static Future<List<LoanModel>> getUserLoans(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.loansCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final loans = querySnapshot.docs
          .map((doc) => LoanModel.fromDocument(doc))
          .toList();

      // Sort by request date in memory
      loans.sort((a, b) => b.requestDate.compareTo(a.requestDate));

      return loans;
    } catch (e) {
      throw Exception('Failed to get user loans: $e');
    }
  }

  static Future<List<LoanModel>> getAllLoans() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.loansCollection)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LoanModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all loans: $e');
    }
  }

  static Future<List<LoanModel>> getPendingLoans() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.loansCollection)
          .where('status', isEqualTo: AppConstants.loanPending)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LoanModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending loans: $e');
    }
  }

  static Future<void> updateLoan(LoanModel loan) async {
    try {
      await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loan.loanId)
          .update(loan.toMap());
    } catch (e) {
      throw Exception('Failed to update loan: $e');
    }
  }

  // Allocation Operations
  static Future<void> createAllocation(AllocationModel allocation) async {
    try {
      await _firestore
          .collection(AppConstants.allocationsCollection)
          .doc(allocation.allocationId)
          .set(allocation.toMap());
    } catch (e) {
      throw Exception('Failed to create allocation: $e');
    }
  }

  static Future<AllocationModel?> getAllocation(String allocationId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.allocationsCollection)
          .doc(allocationId)
          .get();

      if (doc.exists) {
        return AllocationModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get allocation: $e');
    }
  }

  static Future<List<AllocationModel>> getUserAllocations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.allocationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AllocationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user allocations: $e');
    }
  }

  static Future<List<AllocationModel>> getAllAllocations() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.allocationsCollection)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AllocationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all allocations: $e');
    }
  }

  // Get allocations filtered by cycle
  static Future<List<AllocationModel>> getAllocationsByCycle(
    String cycleId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.allocationsCollection)
          .where('cycleId', isEqualTo: cycleId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AllocationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get allocations by cycle: $e');
    }
  }

  static Future<void> updateAllocation(AllocationModel allocation) async {
    try {
      await _firestore
          .collection(AppConstants.allocationsCollection)
          .doc(allocation.allocationId)
          .update(allocation.toMap());
    } catch (e) {
      throw Exception('Failed to update allocation: $e');
    }
  }

  // Cycle Operations
  static Future<void> createCycle(CycleModel cycle) async {
    try {
      await _firestore
          .collection(AppConstants.cyclesCollection)
          .doc(cycle.cycleId)
          .set(cycle.toMap());
    } catch (e) {
      throw Exception('Failed to create cycle: $e');
    }
  }

  static Future<CycleModel?> getCurrentCycle() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.cyclesCollection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return CycleModel.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current cycle: $e');
    }
  }

  static Future<List<CycleModel>> getAllCycles() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.cyclesCollection)
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CycleModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all cycles: $e');
    }
  }

  static Future<void> updateCycle(CycleModel cycle) async {
    try {
      await _firestore
          .collection(AppConstants.cyclesCollection)
          .doc(cycle.cycleId)
          .update(cycle.toMap());
    } catch (e) {
      throw Exception('Failed to update cycle: $e');
    }
  }

  // Lending Pool Operations
  static Future<Map<String, dynamic>?> getLendingPool() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.lendingPoolCollection)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lending pool: $e');
    }
  }

  static Future<void> updateLendingPool(Map<String, dynamic> poolData) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.lendingPoolCollection)
          .doc('current');

      await docRef.set(poolData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update lending pool: $e');
    }
  }

  // Transaction Operations
  static Future<void> createTransaction(
    Map<String, dynamic> transaction,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.transactionsCollection)
          .add(transaction);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserTransactions(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user transactions: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.transactionsCollection)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get all transactions: $e');
    }
  }

  // Real-time listeners
  static Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList(),
        );
  }

  static Stream<List<ContributionModel>> getUserContributionsStream(
    String userId,
  ) {
    return _firestore
        .collection(AppConstants.contributionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ContributionModel.fromDocument(doc))
              .toList(),
        );
  }

  static Stream<List<LoanModel>> getUserLoansStream(String userId) {
    return _firestore
        .collection(AppConstants.loansCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => LoanModel.fromDocument(doc)).toList(),
        );
  }

  static Stream<CycleModel?> getCurrentCycleStream() {
    return _firestore
        .collection(AppConstants.cyclesCollection)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? CycleModel.fromDocument(snapshot.docs.first)
              : null,
        );
  }

  // Notification Operations
  static Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  static Future<List<NotificationModel>> getUserNotifications(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .get();

      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      // Sort by creation date in memory
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  static Future<void> updateNotification(
    String notificationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Update loan payment with M-Pesa reference
  static Future<bool> updateLoanPayment({
    required String loanId,
    required String paymentId,
    required String mpesaRef,
    required String status,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loanData = loanDoc.data()!;
      final repaymentSchedule = List<Map<String, dynamic>>.from(
        loanData['repaymentSchedule'] ?? [],
      );

      // Find and update the specific payment
      bool paymentFound = false;
      for (int i = 0; i < repaymentSchedule.length; i++) {
        if (repaymentSchedule[i]['paymentId'] == paymentId) {
          repaymentSchedule[i]['mpesaRef'] = mpesaRef;
          repaymentSchedule[i]['status'] = status;
          repaymentSchedule[i]['updatedAt'] = FieldValue.serverTimestamp();
          paymentFound = true;
          break;
        }
      }

      if (!paymentFound) {
        throw Exception('Payment not found in loan');
      }

      // Update the loan document
      await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .update({
            'repaymentSchedule': repaymentSchedule,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      throw Exception('Failed to update loan payment: $e');
    }
  }

  // Mark a loan payment as completed
  static Future<bool> markLoanPaymentCompleted({
    required String loanId,
    required String paymentId,
    String? mpesaRef,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        throw Exception('Loan not found');
      }

      final loanData = loanDoc.data()!;
      final repaymentSchedule = List<Map<String, dynamic>>.from(
        loanData['repaymentSchedule'] ?? [],
      );

      // Find and update the specific payment
      bool paymentFound = false;
      bool allPaymentsCompleted = true;

      for (int i = 0; i < repaymentSchedule.length; i++) {
        if (repaymentSchedule[i]['paymentId'] == paymentId) {
          repaymentSchedule[i]['isPaid'] = true;
          repaymentSchedule[i]['paidDate'] = FieldValue.serverTimestamp();
          repaymentSchedule[i]['status'] = AppConstants.paymentCompleted;
          if (mpesaRef != null) {
            repaymentSchedule[i]['mpesaRef'] = mpesaRef;
          }
          repaymentSchedule[i]['updatedAt'] = FieldValue.serverTimestamp();
          paymentFound = true;
        }

        // Check if all payments are completed
        if (!repaymentSchedule[i]['isPaid']) {
          allPaymentsCompleted = false;
        }
      }

      if (!paymentFound) {
        throw Exception('Payment not found');
      }

      // Update loan status if all payments are completed
      String newLoanStatus = loanData['status'];
      if (allPaymentsCompleted) {
        newLoanStatus = AppConstants.loanCompleted;
      }

      // Update the loan document
      await _firestore
          .collection(AppConstants.loansCollection)
          .doc(loanId)
          .update({
            'repaymentSchedule': repaymentSchedule,
            'status': newLoanStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      throw Exception('Failed to mark loan payment as completed: $e');
    }
  }

  // (duplicate allocation and cycle methods removed below; originals defined earlier in file)

  // Generate allocations for a cycle
  static Future<void> generateCycleAllocations(CycleModel cycle) async {
    try {
      final batch = _firestore.batch();

      // Get total contributions for the cycle period
      final contributionsSnapshot = await _firestore
          .collection(AppConstants.contributionsCollection)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cycle.startDate),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(cycle.endDate))
          .where('status', isEqualTo: AppConstants.paymentCompleted)
          .get();

      final totalContributions = contributionsSnapshot.docs.fold(
        0.0,
        (sum, doc) => sum + (doc.data()['amount'] ?? 0.0),
      );

      final allocationAmount =
          totalContributions * AppConstants.memberDistributionPercentage;

      // Create allocations for each member
      for (int i = 0; i < cycle.members.length; i++) {
        final memberId = cycle.members[i];
        final allocationId =
            '${cycle.cycleId}_${memberId}_${DateTime.now().millisecondsSinceEpoch}';

        final allocation = AllocationModel(
          allocationId: allocationId,
          userId: memberId,
          amount: allocationAmount,
          date: DateTime.now(),
          cycleId: cycle.cycleId,
        );

        final allocationRef = _firestore
            .collection(AppConstants.allocationsCollection)
            .doc(allocationId);

        batch.set(allocationRef, allocation.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to generate cycle allocations: $e');
    }
  }

  // Group Management Operations
  static Future<void> createGroup(GroupModel group) async {
    try {
      await _firestore
          .collection('groups')
          .doc(group.groupId)
          .set(group.toMap());
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  static Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();

      if (doc.exists) {
        return GroupModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  static Future<List<GroupModel>> getAllGroups() async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all groups: $e');
    }
  }

  static Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('isActive', isEqualTo: true)
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user groups: $e');
    }
  }

  static Future<List<GroupModel>> getAdminGroups(String adminId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('isActive', isEqualTo: true)
          .where('adminId', isEqualTo: adminId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admin groups: $e');
    }
  }

  static Future<void> updateGroup(GroupModel group) async {
    try {
      final updatedGroup = group.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('groups')
          .doc(group.groupId)
          .update(updatedGroup.toMap());
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  static Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add member to group: $e');
    }
  }

  static Future<void> removeMemberFromGroup(
    String groupId,
    String userId,
  ) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove member from group: $e');
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }
}
