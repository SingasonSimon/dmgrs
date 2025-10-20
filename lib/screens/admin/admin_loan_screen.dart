import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/loan_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../member/loan_repayment_screen.dart';

class AdminLoanScreen extends StatefulWidget {
  const AdminLoanScreen({super.key});

  @override
  State<AdminLoanScreen> createState() => _AdminLoanScreenState();
}

class _AdminLoanScreenState extends State<AdminLoanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    loanProvider.loadLoans();
    loanProvider.loadLendingPoolBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Under Review', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            Tab(text: 'In Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Fully Repaid', icon: Icon(Icons.done_all)),
            Tab(text: 'Declined', icon: Icon(Icons.cancel_outlined)),
          ],
        ),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, child) {
          if (loanProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPendingLoansTab(loanProvider),
              _buildApprovedLoansTab(loanProvider),
              _buildActiveLoansTab(loanProvider),
              _buildCompletedLoansTab(loanProvider),
              _buildRejectedLoansTab(loanProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingLoansTab(LoanProvider loanProvider) {
    final pendingLoans = loanProvider.pendingLoans;

    if (pendingLoans.isEmpty) {
      return _buildEmptyState(
        context,
        'No Loans Under Review',
        'All loan requests have been processed.',
        Icons.check_circle_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: pendingLoans.length,
        itemBuilder: (context, index) {
          final loan = pendingLoans[index];
          return _buildPendingLoanCard(context, loan);
        },
      ),
    );
  }

  Widget _buildApprovedLoansTab(LoanProvider loanProvider) {
    final approvedLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanApproved)
        .toList();

    if (approvedLoans.isEmpty) {
      return _buildEmptyState(
        context,
        'No Approved Loans',
        'There are currently no approved loans waiting for disbursement.',
        Icons.check_circle_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: approvedLoans.length,
        itemBuilder: (context, index) {
          final loan = approvedLoans[index];
          return _buildApprovedLoanCard(context, loan);
        },
      ),
    );
  }

  Widget _buildActiveLoansTab(LoanProvider loanProvider) {
    final activeLoans = loanProvider.activeLoans;

    if (activeLoans.isEmpty) {
      return _buildEmptyState(
        context,
        'No Loans In Progress',
        'There are currently no loans in progress.',
        Icons.account_balance_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: activeLoans.length,
        itemBuilder: (context, index) {
          final loan = activeLoans[index];
          return _buildActiveLoanCard(context, loan);
        },
      ),
    );
  }

  Widget _buildCompletedLoansTab(LoanProvider loanProvider) {
    final completedLoans = loanProvider.completedLoans;

    if (completedLoans.isEmpty) {
      return _buildEmptyState(
        context,
        'No Fully Repaid Loans',
        'No loans have been fully repaid yet.',
        Icons.done_all_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: completedLoans.length,
        itemBuilder: (context, index) {
          final loan = completedLoans[index];
          return _buildCompletedLoanCard(context, loan);
        },
      ),
    );
  }

  Widget _buildRejectedLoansTab(LoanProvider loanProvider) {
    final rejectedLoans = loanProvider.rejectedLoans;

    if (rejectedLoans.isEmpty) {
      return _buildEmptyState(
        context,
        'No Rejected Loans',
        'No loan requests have been rejected.',
        Icons.cancel_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: rejectedLoans.length,
        itemBuilder: (context, index) {
          final loan = rejectedLoans[index];
          return _buildRejectedLoanCard(context, loan);
        },
      ),
    );
  }

  Widget _buildPendingLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.formatCurrency(loan.requestedAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: const Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(loan.purpose, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              FutureBuilder(
                future: _getUserInfo(loan.userId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;
                    return Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user['name']} (${user['phone']})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading user info...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Requested: ${AppHelpers.formatDate(loan.requestDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectLoan(loan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveLoan(loan),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.formatCurrency(loan.finalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Approved',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(loan.purpose, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              FutureBuilder(
                future: _getUserInfo(loan.userId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;
                    return Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user['name']} (${user['phone']})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading user info...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Approved: ${AppHelpers.formatDate(loan.approvalDate ?? loan.requestDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This loan is approved and ready for disbursement.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _disburseLoan(loan),
                  icon: const Icon(Icons.payment),
                  label: const Text('Disburse Loan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.formatCurrency(loan.finalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      AppHelpers.getLoanStatusDisplayText(loan.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppHelpers.getLoanStatusColor(
                      loan.status,
                    ).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: AppHelpers.getLoanStatusColor(loan.status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(loan.purpose, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining Balance:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    AppHelpers.formatCurrency(loan.remainingBalance),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interest Rate:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${loan.interestRate}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (loan.nextPaymentDue != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Next Payment: ${AppHelpers.formatCurrency(loan.nextPaymentDue!.amount)} due ${AppHelpers.formatDate(loan.nextPaymentDue!.dueDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.formatCurrency(loan.finalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(loan.purpose, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed: ${AppHelpers.formatDate(loan.completionDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.formatCurrency(loan.requestedAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: const Text(
                      'REJECTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(loan.purpose, style: Theme.of(context).textTheme.bodyLarge),
              if (loan.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${loan.rejectionReason}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _approveLoan(loan) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Approve Loan',
      message:
          'Are you sure you want to approve this loan request for ${AppHelpers.formatCurrency(loan.requestedAmount)}?',
    ).then((confirmed) {
      if (confirmed == true) {
        final loanProvider = Provider.of<LoanProvider>(context, listen: false);
        loanProvider
            .approveLoanSimple(loan.loanId)
            .then((_) {
              AppHelpers.showSuccessSnackBar(
                context,
                'Loan approved successfully!',
              );
              // Refresh the data to show updated loan status
              _loadData();
            })
            .catchError((error) {
              AppHelpers.showErrorSnackBar(
                context,
                'Failed to approve loan: $error',
              );
            });
      }
    });
  }

  void _disburseLoan(loan) {
    showDialog(
      context: context,
      builder: (context) =>
          _DisburseLoanDialog(loan: loan, onLoanDisbursed: _loadData),
    );
  }

  void _rejectLoan(loan) {
    showDialog(
      context: context,
      builder: (context) =>
          _RejectLoanDialog(loan: loan, onLoanRejected: _loadData),
    );
  }

  Future<Map<String, String>> _getUserInfo(String userId) async {
    try {
      final user = await FirestoreService.getUser(userId);
      return {'name': user?.name ?? 'Unknown', 'phone': user?.phone ?? 'N/A'};
    } catch (e) {
      return {'name': 'Unknown', 'phone': 'N/A'};
    }
  }

  void _navigateToLoanDetails(loan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoanRepaymentScreen(loan: loan)),
    );
  }
}

class _DisburseLoanDialog extends StatefulWidget {
  final loan;
  final VoidCallback onLoanDisbursed;

  const _DisburseLoanDialog({
    required this.loan,
    required this.onLoanDisbursed,
  });

  @override
  State<_DisburseLoanDialog> createState() => _DisburseLoanDialogState();
}

class _DisburseLoanDialogState extends State<_DisburseLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mpesaRefController = TextEditingController();
  String _disbursementMethod = 'mpesa';
  bool _isLoading = false;

  @override
  void dispose() {
    _mpesaRefController.dispose();
    super.dispose();
  }

  void _disburseLoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);

      // Show loading dialog
      AppHelpers.showLoadingDialog(
        context,
        message: 'Processing disbursement...',
      );

      final success = await loanProvider.disburseLoan(
        loanId: widget.loan.loanId,
        disbursementMethod: _disbursementMethod,
        mpesaRef: _mpesaRefController.text.trim().isEmpty
            ? null
            : _mpesaRefController.text.trim(),
      );

      // Hide loading dialog
      if (mounted) {
        AppHelpers.hideLoadingDialog(context);
      }

      if (mounted) {
        if (success) {
          AppHelpers.showSuccessSnackBar(
            context,
            'Loan disbursed successfully!',
          );
          Navigator.pop(context);
          widget.onLoanDisbursed();
        } else {
          final errorMessage = AppHelpers.getErrorMessage(
            loanProvider.error ?? "Unknown error",
          );
          AppHelpers.showErrorSnackBar(
            context,
            'Failed to disburse loan: $errorMessage',
          );
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) {
        try {
          AppHelpers.hideLoadingDialog(context);
        } catch (_) {
          // Dialog might already be closed
        }

        final errorMessage = AppHelpers.getErrorMessage(e);
        AppHelpers.showErrorSnackBar(
          context,
          'Failed to disburse loan: $errorMessage',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Disburse Loan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${AppHelpers.formatCurrency(widget.loan.finalAmount)}',
                  ),
                  Text('Purpose: ${widget.loan.purpose}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Disbursement Method',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _disbursementMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
              ],
              onChanged: (value) {
                setState(() {
                  _disbursementMethod = value!;
                });
              },
            ),
            if (_disbursementMethod == 'mpesa') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _mpesaRefController,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Reference (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter M-Pesa transaction reference',
                ),
                validator: (value) {
                  if (_disbursementMethod == 'mpesa' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'M-Pesa reference is required for M-Pesa disbursements';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _disburseLoan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Disburse Loan'),
        ),
      ],
    );
  }
}

class _RejectLoanDialog extends StatefulWidget {
  final loan;
  final VoidCallback onLoanRejected;

  const _RejectLoanDialog({required this.loan, required this.onLoanRejected});

  @override
  State<_RejectLoanDialog> createState() => _RejectLoanDialogState();
}

class _RejectLoanDialogState extends State<_RejectLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _rejectLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    final success = await loanProvider.rejectLoanSimple(
      widget.loan.loanId,
      _reasonController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      AppHelpers.showSuccessSnackBar(context, 'Loan rejected successfully!');
      // Refresh the data to show updated loan status
      widget.onLoanRejected();
    } else if (mounted) {
      AppHelpers.showErrorSnackBar(
        context,
        loanProvider.error ?? 'Failed to reject loan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Loan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${AppHelpers.formatCurrency(widget.loan.requestedAmount)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason for rejecting this loan',
                prefixIcon: Icon(Icons.cancel),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Rejection reason is required';
                }
                if (value.length < 10) {
                  return 'Please provide a detailed reason (at least 10 characters)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _rejectLoan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reject Loan'),
        ),
      ],
    );
  }
}
