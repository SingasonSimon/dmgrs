import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contribution_model.dart';
import '../models/penalty_model.dart';
import '../utils/constants.dart';

class PenaltyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check for overdue contributions and create penalties
  static Future<void> checkAndCreatePenalties() async {
    try {
      print('PenaltyService: Checking for overdue contributions...');

      final now = DateTime.now();
      final overdueDate = now.subtract(
        const Duration(days: 1),
      ); // 1 day grace period

      // Get all contributions that are overdue
      final overdueContributions = await _firestore
          .collection(AppConstants.contributionsCollection)
          .where('status', isEqualTo: AppConstants.contributionPending)
          .where('dueDate', isLessThan: Timestamp.fromDate(overdueDate))
          .get();

      print(
        'PenaltyService: Found ${overdueContributions.docs.length} overdue contributions',
      );

      for (final doc in overdueContributions.docs) {
        final contribution = ContributionModel.fromMap(doc.data());

        // Check if penalty already exists for this contribution
        final existingPenalty = await _firestore
            .collection(AppConstants.penaltiesCollection)
            .where('contributionId', isEqualTo: contribution.contributionId)
            .get();

        if (existingPenalty.docs.isEmpty) {
          // Create new penalty
          await _createPenalty(contribution);
        }
      }
    } catch (e) {
      print('PenaltyService: Error checking penalties - $e');
    }
  }

  // Create penalty for overdue contribution
  static Future<void> _createPenalty(ContributionModel contribution) async {
    try {
      final penaltyAmount = _calculatePenaltyAmount(contribution.amount);
      final penalty = PenaltyModel(
        penaltyId: _firestore
            .collection(AppConstants.penaltiesCollection)
            .doc()
            .id,
        userId: contribution.userId,
        contributionId: contribution.contributionId,
        amount: penaltyAmount,
        reason: 'Late contribution payment',
        status: AppConstants.penaltyPending,
        dueDate: DateTime.now().add(
          const Duration(days: 7),
        ), // 7 days to pay penalty
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.penaltiesCollection)
          .doc(penalty.penaltyId)
          .set(penalty.toMap());

      print(
        'PenaltyService: Created penalty ${penalty.penaltyId} for user ${contribution.userId}',
      );
    } catch (e) {
      print('PenaltyService: Error creating penalty - $e');
    }
  }

  // Calculate penalty amount (5% of contribution amount)
  static double _calculatePenaltyAmount(double contributionAmount) {
    return contributionAmount * 0.05; // 5% penalty
  }

  // Get user penalties
  static Future<List<PenaltyModel>> getUserPenalties(String userId) async {
    try {
      final penalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return penalties.docs
          .map((doc) => PenaltyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('PenaltyService: Error getting user penalties - $e');
      return [];
    }
  }

  // Get all pending penalties
  static Future<List<PenaltyModel>> getPendingPenalties() async {
    try {
      final penalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('status', isEqualTo: AppConstants.penaltyPending)
          .orderBy('createdAt', descending: true)
          .get();

      return penalties.docs
          .map((doc) => PenaltyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('PenaltyService: Error getting pending penalties - $e');
      return [];
    }
  }

  // Mark penalty as paid
  static Future<bool> markPenaltyAsPaid(String penaltyId) async {
    try {
      await _firestore
          .collection(AppConstants.penaltiesCollection)
          .doc(penaltyId)
          .update({
            'status': AppConstants.penaltyPaid,
            'paidAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('PenaltyService: Marked penalty $penaltyId as paid');
      return true;
    } catch (e) {
      print('PenaltyService: Error marking penalty as paid - $e');
      return false;
    }
  }

  // Mark penalty as waived
  static Future<bool> waivePenalty(String penaltyId, String reason) async {
    try {
      await _firestore
          .collection(AppConstants.penaltiesCollection)
          .doc(penaltyId)
          .update({
            'status': AppConstants.penaltyWaived,
            'waivedAt': FieldValue.serverTimestamp(),
            'waivedReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('PenaltyService: Waived penalty $penaltyId - $reason');
      return true;
    } catch (e) {
      print('PenaltyService: Error waiving penalty - $e');
      return false;
    }
  }

  // Get penalty statistics
  static Future<Map<String, dynamic>> getPenaltyStats() async {
    try {
      final totalPenalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .get();

      final pendingPenalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('status', isEqualTo: AppConstants.penaltyPending)
          .get();

      final paidPenalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('status', isEqualTo: AppConstants.penaltyPaid)
          .get();

      final waivedPenalties = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('status', isEqualTo: AppConstants.penaltyWaived)
          .get();

      double totalPenaltyAmount = 0;
      double pendingPenaltyAmount = 0;
      double paidPenaltyAmount = 0;

      for (final doc in totalPenalties.docs) {
        final penalty = PenaltyModel.fromMap(doc.data());
        totalPenaltyAmount += penalty.amount;
      }

      for (final doc in pendingPenalties.docs) {
        final penalty = PenaltyModel.fromMap(doc.data());
        pendingPenaltyAmount += penalty.amount;
      }

      for (final doc in paidPenalties.docs) {
        final penalty = PenaltyModel.fromMap(doc.data());
        paidPenaltyAmount += penalty.amount;
      }

      return {
        'totalPenalties': totalPenalties.docs.length,
        'pendingPenalties': pendingPenalties.docs.length,
        'paidPenalties': paidPenalties.docs.length,
        'waivedPenalties': waivedPenalties.docs.length,
        'totalPenaltyAmount': totalPenaltyAmount,
        'pendingPenaltyAmount': pendingPenaltyAmount,
        'paidPenaltyAmount': paidPenaltyAmount,
      };
    } catch (e) {
      print('PenaltyService: Error getting penalty stats - $e');
      return {};
    }
  }

  // Schedule automatic penalty checking (call this periodically)
  static void schedulePenaltyChecking() {
    // This would typically be called from a background service
    // For now, we'll just call it manually when needed
    checkAndCreatePenalties();
  }
}
