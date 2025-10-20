import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/mpesa_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class LoanProvider with ChangeNotifier {
  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _error;
  double _lendingPoolBalance = 0.0;

  // Getters
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get lendingPoolBalance => _lendingPoolBalance;

  // Get user loans
  List<LoanModel> getUserLoans(String userId) {
    return _loans.where((l) => l.userId == userId).toList();
  }

  // Get pending loans
  List<LoanModel> get pendingLoans {
    return _loans.where((l) => l.isPending).toList();
  }

  // Get approved loans
  List<LoanModel> get approvedLoans {
    return _loans.where((l) => l.isApproved).toList();
  }

  // Get active loans
  List<LoanModel> get activeLoans {
    return _loans.where((l) => l.isActive).toList();
  }

  // Get completed loans
  List<LoanModel> get completedLoans {
    return _loans.where((l) => l.isCompleted).toList();
  }

  // Get rejected loans
  List<LoanModel> get rejectedLoans {
    return _loans.where((l) => l.isRejected).toList();
  }

  // Get total outstanding loans
  double get totalOutstandingLoans {
    return _loans
        .where((l) => l.isActive)
        .fold(0.0, (sum, l) => sum + l.remainingBalance);
  }

  // Get total loans this month
  double get totalLoansThisMonth {
    final now = DateTime.now();
    return _loans
        .where(
          (l) =>
              l.requestDate.year == now.year &&
              l.requestDate.month == now.month,
        )
        .fold(0.0, (sum, l) => sum + l.finalAmount);
  }

  // Load all loans
  Future<void> loadLoans() async {
    try {
      _setLoading(true);
      _clearError();

      _loans = await FirestoreService.getAllLoans();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load loans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user loans
  Future<void> loadUserLoans(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _loans = await FirestoreService.getUserLoans(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user loans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load pending loans
  Future<void> loadPendingLoans() async {
    try {
      _setLoading(true);
      _clearError();

      _loans = await FirestoreService.getPendingLoans();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load pending loans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load lending pool balance
  Future<void> loadLendingPoolBalance() async {
    try {
      _setLoading(true);
      _clearError();

      final poolData = await FirestoreService.getLendingPool();
      if (poolData != null) {
        _lendingPoolBalance = (poolData['totalAmount'] ?? 0.0).toDouble();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load lending pool balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create loan request
  Future<bool> createLoanRequest({
    required String userId,
    required double requestedAmount,
    required String purpose,
    required double interestRate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate loan amount
      if (requestedAmount > _lendingPoolBalance) {
        _setError('Loan amount cannot exceed available pool amount');
        return false;
      }

      if (requestedAmount < 1000) {
        _setError('Minimum loan amount is KSh 1,000');
        return false;
      }

      final loanId = AppHelpers.generateRandomId();
      final now = DateTime.now();

      final loan = LoanModel(
        loanId: loanId,
        userId: userId,
        requestedAmount: requestedAmount,
        purpose: purpose,
        status: AppConstants.loanPending,
        interestRate: interestRate,
        requestDate: now,
      );

      await FirestoreService.createLoan(loan);

      // Add to local list
      _loans.insert(0, loan);

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'loan_request',
        'amount': requestedAmount,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': loanId,
        'description': 'Loan request: $purpose',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create loan request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve loan
  Future<bool> approveLoan({
    required String loanId,
    required String approvedBy,
    double? approvedAmount,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final loanIndex = _loans.indexWhere((l) => l.loanId == loanId);
      if (loanIndex == -1) {
        throw Exception('Loan not found');
      }

      final loan = _loans[loanIndex];
      final now = DateTime.now();
      final finalAmount = approvedAmount ?? loan.requestedAmount;

      // Check if lending pool has enough funds
      if (finalAmount > _lendingPoolBalance) {
        _setError('Insufficient funds in lending pool');
        return false;
      }

      // Create repayment schedule with smart period based on amount
      final repaymentPeriod = _calculateRepaymentPeriod(finalAmount);
      final repaymentSchedule = _createRepaymentSchedule(
        finalAmount,
        loan.interestRate,
        now,
        repaymentPeriod,
      );

      final updatedLoan = loan.copyWith(
        status: AppConstants.loanApproved, // Keep as approved until disbursed
        approvedAmount: finalAmount,
        approvalDate: now,
        approvedBy: approvedBy,
        notes: notes,
        repaymentSchedule: repaymentSchedule,
        dueDate: now.add(Duration(days: repaymentPeriod * 30)), // Dynamic term
      );

      await FirestoreService.updateLoan(updatedLoan);
      _loans[loanIndex] = updatedLoan;

      // Update lending pool balance
      await _updateLendingPool(-finalAmount);

      // Send approval notification
      await NotificationService.sendLoanStatusNotification(
        userId: loan.userId,
        userName: 'Member', // You might want to get the actual name
        status: AppConstants.loanApproved,
        amount: finalAmount,
      );

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'loan_approval',
        'amount': finalAmount,
        'userId': loan.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': loanId,
        'description': 'Loan approved: ${loan.purpose}',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to approve loan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject loan
  Future<bool> rejectLoan({
    required String loanId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final loanIndex = _loans.indexWhere((l) => l.loanId == loanId);
      if (loanIndex == -1) {
        throw Exception('Loan not found');
      }

      final loan = _loans[loanIndex];
      final now = DateTime.now();

      final updatedLoan = loan.copyWith(
        status: AppConstants.loanRejected,
        approvalDate: now,
        approvedBy: rejectedBy,
        rejectionReason: rejectionReason,
      );

      await FirestoreService.updateLoan(updatedLoan);
      _loans[loanIndex] = updatedLoan;

      // Send rejection notification
      await NotificationService.sendLoanStatusNotification(
        userId: loan.userId,
        userName: 'Member', // You might want to get the actual name
        status: AppConstants.loanRejected,
        amount: loan.requestedAmount,
        reason: rejectionReason,
      );

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'loan_rejection',
        'amount': 0,
        'userId': loan.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': loanId,
        'description': 'Loan rejected: $rejectionReason',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reject loan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Disburse loan
  Future<bool> disburseLoan({
    required String loanId,
    required String disbursementMethod,
    String? mpesaRef,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final loanIndex = _loans.indexWhere((l) => l.loanId == loanId);
      if (loanIndex == -1) {
        throw Exception('Loan not found');
      }

      final loan = _loans[loanIndex];

      // Only disburse approved loans
      if (!loan.isApproved) {
        _setError('Only approved loans can be disbursed');
        return false;
      }

      final now = DateTime.now();

      final updatedLoan = loan.copyWith(
        status: AppConstants.loanActive, // Change from approved to active
        disbursementDate: now,
      );

      await FirestoreService.updateLoan(updatedLoan);
      _loans[loanIndex] = updatedLoan;

      // Send disbursement notification
      await NotificationService.sendLoanStatusNotification(
        userId: loan.userId,
        userName: 'Member',
        status: AppConstants.loanActive,
        amount: loan.finalAmount,
      );

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'loan_disbursement',
        'amount': loan.finalAmount,
        'userId': loan.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': mpesaRef ?? loanId,
        'description': 'Loan disbursed: ${loan.purpose}',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to disburse loan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Record loan repayment
  Future<bool> recordLoanRepayment({
    required String loanId,
    required String paymentId,
    required double amount,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final loanIndex = _loans.indexWhere((l) => l.loanId == loanId);
      if (loanIndex == -1) {
        throw Exception('Loan not found');
      }

      final loan = _loans[loanIndex];
      final now = DateTime.now();

      // Update repayment schedule
      final updatedSchedule = loan.repaymentSchedule.map((payment) {
        if (payment.paymentId == paymentId) {
          return payment.copyWith(isPaid: true, paidDate: now, notes: notes);
        }
        return payment;
      }).toList();

      // Check if loan is completed
      final isCompleted = updatedSchedule.every((payment) => payment.isPaid);
      final newStatus = isCompleted
          ? AppConstants.loanCompleted
          : AppConstants.loanActive;

      final updatedLoan = loan.copyWith(
        status: newStatus,
        repaymentSchedule: updatedSchedule,
      );

      await FirestoreService.updateLoan(updatedLoan);
      _loans[loanIndex] = updatedLoan;

      // Update lending pool balance
      await _updateLendingPool(amount);

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'loan_repayment',
        'amount': amount,
        'userId': loan.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': paymentId,
        'description': 'Loan repayment',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to record loan repayment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate smart repayment period based on loan amount
  int _calculateRepaymentPeriod(double amount) {
    if (amount <= 5000) {
      return 3; // 3 months for small loans (KSh 1,000-5,000)
    } else if (amount <= 15000) {
      return 6; // 6 months for medium loans (KSh 5,001-15,000)
    } else if (amount <= 50000) {
      return 12; // 12 months for large loans (KSh 15,001-50,000)
    } else {
      return 18; // 18 months for very large loans (KSh 50,001+)
    }
  }

  // Create repayment schedule with dynamic period
  List<RepaymentSchedule> _createRepaymentSchedule(
    double amount,
    double interestRate,
    DateTime startDate,
    int repaymentPeriodMonths,
  ) {
    final List<RepaymentSchedule> schedule = [];
    final double totalAmount = amount + (amount * interestRate / 100);
    final int numberOfPayments = repaymentPeriodMonths;
    final double monthlyPayment = totalAmount / numberOfPayments;

    for (int i = 0; i < numberOfPayments; i++) {
      final paymentDate = DateTime(
        startDate.year,
        startDate.month + i + 1,
        startDate.day,
      );

      schedule.add(
        RepaymentSchedule(
          paymentId: AppHelpers.generateRandomId(),
          amount: monthlyPayment,
          dueDate: paymentDate,
        ),
      );
    }

    return schedule;
  }

  // Migrate existing loans to new smart repayment logic
  Future<void> migrateExistingLoans() async {
    try {
      _setLoading(true);
      _clearError();

      print('Starting loan migration...');

      // Get all loans
      final allLoans = await FirestoreService.getAllLoans();
      int migratedCount = 0;

      for (final loan in allLoans) {
        // Only migrate loans that are active or approved but don't have proper repayment schedule
        if ((loan.status == AppConstants.loanActive ||
                loan.status == AppConstants.loanApproved) &&
            (loan.repaymentSchedule.isEmpty ||
                loan.repaymentSchedule.length == 12)) {
          final finalAmount = loan.approvedAmount ?? loan.requestedAmount;
          final newRepaymentPeriod = _calculateRepaymentPeriod(finalAmount);
          final newInterestRate = _calculateInterestRate(finalAmount);

          // Only migrate if the repayment period would be different
          if (loan.repaymentSchedule.length != newRepaymentPeriod ||
              loan.interestRate != newInterestRate) {
            print(
              'Migrating loan ${loan.loanId}: ${loan.repaymentSchedule.length} months -> $newRepaymentPeriod months, ${loan.interestRate}% -> $newInterestRate%',
            );

            // Create new repayment schedule
            final newRepaymentSchedule = _createRepaymentSchedule(
              finalAmount,
              newInterestRate,
              loan.approvalDate ?? loan.requestDate,
              newRepaymentPeriod,
            );

            // Update the loan
            final updatedLoan = loan.copyWith(
              interestRate: newInterestRate,
              repaymentSchedule: newRepaymentSchedule,
              dueDate: (loan.approvalDate ?? loan.requestDate).add(
                Duration(days: newRepaymentPeriod * 30),
              ),
            );

            await FirestoreService.updateLoan(updatedLoan);
            migratedCount++;
          }
        }
      }

      print('Migration completed. Migrated $migratedCount loans.');

      // Reload loans to reflect changes
      await loadLoans();

      notifyListeners();
    } catch (e) {
      print('Migration error: $e');
      _setError('Failed to migrate existing loans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Calculate smart interest rate based on loan amount (same logic as in loan screen)
  double _calculateInterestRate(double amount) {
    if (amount <= 5000) {
      return 8.0; // 8% for small loans (3 months)
    } else if (amount <= 15000) {
      return 10.0; // 10% for medium loans (6 months)
    } else if (amount <= 50000) {
      return 12.0; // 12% for large loans (12 months)
    } else {
      return 15.0; // 15% for very large loans (18 months)
    }
  }

  // Update lending pool balance
  Future<void> _updateLendingPool(double amount) async {
    try {
      final newBalance = _lendingPoolBalance + amount;
      await FirestoreService.updateLendingPool({
        'totalAmount': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _lendingPoolBalance = newBalance;
    } catch (e) {
      _setError('Failed to update lending pool: $e');
    }
  }

  // Get loan statistics
  Map<String, dynamic> getLoanStats() {
    final now = DateTime.now();
    final thisMonth = _loans
        .where(
          (l) =>
              l.requestDate.year == now.year &&
              l.requestDate.month == now.month,
        )
        .toList();

    final pendingCount = _loans.where((l) => l.isPending).length;
    final approvedCount = _loans.where((l) => l.isApproved).length;
    final activeCount = _loans.where((l) => l.isActive).length;
    final completedCount = _loans.where((l) => l.isCompleted).length;
    final rejectedCount = _loans.where((l) => l.isRejected).length;

    return {
      'totalLoans': _loans.length,
      'pendingLoans': pendingCount,
      'approvedLoans': approvedCount,
      'activeLoans': activeCount,
      'completedLoans': completedCount,
      'rejectedLoans': rejectedCount,
      'thisMonthLoans': thisMonth.length,
      'totalRequested': _loans.fold(0.0, (sum, l) => sum + l.requestedAmount),
      'totalApproved': _loans
          .where((l) => l.isApproved || l.isActive || l.isCompleted)
          .fold(0.0, (sum, l) => sum + l.finalAmount),
      'totalOutstanding': totalOutstandingLoans,
      'lendingPoolBalance': _lendingPoolBalance,
    };
  }

  // Get user loan statistics
  Map<String, dynamic> getUserLoanStats(String userId) {
    final userLoans = getUserLoans(userId);
    final pendingCount = userLoans.where((l) => l.isPending).length;
    final activeCount = userLoans.where((l) => l.isActive).length;
    final completedCount = userLoans.where((l) => l.isCompleted).length;
    final rejectedCount = userLoans.where((l) => l.isRejected).length;

    return {
      'totalLoans': userLoans.length,
      'pendingLoans': pendingCount,
      'activeLoans': activeCount,
      'completedLoans': completedCount,
      'rejectedLoans': rejectedCount,
      'totalRequested': userLoans.fold(
        0.0,
        (sum, l) => sum + l.requestedAmount,
      ),
      'totalApproved': userLoans
          .where((l) => l.isApproved || l.isActive || l.isCompleted)
          .fold(0.0, (sum, l) => sum + l.finalAmount),
      'totalOutstanding': userLoans
          .where((l) => l.isActive)
          .fold(0.0, (sum, l) => sum + l.remainingBalance),
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    _error = error;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    _error = null;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Simplified approve loan method (for admin use)
  Future<bool> approveLoanSimple(String loanId) async {
    return await approveLoan(
      loanId: loanId,
      approvedBy: 'admin', // TODO: Get actual admin user ID
      approvedAmount: null, // Use requested amount
      notes: 'Approved by admin',
    );
  }

  // Simplified reject loan method (for admin use)
  Future<bool> rejectLoanSimple(String loanId, String rejectionReason) async {
    return await rejectLoan(
      loanId: loanId,
      rejectedBy: 'admin', // TODO: Get actual admin user ID
      rejectionReason: rejectionReason,
    );
  }

  // Cancel loan request (for member use)
  Future<bool> cancelLoan(String loanId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Update loan status to cancelled
      await FirestoreService.updateLoanStatus(
        loanId,
        AppConstants.loanCancelled,
        notes: 'Cancelled by user',
      );

      // Reload user loans to reflect the change
      await loadUserLoans(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to cancel loan: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Process loan payment with M-Pesa
  Future<bool> processLoanPayment({
    required String loanId,
    required String paymentId,
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Initiate M-Pesa STK Push
      final mpesaResponse = await MpesaService.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: amount,
        accountReference: 'LOAN_PAYMENT_$paymentId',
        transactionDesc: 'Loan repayment payment',
      );

      if (mpesaResponse != null && mpesaResponse['ResponseCode'] == '0') {
        // Update loan payment with M-Pesa reference
        final success = await FirestoreService.updateLoanPayment(
          loanId: loanId,
          paymentId: paymentId,
          mpesaRef: mpesaResponse['CheckoutRequestID'],
          status: AppConstants.paymentPending,
        );

        if (success) {
          // Reload loans to reflect changes
          await loadLoans();
          notifyListeners();
          return true;
        } else {
          throw Exception('Failed to update loan payment');
        }
      } else {
        throw Exception('M-Pesa STK Push failed');
      }
    } catch (e) {
      _setError('Failed to process loan payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark a loan payment as completed (for admin use)
  Future<bool> markLoanPaymentCompleted({
    required String loanId,
    required String paymentId,
    String? mpesaRef,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await FirestoreService.markLoanPaymentCompleted(
        loanId: loanId,
        paymentId: paymentId,
        mpesaRef: mpesaRef,
      );

      if (success) {
        // Reload loans to reflect changes
        await loadLoans();
        notifyListeners();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to mark payment as completed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
