import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_card.dart';
import '../../providers/loan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mpesa_service.dart';

class LoanRepaymentScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanRepaymentScreen({super.key, required this.loan});

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Repayment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLoanDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Summary Card
            _buildLoanSummaryCard(),

            const SizedBox(height: 24),

            // Repayment Schedule
            _buildRepaymentSchedule(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSummaryCard() {
    final loan = widget.loan;
    final totalPaid = loan.repaymentSchedule
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
    final remainingAmount =
        (loan.approvedAmount ?? loan.requestedAmount) - totalPaid;
    final nextPayment =
        loan.repaymentSchedule.where((payment) => !payment.isPaid).isNotEmpty
        ? loan.repaymentSchedule.where((payment) => !payment.isPaid).first
        : null;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppHelpers.getLoanStatusColor(
                      loan.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppHelpers.getLoanStatusColor(loan.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.purpose,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

            const SizedBox(height: 24),

            // Loan Details
            _buildDetailRow(
              'Loan Amount',
              AppHelpers.formatCurrency(
                loan.approvedAmount ?? loan.requestedAmount,
              ),
            ),
            _buildDetailRow('Interest Rate', '${loan.interestRate}% per annum'),
            _buildDetailRow('Total Paid', AppHelpers.formatCurrency(totalPaid)),
            _buildDetailRow(
              'Remaining',
              AppHelpers.formatCurrency(remainingAmount),
            ),

            if (nextPayment != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Payment Due',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppHelpers.formatCurrency(nextPayment.amount),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text(
                            AppHelpers.formatDate(nextPayment.dueDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentSchedule() {
    final loan = widget.loan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repayment Schedule',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (loan.repaymentSchedule.isEmpty)
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Repayment Schedule',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Repayment schedule will be generated when your loan is approved.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...loan.repaymentSchedule.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            return _buildPaymentCard(payment, index + 1);
          }),
      ],
    );
  }

  Widget _buildPaymentCard(RepaymentSchedule payment, int installmentNumber) {
    final isOverdue =
        !payment.isPaid && payment.dueDate.isBefore(DateTime.now());

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: payment.isPaid ? null : () => _makePayment(payment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: payment.isPaid
                      ? Colors.green.withOpacity(0.1)
                      : isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  payment.isPaid
                      ? Icons.check_circle
                      : isOverdue
                      ? Icons.warning
                      : Icons.schedule,
                  color: payment.isPaid
                      ? Colors.green
                      : isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installment $installmentNumber',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.formatCurrency(payment.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: payment.isPaid
                            ? Colors.green
                            : isOverdue
                            ? Colors.red
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.isPaid
                          ? 'Paid on ${AppHelpers.formatDate(payment.paidDate!)}'
                          : 'Due ${AppHelpers.formatDate(payment.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: payment.isPaid
                            ? Colors.green
                            : isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!payment.isPaid) ...[
                // Admin mark as paid button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final isAdmin = authProvider.currentUser?.role == AppConstants.adminRole;
                    if (isAdmin) {
                      return IconButton(
                        onPressed: () => _markPaymentAsPaid(payment),
                        icon: const Icon(Icons.check_circle),
                        color: Colors.green,
                        tooltip: 'Mark as Paid (Admin)',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Regular payment button
                IconButton(
                  onPressed: () => _makePayment(payment),
                  icon: const Icon(Icons.payment),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final loan = widget.loan;
    final hasUnpaidPayments = loan.repaymentSchedule.any(
      (payment) => !payment.isPaid,
    );

    if (!hasUnpaidPayments) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makeNextPayment(),
                icon: const Icon(Icons.payment),
                label: const Text('Pay Next Installment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewPaymentHistory(),
                icon: const Icon(Icons.history),
                label: const Text('Payment History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLoanDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loan Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Loan ID', widget.loan.loanId),
            _buildDetailRow(
              'Request Date',
              AppHelpers.formatDate(widget.loan.requestDate),
            ),
            if (widget.loan.approvalDate != null)
              _buildDetailRow(
                'Approval Date',
                AppHelpers.formatDate(widget.loan.approvalDate!),
              ),
            if (widget.loan.dueDate != null)
              _buildDetailRow(
                'Final Due Date',
                AppHelpers.formatDate(widget.loan.dueDate!),
              ),
            _buildDetailRow('Interest Rate', '${widget.loan.interestRate}%'),
            if (widget.loan.notes != null) ...[
              const SizedBox(height: 16),
              Text(
                'Notes:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.loan.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _makePayment(RepaymentSchedule payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment Amount: ${AppHelpers.formatCurrency(payment.amount)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Due Date: ${AppHelpers.formatDate(payment.dueDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'This will initiate an M-Pesa payment request. You will receive an STK Push notification.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(payment);
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _makeNextPayment() {
    final nextPayment =
        widget.loan.repaymentSchedule
            .where((payment) => !payment.isPaid)
            .isNotEmpty
        ? widget.loan.repaymentSchedule
              .where((payment) => !payment.isPaid)
              .first
        : null;

    if (nextPayment != null) {
      _makePayment(nextPayment);
    }
  }

  void _viewPaymentHistory() {
    // TODO: Implement payment history screen
    AppHelpers.showSnackBar(context, 'Payment history feature coming soon!');
  }

  void _markPaymentAsPaid(RepaymentSchedule payment) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Mark Payment as Paid',
      message: 'Are you sure you want to mark this payment of ${AppHelpers.formatCurrency(payment.amount)} as paid?',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final loanProvider = Provider.of<LoanProvider>(context, listen: false);
          final success = await loanProvider.markLoanPaymentCompleted(
            loanId: widget.loan.loanId,
            paymentId: payment.paymentId,
          );

          if (mounted) {
            if (success) {
              AppHelpers.showSuccessSnackBar(
                context,
                'Payment marked as completed successfully!',
              );
              setState(() {}); // Refresh the UI
            } else {
              AppHelpers.showErrorSnackBar(
                context,
                'Failed to mark payment as completed: ${loanProvider.error ?? "Unknown error"}',
              );
            }
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Error marking payment as completed: ${e.toString()}',
            );
          }
        }
      }
    });
  }

  void _processPayment(RepaymentSchedule payment) {
    showDialog(
      context: context,
      builder: (context) => _PaymentDialog(
        payment: payment,
        loan: widget.loan,
        onPaymentSuccess: () {
          // Refresh the loan data
          setState(() {});
        },
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final RepaymentSchedule payment;
  final loan;
  final VoidCallback onPaymentSuccess;

  const _PaymentDialog({
    required this.payment,
    required this.loan,
    required this.onPaymentSuccess,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${AppHelpers.formatCurrency(widget.payment.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Due Date: ${AppHelpers.formatDate(widget.payment.dueDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'M-Pesa Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '07XX XXX XXX',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!MpesaService.isValidPhoneNumber(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive an M-Pesa prompt on your phone to complete the payment.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
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
          onPressed: _isLoading ? null : _processPayment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pay Now'),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);

      // Process loan payment
      final success = await loanProvider.processLoanPayment(
        loanId: widget.loan.loanId,
        paymentId: widget.payment.paymentId,
        amount: widget.payment.amount,
        phoneNumber: _phoneController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
        AppHelpers.showSnackBar(
          context,
          'Payment initiated! Check your phone for M-Pesa prompt.',
        );
        widget.onPaymentSuccess();
      } else if (mounted) {
        AppHelpers.showSnackBar(
          context,
          loanProvider.error ?? 'Failed to initiate payment',
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error processing payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
