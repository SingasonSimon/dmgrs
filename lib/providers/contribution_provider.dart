import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contribution_model.dart';
import '../models/allocation_model.dart';
import '../services/firestore_service.dart';
import '../services/mpesa_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ContributionProvider with ChangeNotifier {
  List<ContributionModel> _contributions = [];
  List<AllocationModel> _allocations = [];
  bool _isLoading = false;
  String? _error;
  double _lendingPoolBalance = 0.0;
  CycleModel? _currentCycle;

  // Getters
  List<ContributionModel> get contributions => _contributions;
  List<AllocationModel> get allocations => _allocations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get lendingPoolBalance => _lendingPoolBalance;
  CycleModel? get currentCycle => _currentCycle;

  // Get user contributions
  List<ContributionModel> getUserContributions(String userId) {
    return _contributions.where((c) => c.userId == userId).toList();
  }

  // Get user allocations
  List<AllocationModel> getUserAllocations(String userId) {
    return _allocations.where((a) => a.userId == userId).toList();
  }

  // Get pending contributions
  List<ContributionModel> get pendingContributions {
    return _contributions.where((c) => c.isPending).toList();
  }

  // Get overdue contributions
  List<ContributionModel> get overdueContributions {
    return _contributions.where((c) => c.isOverdue).toList();
  }

  // Get completed contributions
  List<ContributionModel> get completedContributions {
    return _contributions.where((c) => c.isCompleted).toList();
  }

  // Get total contributions this month
  double get totalContributionsThisMonth {
    final now = DateTime.now();
    return _contributions
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  // Get total lending pool amount
  double get totalLendingPoolAmount {
    return _contributions
        .where((c) => c.isCompleted)
        .fold(
          0.0,
          (sum, c) => sum + AppHelpers.calculateLendingPoolAmount(c.amount),
        );
  }

  // Get total member distribution amount
  double get totalMemberDistributionAmount {
    return _contributions
        .where((c) => c.isCompleted)
        .fold(
          0.0,
          (sum, c) =>
              sum + AppHelpers.calculateMemberDistributionAmount(c.amount),
        );
  }

  // Load all contributions
  Future<void> loadContributions() async {
    try {
      _setLoading(true);
      _clearError();

      _contributions = await FirestoreService.getAllContributions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load contributions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user contributions
  Future<void> loadUserContributions(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _contributions = await FirestoreService.getUserContributions(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user contributions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all allocations
  Future<void> loadAllocations() async {
    try {
      _setLoading(true);
      _clearError();

      _allocations = await FirestoreService.getAllAllocations();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load allocations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load current cycle
  Future<void> loadCurrentCycle() async {
    try {
      _setLoading(true);
      _clearError();

      _currentCycle = await FirestoreService.getCurrentCycle();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current cycle: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Start a new cycle
  Future<bool> startCycle({
    required List<String> memberUserIds,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? groupId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final cycle = CycleModel(
        cycleId: AppHelpers.generateRandomId(),
        startDate: startDate,
        endDate: endDate,
        members: memberUserIds,
        currentIndex: 0,
        isActive: true,
        notes: notes,
        metadata: groupId != null ? {'groupId': groupId} : null,
      );

      await FirestoreService.createCycle(cycle);
      _currentCycle = cycle;

      // Optionally generate allocations upfront (can be per-step as well)
      // await FirestoreService.generateCycleAllocations(cycle);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start cycle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Advance current cycle to next member
  Future<bool> advanceCycle() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentCycle == null) {
        throw Exception('No active cycle');
      }

      final cycle = _currentCycle!;
      if (cycle.currentIndex >= cycle.members.length) {
        // Already completed
        return false;
      }

      final updated = cycle.copyWith(currentIndex: cycle.currentIndex + 1);
      await FirestoreService.updateCycle(updated);
      _currentCycle = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to advance cycle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete the current cycle
  Future<bool> completeCycle() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentCycle == null) {
        throw Exception('No active cycle');
      }

      final completed = _currentCycle!.copyWith(
        isActive: false,
        completedDate: DateTime.now(),
      );
      await FirestoreService.updateCycle(completed);
      _currentCycle = completed;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete cycle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reload allocations for current cycle
  Future<void> reloadAllocationsForCurrentCycle() async {
    try {
      if (_currentCycle == null) return;
      final list = await FirestoreService.getAllocationsByCycle(
        _currentCycle!.cycleId,
      );
      _allocations = list;
      notifyListeners();
    } catch (_) {}
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

  // Create contribution
  Future<bool> createContribution({
    required String userId,
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate amount
      if (amount <= 0) {
        throw Exception('Contribution amount must be greater than zero.');
      }

      // Enforce one contribution per user per calendar month
      final now = DateTime.now();
      final alreadyContributed =
          await FirestoreService.hasUserContributionInMonth(
            userId: userId,
            year: now.year,
            month: now.month,
          );
      if (alreadyContributed) {
        throw Exception('You have already contributed this month.');
      }

      final contributionId = AppHelpers.generateRandomId();
      final dueDate = DateTime(now.year, now.month + 1, 1);

      final contribution = ContributionModel(
        contributionId: contributionId,
        userId: userId,
        amount: amount,
        date: now,
        status: AppConstants.paymentPending,
        dueDate: dueDate,
      );

      // Save contribution to Firestore with retry mechanism
      await FirestoreService.retryOperation(
        () => FirestoreService.createContribution(contribution),
      );

      // Initiate M-Pesa STK Push with retry mechanism
      final mpesaResponse = await FirestoreService.retryOperation(
        () => MpesaService.simulateSTKPush(
          phoneNumber: phoneNumber,
          amount: amount,
          accountReference: 'CONTRIBUTION_$contributionId',
        ),
      );

      if (mpesaResponse != null && mpesaResponse['ResponseCode'] == '0') {
        // Update contribution with M-Pesa reference
        final updatedContribution = contribution.copyWith(
          mpesaRef: mpesaResponse['CheckoutRequestID'],
        );

        await FirestoreService.retryOperation(
          () => FirestoreService.updateContribution(updatedContribution),
        );

        // Add to local list
        _contributions.insert(0, updatedContribution);
        notifyListeners();

        return true;
      } else {
        throw Exception(
          'M-Pesa STK Push failed: ${mpesaResponse?['CustomerMessage'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Error creating contribution: $e');
      _setError('Failed to create contribution: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process contribution payment
  Future<bool> processContributionPayment({
    required String contributionId,
    required String mpesaRef,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Find contribution
      final contributionIndex = _contributions.indexWhere(
        (c) => c.contributionId == contributionId,
      );
      if (contributionIndex == -1) {
        throw Exception('Contribution not found');
      }

      final contribution = _contributions[contributionIndex];
      final now = DateTime.now();

      // Update contribution status
      final updatedContribution = contribution.copyWith(
        status: AppConstants.paymentCompleted,
        mpesaRef: mpesaRef,
        paidDate: now,
      );

      await FirestoreService.updateContribution(updatedContribution);

      // Update local list
      _contributions[contributionIndex] = updatedContribution;

      // Process fund allocation
      await _processFundAllocation(updatedContribution);

      // Create transaction record
      await FirestoreService.createTransaction({
        'type': 'contribution',
        'amount': amount,
        'userId': contribution.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'reference': mpesaRef,
        'description': 'Monthly contribution payment',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to process contribution payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process fund allocation
  Future<void> _processFundAllocation(ContributionModel contribution) async {
    try {
      print(
        'Processing fund allocation for contribution: ${contribution.amount}',
      );

      // Validate contribution
      if (contribution.amount <= 0) {
        throw Exception('Invalid contribution amount for allocation');
      }

      // Calculate amounts
      final lendingPoolAmount = AppHelpers.calculateLendingPoolAmount(
        contribution.amount,
      );
      final memberDistributionAmount =
          AppHelpers.calculateMemberDistributionAmount(contribution.amount);

      print('Lending pool amount: $lendingPoolAmount');
      print('Member distribution amount: $memberDistributionAmount');

      // Update lending pool with retry mechanism
      await FirestoreService.retryOperation(
        () => _updateLendingPool(lendingPoolAmount),
      );

      // Check if cycle exists, if not create one
      if (_currentCycle == null) {
        print('No active cycle found, creating new cycle...');
        await _createNewCycle();
        // Load the newly created cycle
        await loadCurrentCycle();
      }

      // Allocate to member if cycle is active
      if (_currentCycle != null && _currentCycle!.isActiveCycle) {
        print('Allocating to member: ${_currentCycle!.nextMember}');
        await FirestoreService.retryOperation(
          () => _allocateToMember(memberDistributionAmount),
        );
      } else {
        print('No active cycle or cycle is not active');
      }
    } catch (e) {
      print('Error in fund allocation: $e');
      _setError('Failed to process fund allocation: $e');
      // Don't rethrow - allocation failure shouldn't fail the contribution
    }
  }

  // Update lending pool
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

  // Allocate to member
  Future<void> _allocateToMember(double amount) async {
    try {
      if (_currentCycle == null || _currentCycle!.allMembersAllocated) {
        return;
      }

      final nextMember = _currentCycle!.nextMember;
      if (nextMember == null) {
        return;
      }

      final allocationId = AppHelpers.generateRandomId();
      final now = DateTime.now();

      final allocation = AllocationModel(
        allocationId: allocationId,
        userId: nextMember,
        amount: amount,
        date: now,
        cycleId: _currentCycle!.cycleId,
        disbursed: false,
      );

      await FirestoreService.createAllocation(allocation);

      // Update cycle
      final updatedCycle = _currentCycle!.copyWith(
        currentIndex: _currentCycle!.currentIndex + 1,
      );
      await FirestoreService.updateCycle(updatedCycle);
      _currentCycle = updatedCycle;

      // Add to local list
      _allocations.insert(0, allocation);

      // Send notification
      await NotificationService.sendAllocationNotification(
        userId: nextMember,
        userName: 'Member', // You might want to get the actual name
        amount: amount,
      );

      notifyListeners();
    } catch (e) {
      _setError('Failed to allocate to member: $e');
    }
  }

  // Initialize or get current cycle
  Future<void> initializeCycle() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if there's an active cycle
      _currentCycle = await FirestoreService.getCurrentCycle();

      if (_currentCycle == null) {
        // Create a new cycle
        await _createNewCycle();
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize cycle: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new cycle
  Future<void> _createNewCycle() async {
    try {
      print('Creating new cycle...');

      // Get all active members (simplified query to avoid index requirement)
      final members = await FirestoreService.getAllUsers();
      final activeMembers = members
          .where(
            (m) => m.role == AppConstants.memberRole && m.status == 'active',
          )
          .toList();
      print('Found ${activeMembers.length} active members');

      if (activeMembers.isEmpty) {
        // If no members found, create a cycle with just the current user
        // We'll need to get the current user ID from the auth service
        final currentUserModel = await AuthService.getCurrentUserModel();
        if (currentUserModel == null) {
          throw Exception('No authenticated user found');
        }
        final currentUserId = currentUserModel.userId;
        print('No active members found, using current user: $currentUserId');

        final cycleId = AppHelpers.generateRandomId();
        final now = DateTime.now();
        final endDate = DateTime(now.year + 1, now.month, now.day);

        final newCycle = CycleModel(
          cycleId: cycleId,
          startDate: now,
          endDate: endDate,
          members: [currentUserId],
          currentIndex: 0,
          isActive: true,
        );

        await FirestoreService.createCycle(newCycle);
        _currentCycle = newCycle;
        print('Cycle created with current user only');
        return;
      }

      // Shuffle members for random order
      final shuffledMembers = List<String>.from(
        activeMembers.map((m) => m.userId),
      );
      shuffledMembers.shuffle();
      print('Shuffled members: $shuffledMembers');

      final cycleId = AppHelpers.generateRandomId();
      final now = DateTime.now();
      final endDate = DateTime(
        now.year + 1,
        now.month,
        now.day,
      ); // 1 year cycle

      final newCycle = CycleModel(
        cycleId: cycleId,
        startDate: now,
        endDate: endDate,
        members: shuffledMembers,
        currentIndex: 0,
        isActive: true,
      );

      await FirestoreService.createCycle(newCycle);
      _currentCycle = newCycle;
      print(
        'Cycle created successfully with ${shuffledMembers.length} members',
      );
    } catch (e) {
      print('Error creating cycle: $e');
      _setError('Failed to create new cycle: $e');
    }
  }

  // Complete current cycle and start new one
  Future<void> completeCurrentCycle() async {
    try {
      if (_currentCycle == null) return;

      // Mark current cycle as completed
      final completedCycle = _currentCycle!.copyWith(
        isActive: false,
        completedDate: DateTime.now(),
      );
      await FirestoreService.updateCycle(completedCycle);

      // Create new cycle
      await _createNewCycle();
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete cycle: $e');
    }
  }

  // Apply penalty for late payment
  Future<bool> applyPenalty({
    required String contributionId,
    required double penaltyAmount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final contributionIndex = _contributions.indexWhere(
        (c) => c.contributionId == contributionId,
      );
      if (contributionIndex == -1) {
        throw Exception('Contribution not found');
      }

      final contribution = _contributions[contributionIndex];
      final updatedContribution = contribution.copyWith(
        penaltyAmount: penaltyAmount,
        status: AppConstants.paymentOverdue,
      );

      await FirestoreService.updateContribution(updatedContribution);
      _contributions[contributionIndex] = updatedContribution;

      // Send penalty notification
      await NotificationService.sendPenaltyNotification(
        userId: contribution.userId,
        userName: 'Member', // You might want to get the actual name
        penaltyAmount: penaltyAmount,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to apply penalty: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Disburse allocation
  Future<bool> disburseAllocation({
    required String allocationId,
    required String disbursementMethod,
    String? mpesaRef,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final allocationIndex = _allocations.indexWhere(
        (a) => a.allocationId == allocationId,
      );
      if (allocationIndex == -1) {
        throw Exception('Allocation not found');
      }

      final allocation = _allocations[allocationIndex];
      final now = DateTime.now();

      final updatedAllocation = allocation.copyWith(
        disbursed: true,
        disbursementDate: now,
        disbursementMethod: disbursementMethod,
        mpesaRef: mpesaRef,
      );

      await FirestoreService.updateAllocation(updatedAllocation);
      _allocations[allocationIndex] = updatedAllocation;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to disburse allocation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get contribution statistics
  Map<String, dynamic> getContributionStats() {
    final now = DateTime.now();
    final thisMonth = _contributions
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .toList();

    final completedThisMonth = thisMonth.where((c) => c.isCompleted).length;
    final pendingThisMonth = thisMonth.where((c) => c.isPending).length;
    final overdueThisMonth = thisMonth.where((c) => c.isOverdue).length;

    return {
      'totalContributions': _contributions.length,
      'completedContributions': _contributions
          .where((c) => c.isCompleted)
          .length,
      'pendingContributions': _contributions.where((c) => c.isPending).length,
      'overdueContributions': _contributions.where((c) => c.isOverdue).length,
      'thisMonthTotal': thisMonth.length,
      'thisMonthCompleted': completedThisMonth,
      'thisMonthPending': pendingThisMonth,
      'thisMonthOverdue': overdueThisMonth,
      'totalAmount': _contributions.fold(0.0, (sum, c) => sum + c.amount),
      'lendingPoolBalance': _lendingPoolBalance,
    };
  }

  // Get member count
  Future<int> getMemberCount() async {
    try {
      // Get all active users (both members and admins)
      final allUsers = await FirestoreService.getAllUsers();
      final activeUsers = allUsers
          .where((user) => user.status == 'active')
          .toList();

      print('Found ${allUsers.length} total users');
      print('Found ${activeUsers.length} active users');

      for (final user in allUsers) {
        print(
          'User: ${user.name} (${user.userId}) - Role: ${user.role} - Status: ${user.status}',
        );
      }

      return activeUsers.length;
    } catch (e) {
      print('Error getting member count: $e');
      return 0;
    }
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

  // Disburse allocation by ID
  Future<void> disburseAllocationById(String allocationId) async {
    try {
      _setLoading(true);
      _clearError();

      final allocationIndex = _allocations.indexWhere(
        (a) => a.allocationId == allocationId,
      );
      if (allocationIndex == -1) {
        throw Exception('Allocation not found');
      }

      final allocation = _allocations[allocationIndex];
      final now = DateTime.now();

      final updatedAllocation = allocation.copyWith(
        disbursed: true,
        disbursementDate: now,
      );

      await FirestoreService.updateAllocation(updatedAllocation);
      _allocations[allocationIndex] = updatedAllocation;

      // Send disbursement notification
      await NotificationService.sendAllocationNotification(
        userId: allocation.userId,
        userName: 'Member',
        amount: allocation.amount,
      );

      notifyListeners();
    } catch (e) {
      _setError('Failed to disburse allocation: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Complete current cycle manually
  Future<void> completeCurrentCycleManually() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentCycle == null) {
        throw Exception('No active cycle found');
      }

      final now = DateTime.now();
      final updatedCycle = _currentCycle!.copyWith(
        isActive: false,
        completedDate: now,
      );

      await FirestoreService.updateCycle(updatedCycle);
      _currentCycle = updatedCycle;

      // Send cycle completion notification to all members
      for (final memberId in _currentCycle!.members) {
        await NotificationService.sendAllocationNotification(
          userId: memberId,
          userName: 'Member',
          amount: 0, // Cycle completion notification
        );
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to complete cycle: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check payment status for pending contributions
  Future<void> checkPaymentStatus() async {
    try {
      _setLoading(true);
      _clearError();

      final pendingContributions = _contributions
          .where((c) => c.isPending)
          .toList();

      for (final contribution in pendingContributions) {
        if (contribution.mpesaRef != null) {
          // Simulate checking payment status
          // In a real implementation, you would call M-Pesa API to check status
          final statusResponse = await MpesaService.simulateSTKPushQuery(
            checkoutRequestId: contribution.mpesaRef!,
          );

          if (statusResponse != null && statusResponse['ResultCode'] == '0') {
            // Payment successful
            await processContributionPayment(
              contributionId: contribution.contributionId,
              mpesaRef: contribution.mpesaRef!,
              amount: contribution.amount,
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to check payment status: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Simulate payment completion (for testing)
  Future<void> simulatePaymentCompletion(String contributionId) async {
    try {
      final contributionIndex = _contributions.indexWhere(
        (c) => c.contributionId == contributionId,
      );

      if (contributionIndex != -1) {
        final contribution = _contributions[contributionIndex];
        await processContributionPayment(
          contributionId: contributionId,
          mpesaRef:
              contribution.mpesaRef ??
              'SIMULATED_${DateTime.now().millisecondsSinceEpoch}',
          amount: contribution.amount,
        );
      }
    } catch (e) {
      _setError('Failed to simulate payment completion: $e');
    }
  }
}
