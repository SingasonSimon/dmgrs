import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../models/loan_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import 'loan_repayment_screen.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      loanProvider.loadUserLoans(authProvider.userId);
      loanProvider.loadLendingPoolBalance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showRequestLoanDialog,
          ),
        ],
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, child) {
          if (loanProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userLoans = loanProvider.getUserLoans(
            Provider.of<AuthProvider>(context, listen: false).userId,
          );

          if (userLoans.isEmpty) {
            return _buildEmptyState(context, loanProvider);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: userLoans.length,
              itemBuilder: (context, index) {
                final loan = userLoans[index];
                return _buildLoanCard(context, loan);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LoanProvider loanProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No Loan Requests',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t requested any loans yet. Available pool: ${AppHelpers.formatCurrency(loanProvider.lendingPoolBalance)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showRequestLoanDialog,
            icon: const Icon(Icons.add),
            label: const Text('Request Loan'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, loan) {
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
              if (loan.approvalDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approved: ${AppHelpers.formatDate(loan.approvalDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (loan.isActive && loan.nextPaymentDue != null) ...[
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
              if (loan.isActive) ...[
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
              ],
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
              if (loan.isPending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelLoanRequest(loan),
                    child: const Text('Cancel Request'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLoanDetails(loan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoanRepaymentScreen(loan: loan)),
    );
  }

  void _showRequestLoanDialog() {
    showDialog(context: context, builder: (context) => _RequestLoanDialog());
  }

  void _cancelLoanRequest(LoanModel loan) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Cancel Loan Request',
      message:
          'Are you sure you want to cancel this loan request? This action cannot be undone.',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final loanProvider = Provider.of<LoanProvider>(
            context,
            listen: false,
          );
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await loanProvider.cancelLoan(loan.loanId, authProvider.userId);

          if (mounted) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Loan request cancelled successfully',
            );
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Failed to cancel loan request: ${e.toString()}',
            );
          }
        }
      }
    });
  }
}

class _RequestLoanDialog extends StatefulWidget {
  @override
  State<_RequestLoanDialog> createState() => _RequestLoanDialogState();
}

class _RequestLoanDialogState extends State<_RequestLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {}); // Rebuild to update repayment period text
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String _getRepaymentPeriodText(String amountText) {
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 5000) {
      return '3 months';
    } else if (amount <= 15000) {
      return '6 months';
    } else if (amount <= 50000) {
      return '12 months';
    } else {
      return '18 months';
    }
  }

  double _calculateInterestRate(double amount) {
    // Dynamic interest rates based on loan amount
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

  Future<void> _requestLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    final success = await loanProvider.createLoanRequest(
      userId: authProvider.userId,
      requestedAmount: double.parse(_amountController.text),
      purpose: _purposeController.text.trim(),
      interestRate: _calculateInterestRate(
        double.parse(_amountController.text),
      ),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      AppHelpers.showSuccessSnackBar(
        context,
        'Loan request submitted successfully!',
      );
    } else if (mounted) {
      AppHelpers.showErrorSnackBar(
        context,
        loanProvider.error ?? 'Failed to submit loan request',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        return AlertDialog(
          title: const Text('Request Loan'),
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Available Pool: ${AppHelpers.formatCurrency(loanProvider.lendingPoolBalance)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount (KSh)',
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid amount';
                    }
                    if (amount < 1000) {
                      return 'Minimum loan amount is KSh 1,000';
                    }
                    if (amount > loanProvider.lendingPoolBalance) {
                      return 'Amount cannot exceed available pool';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    hintText: 'Describe the purpose of this loan',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Purpose is required';
                    }
                    if (value.length < 10) {
                      return 'Please provide a detailed purpose (at least 10 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Terms:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Interest Rate: ${_calculateInterestRate(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(0)}% per annum',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '• Repayment Period: ${_getRepaymentPeriodText(_amountController.text)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '• Monthly installments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan Terms Guide:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• KSh 1,000-5,000: 3 months @ 8%',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                            Text(
                              '• KSh 5,001-15,000: 6 months @ 10%',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                            Text(
                              '• KSh 15,001-50,000: 12 months @ 12%',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                            Text(
                              '• KSh 50,001+: 18 months @ 15%',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              onPressed: _isLoading ? null : _requestLoan,
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }
}
