import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  // Pagination
  static const int _itemsPerPage = 10;
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Filtering
  String _selectedStatus = 'All';
  String _selectedMonth = 'All';
  String _selectedYear = 'All';

  final List<String> _statusOptions = ['All', 'Pending', 'Completed', 'Failed'];
  final List<String> _monthOptions = [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<String> _yearOptions = ['All', '2024', '2023', '2022'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );

    if (authProvider.isAuthenticated) {
      contributionProvider.loadUserContributions(authProvider.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Contributions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPaymentStatus,
            tooltip: 'Check Payment Status',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showMakeContributionDialog,
          ),
        ],
      ),
      body: Consumer<ContributionProvider>(
        builder: (context, contributionProvider, child) {
          if (contributionProvider.isLoading && _currentPage == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          final allContributions = contributionProvider.getUserContributions(
            Provider.of<AuthProvider>(context, listen: false).userId,
          );

          final filteredContributions = _filterContributions(allContributions);
          final paginatedContributions = _paginateContributions(
            filteredContributions,
          );

          if (paginatedContributions.isEmpty && _currentPage == 0) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _resetPagination();
              _loadData();
            },
            child: Column(
              children: [
                // Filter Summary
                if (_hasActiveFilters()) _buildFilterSummary(),

                // Contributions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount:
                        paginatedContributions.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == paginatedContributions.length) {
                        // Load more button
                        return _buildLoadMoreButton();
                      }

                      final contribution = paginatedContributions[index];
                      return _buildContributionCard(context, contribution);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No Contributions Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start making your monthly contributions to participate in the group.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showMakeContributionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Make Contribution'),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(BuildContext context, contribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppHelpers.formatCurrency(contribution.amount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    contribution.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppHelpers.getPaymentStatusColor(
                    contribution.status,
                  ).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: AppHelpers.getPaymentStatusColor(
                      contribution.status,
                    ),
                  ),
                ),
              ],
            ),
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
                  AppHelpers.formatDate(contribution.date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (contribution.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${AppHelpers.formatDate(contribution.dueDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (contribution.penaltyAmount != null &&
                contribution.penaltyAmount! > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Penalty: ${AppHelpers.formatCurrency(contribution.penaltyAmount!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (contribution.mpesaRef != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ref: ${contribution.mpesaRef}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (contribution.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _retryPayment(contribution),
                      child: const Text('Retry Payment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _simulatePayment(contribution),
                      child: const Text('Simulate Payment'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMakeContributionDialog() {
    showDialog(
      context: context,
      builder: (context) => _MakeContributionDialog(),
    );
  }

  void _retryPayment(contribution) {
    showDialog(
      context: context,
      builder: (context) => _RetryPaymentDialog(contribution: contribution),
    );
  }

  void _checkPaymentStatus() {
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );

    contributionProvider
        .checkPaymentStatus()
        .then((_) {
          AppHelpers.showSnackBar(context, 'Payment status checked!');
        })
        .catchError((error) {
          AppHelpers.showErrorSnackBar(
            context,
            'Failed to check payment status: $error',
          );
        });
  }

  void _simulatePayment(contribution) {
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );

    contributionProvider
        .simulatePaymentCompletion(contribution.contributionId)
        .then((_) {
          AppHelpers.showSuccessSnackBar(
            context,
            'Payment simulated successfully!',
          );
        })
        .catchError((error) {
          AppHelpers.showErrorSnackBar(
            context,
            'Failed to simulate payment: $error',
          );
        });
  }

  // Filtering methods
  List<dynamic> _filterContributions(List<dynamic> contributions) {
    return contributions.where((contribution) {
      // Status filter
      if (_selectedStatus != 'All' &&
          contribution.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // Month filter
      if (_selectedMonth != 'All') {
        final monthIndex = _monthOptions.indexOf(_selectedMonth);
        if (monthIndex > 0 && contribution.date.month != monthIndex) {
          return false;
        }
      }

      // Year filter
      if (_selectedYear != 'All') {
        final year = int.parse(_selectedYear);
        if (contribution.date.year != year) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<dynamic> _paginateContributions(List<dynamic> contributions) {
    final endIndex = (_currentPage + 1) * _itemsPerPage;
    final paginated = contributions.take(endIndex).toList();

    // Update hasMoreData
    _hasMoreData = endIndex < contributions.length;

    return paginated;
  }

  bool _hasActiveFilters() {
    return _selectedStatus != 'All' ||
        _selectedMonth != 'All' ||
        _selectedYear != 'All';
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
    });
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMoreData) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      // Simulate loading delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedStatus: _selectedStatus,
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
        statusOptions: _statusOptions,
        monthOptions: _monthOptions,
        yearOptions: _yearOptions,
        onApplyFilters: (status, month, year) {
          setState(() {
            _selectedStatus = status;
            _selectedMonth = month;
            _selectedYear = year;
            _resetPagination();
          });
        },
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filters: ${_getFilterSummaryText()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = 'All';
                _selectedMonth = 'All';
                _selectedYear = 'All';
                _resetPagination();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _getFilterSummaryText() {
    final filters = <String>[];
    if (_selectedStatus != 'All') filters.add(_selectedStatus);
    if (_selectedMonth != 'All') filters.add(_selectedMonth);
    if (_selectedYear != 'All') filters.add(_selectedYear);
    return filters.join(', ');
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _hasMoreData ? _loadMore : null,
              child: const Text('Load More'),
            ),
    );
  }
}

class _MakeContributionDialog extends StatefulWidget {
  @override
  State<_MakeContributionDialog> createState() =>
      _MakeContributionDialogState();
}

class _MakeContributionDialogState extends State<_MakeContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _makeContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );

    final success = await contributionProvider.createContribution(
      userId: authProvider.userId,
      amount: AppConstants.monthlyContribution,
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      AppHelpers.showSuccessSnackBar(
        context,
        'Contribution initiated! Check your phone for M-Pesa prompt.',
      );
    } else if (mounted) {
      AppHelpers.showErrorSnackBar(
        context,
        contributionProvider.error ?? 'Failed to initiate contribution',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make Contribution'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Contribution: ${AppHelpers.formatCurrency(AppConstants.monthlyContribution)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., 0712345678',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (!AppHelpers.isValidPhoneNumber(value)) {
                  return 'Please enter a valid Kenyan phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive an M-Pesa STK Push prompt on your phone to complete the payment.',
                      style: Theme.of(context).textTheme.bodySmall,
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
          onPressed: _isLoading ? null : _makeContribution,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pay Now'),
        ),
      ],
    );
  }
}

class _RetryPaymentDialog extends StatefulWidget {
  final contribution;

  const _RetryPaymentDialog({required this.contribution});

  @override
  State<_RetryPaymentDialog> createState() => _RetryPaymentDialogState();
}

class _RetryPaymentDialogState extends State<_RetryPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with user's phone number if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _phoneController.text = authProvider.userPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _retryPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );

    // Create a new contribution with the same details
    final success = await contributionProvider.createContribution(
      userId: widget.contribution.userId,
      amount: widget.contribution.amount,
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      AppHelpers.showSuccessSnackBar(
        context,
        'Payment retry initiated! Check your phone for M-Pesa prompt.',
      );
    } else if (mounted) {
      AppHelpers.showErrorSnackBar(
        context,
        contributionProvider.error ?? 'Failed to retry payment',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retry Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${AppHelpers.formatCurrency(widget.contribution.amount)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., 0712345678',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (!AppHelpers.isValidPhoneNumber(value)) {
                  return 'Please enter a valid Kenyan phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive an M-Pesa STK Push prompt on your phone to complete the payment.',
                      style: Theme.of(context).textTheme.bodySmall,
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
          onPressed: _isLoading ? null : _retryPayment,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Retry Payment'),
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final String selectedStatus;
  final String selectedMonth;
  final String selectedYear;
  final List<String> statusOptions;
  final List<String> monthOptions;
  final List<String> yearOptions;
  final Function(String, String, String) onApplyFilters;

  const _FilterDialog({
    required this.selectedStatus,
    required this.selectedMonth,
    required this.selectedYear,
    required this.statusOptions,
    required this.monthOptions,
    required this.yearOptions,
    required this.onApplyFilters,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String _tempStatus;
  late String _tempMonth;
  late String _tempYear;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.selectedStatus;
    _tempMonth = widget.selectedMonth;
    _tempYear = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Contributions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter
            Text(
              'Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tempStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.statusOptions.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Month Filter
            Text(
              'Month',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tempMonth,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.monthOptions.map((month) {
                return DropdownMenuItem(value: month, child: Text(month));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempMonth = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Year Filter
            Text(
              'Year',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tempYear,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.yearOptions.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempYear = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _tempStatus = 'All';
              _tempMonth = 'All';
              _tempYear = 'All';
            });
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilters(_tempStatus, _tempMonth, _tempYear);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
